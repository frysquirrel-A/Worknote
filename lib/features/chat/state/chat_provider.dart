import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/domain/models.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _allMessages = [];
  Timer? _pollingTimer;

  String _activeThreadId = 'default';
  String? _activeThreadTitle;

  String get activeThreadId => _activeThreadId;
  String get activeThreadTitle => _activeThreadTitle ?? '대화방';

  ChatProvider() {
    _loadLocal();
  }

  void _loadLocal() {
    try {
      _allMessages = Hive.box<ChatMessage>('messages').values.toList();
    } catch (_) {
      _allMessages = [];
    }
  }

  void reloadLocal() {
    _loadLocal();
    notifyListeners();
  }

  void setActiveThread(String threadId, {String? title}) {
    _activeThreadId = threadId;
    _activeThreadTitle = title;
    notifyListeners();
  }

  List<ChatMessage> getMessages(String threadId) {
    return _allMessages.where((m) => m.teamId == threadId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  bool hasMessages(String threadId) {
    return _allMessages.any((m) => m.teamId == threadId);
  }

  ChatMessage? getLastMessage(String threadId) {
    final messages = getMessages(threadId);
    return messages.isEmpty ? null : messages.first;
  }

  Map<String, dynamic>? getThreadMeta(String threadId) {
    final raw = Hive.box('chat_threads').get(threadId);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  String dmThreadId(String teamId, String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return 'dm_${teamId}_${ids[0]}_${ids[1]}';
  }

  Future<String> createGroupThread({
    required String teamId,
    required String title,
    required List<String> memberIds,
  }) async {
    final now = DateTime.now().toIso8601String();
    final threadId = 'grp_${teamId}_${_uuid.v4()}';
    final threadData = {
      'id': threadId,
      'teamId': teamId,
      'type': 'group',
      'title': title,
      'memberIds': memberIds,
      'createdAt': now,
      'updatedAt': now,
    };
    await Hive.box('chat_threads').put(threadId, threadData);

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: teamId,
        entity: 'chat_thread',
        action: 'put',
        entityId: threadId,
        payload: {
          'type': 'group',
          'title': title,
          'memberCount': memberIds.length.toString(),
        },
      ),
    );

    notifyListeners();
    return threadId;
  }

  Future<void> renameGroupThread(String threadId, String newTitle) async {
    final box = Hive.box('chat_threads');
    final dynamic raw = box.get(threadId);
    final Map<String, dynamic>? data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : null;
    if (data == null) return;

    data['title'] = newTitle;
    data['updatedAt'] = DateTime.now().toIso8601String();
    await box.put(threadId, data);

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: (data['teamId'] ?? 'unknown').toString(),
        entity: 'chat_thread',
        action: 'rename',
        entityId: threadId,
        payload: {'title': newTitle},
      ),
    );

    if (_activeThreadId == threadId) {
      _activeThreadTitle = newTitle;
    }
    notifyListeners();
  }

  Future<void> deleteGroupThread(
    String threadId, {
    bool clearMessages = true,
  }) async {
    final box = Hive.box('chat_threads');
    final dynamic raw = box.get(threadId);
    final Map<String, dynamic>? data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : null;

    await box.delete(threadId);

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: (data?['teamId'] ?? _inferTeamIdFromThreadId(threadId))
            .toString(),
        entity: 'chat_thread',
        action: 'delete',
        entityId: threadId,
        payload: {'clearMessages': clearMessages.toString()},
      ),
    );

    if (clearMessages) {
      await clearThreadMessages(threadId);
    }

    notifyListeners();
  }

  Future<void> clearThreadMessages(String threadId) async {
    final deleteIds = _allMessages
        .where((m) => m.teamId == threadId)
        .map((m) => m.id)
        .toList();
    _allMessages.removeWhere((m) => m.teamId == threadId);

    final box = Hive.box<ChatMessage>('messages');
    if (deleteIds.isNotEmpty) {
      await box.deleteAll(deleteIds);
    }

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: _inferTeamIdFromThreadId(threadId),
        entity: 'chat_message',
        action: 'clear_thread',
        entityId: threadId,
        payload: const {},
      ),
    );

    notifyListeners();
    await _sync();
  }

  List<Map<String, dynamic>> getGroupThreads(String teamId) {
    final box = Hive.box('chat_threads');
    final threads = box.values
        .whereType<Map>()
        .map((t) => Map<String, dynamic>.from(t))
        .where((t) => t['teamId'] == teamId && t['type'] == 'group')
        .toList();
    threads.sort((a, b) {
      final aAt = _threadUpdatedAt(a);
      final bAt = _threadUpdatedAt(b);
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return bAt.compareTo(aAt);
    });
    return threads;
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _sync();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _sync());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(
    String threadId,
    String content,
    String senderId,
    String senderName,
  ) async {
    final normalized = content.trim();
    if (normalized.isEmpty) return;

    final newMsg = ChatMessage(
      id: _uuid.v4(),
      teamId: threadId,
      senderId: senderId,
      senderName: senderName,
      content: normalized,
      sentAt: DateTime.now(),
    );

    _allMessages.add(newMsg);

    try {
      await Hive.box<ChatMessage>('messages').put(newMsg.id, newMsg);
    } catch (_) {
      // Keep in-memory if local persistence fails.
    }

    await _touchThread(threadId);

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: _inferTeamIdFromThreadId(threadId),
        entity: 'chat_message',
        action: 'put',
        entityId: newMsg.id,
        payload: {
          'threadId': threadId,
          'senderId': senderId,
          'senderName': senderName,
          'content': normalized,
          'sentAt': newMsg.sentAt.toIso8601String(),
        },
      ),
    );

    notifyListeners();
    await _sync();
  }

  Future<void> _sync() async {
    if (!_driveService.isReady) return;

    final data = await _driveService.syncJsonData(
      _allMessages.map((e) => e.toJson()).toList(),
      'worknote_chats.json',
    );
    if (data == null) return;

    final box = Hive.box<ChatMessage>('messages');
    final mergedById = <String, ChatMessage>{
      for (final local in box.values) local.id: local,
    };

    final syncedMessages = data
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    for (final m in syncedMessages) {
      mergedById[m.id] = m;
      await box.put(m.id, m);
    }

    _allMessages = mergedById.values.toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    notifyListeners();
  }

  String _inferTeamIdFromThreadId(String threadId) {
    if (threadId.isEmpty) return 'unknown';

    if (!threadId.contains('_')) {
      return threadId;
    }

    final parts = threadId.split('_');
    if ((parts.first == 'grp' || parts.first == 'dm') &&
        parts.length >= 2 &&
        parts[1].isNotEmpty) {
      return parts[1];
    }

    return threadId;
  }

  DateTime? _threadUpdatedAt(Map<String, dynamic> thread) {
    final raw = thread['updatedAt'] ?? thread['createdAt'];
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> _touchThread(String threadId) async {
    final box = Hive.box('chat_threads');
    final raw = box.get(threadId);
    if (raw is! Map) return;

    final data = Map<String, dynamic>.from(raw);
    data['updatedAt'] = DateTime.now().toIso8601String();
    await box.put(threadId, data);
  }
}
