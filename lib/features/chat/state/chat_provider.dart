import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/data/services/drive_service.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  List<ChatMessage> _allMessages = [];
  Timer? _pollingTimer;

  String _activeThreadId = 'default';
  String? _activeThreadTitle;

  String get activeThreadId => _activeThreadId;
  String get activeThreadTitle => _activeThreadTitle ?? '대화방';

  
  String _inferTeamIdFromThreadId(String threadId) {
    // Known patterns:
    // - grp_{teamId}_{uuid}
    // - dm_{teamId}_{uid1}_{uid2}
    final parts = threadId.split('_');
    if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
    return 'unknown';
  }

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

  /// threadId를 기준으로 메시지 필터링 (기본 teamId와 호환)
  List<ChatMessage> getMessages(String threadId) {
    return _allMessages.where((m) => m.teamId == threadId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  // DM 스레드 ID 생성 헬퍼
  String dmThreadId(String teamId, String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return 'dm_${teamId}_${ids[0]}_${ids[1]}';
  }

  // 그룹 스레드 생성
  Future<String> createGroupThread({
    required String teamId,
    required String title,
    required List<String> memberIds,
  }) async {
    final threadId = 'grp_${teamId}_${const Uuid().v4()}';
    final threadData = {
      'id': threadId,
      'teamId': teamId,
      'type': 'group',
      'title': title,
      'memberIds': memberIds,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await Hive.box('chat_threads').put(threadId, threadData);

    // Outbox: thread create
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

  // 그룹 이름 변경
  Future<void> renameGroupThread(String threadId, String newTitle) async {
    final box = Hive.box('chat_threads');
    final Map<String, dynamic>? data = box.get(threadId) != null ? Map<String, dynamic>.from(box.get(threadId)) : null;
    if (data != null) {
      data['title'] = newTitle;
      await box.put(threadId, data);

      // Outbox: thread rename
      unawaited(
        SyncOutbox.instance.enqueue(
          teamId: (data['teamId'] ?? 'unknown').toString(),
          entity: 'chat_thread',
          action: 'rename',
          entityId: threadId,
          payload: {
            'title': newTitle,
          },
        ),
      );

      if (_activeThreadId == threadId) _activeThreadTitle = newTitle;
      notifyListeners();
    }
  }

  // 그룹 삭제
  Future<void> deleteGroupThread(String threadId, {bool clearMessages = true}) async {
    final box = Hive.box('chat_threads');
    final dynamic raw = box.get(threadId);
    final Map<String, dynamic>? data = raw is Map ? Map<String, dynamic>.from(raw) : null;

    await box.delete(threadId);

    // Outbox: thread delete
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: (data?['teamId'] ?? _inferTeamIdFromThreadId(threadId)).toString(),
        entity: 'chat_thread',
        action: 'delete',
        entityId: threadId,
        payload: {
          'clearMessages': clearMessages.toString(),
        },
      ),
    );

    if (clearMessages) {
      await clearThreadMessages(threadId);
    }

    notifyListeners();
  }

  // 특정 대화방 메시지 삭제
  Future<void> clearThreadMessages(String threadId) async {
    _allMessages = _allMessages.where((m) => m.teamId != threadId).toList();
    final box = Hive.box<ChatMessage>('messages');
    await box.clear();
    for (final m in _allMessages) {
      await box.put(m.id, m);
    }

    // Outbox: thread messages cleared
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

  // 팀별 그룹 스레드 목록 조회
  List<Map<String, dynamic>> getGroupThreads(String teamId) {
    final box = Hive.box('chat_threads');
    return box.values
        .where((t) => t['teamId'] == teamId && t['type'] == 'group')
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
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

  /// threadId를 teamId 필드에 저장하여 호환성 유지
  Future<void> sendMessage(String threadId, String content, String senderId, String senderName) async {
    final newMsg = ChatMessage(
      id: const Uuid().v4(),
      teamId: threadId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
    );

    _allMessages.add(newMsg);

    try {
      await Hive.box<ChatMessage>('messages').put(newMsg.id, newMsg);
    } catch (_) {
      // If persisting fails, keep in-memory only (avoid crashing chat UX)
    }

    // Outbox: message send
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
          'content': content,
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
        _allMessages.map((e) => e.toJson()).toList(), 'worknote_chats.json');
    if (data == null) return;

    _allMessages = data.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();

    final box = Hive.box<ChatMessage>('messages');
    await box.clear();
    for (final m in _allMessages) {
      await box.put(m.id, m);
    }

    notifyListeners();
  }
}
