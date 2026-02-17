import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/drive_service.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();

  // 메시지(모든 스레드)
  List<ChatMessage> _allMessages = [];

  // 스레드 메타(팀/DM/그룹)
  List<ChatThread> _threads = [];

  Timer? _pollingTimer;

  String _activeThreadId = '';
  String _activeThreadTitle = '';

  String get activeThreadId => _activeThreadId;
  String get activeThreadTitle => _activeThreadTitle;

  /// 현재 팀의 기본 단체 채널로 활성 스레드 세팅
  void ensureActiveForTeam({required Team team}) {
    if (_activeThreadId.isEmpty || !_threads.any((t) => t.id == _activeThreadId)) {
      setActiveThread(threadId: team.id, title: '단체 · ${team.name}');
    }
  }

  void setActiveThread({required String threadId, required String title}) {
    _activeThreadId = threadId;
    _activeThreadTitle = title;
    notifyListeners();
  }

  /// DM thread id: dm_<teamId>_<a>_<b> (a,b는 정렬된 userId)
  String dmThreadId(String teamId, String myId, String otherId) {
    final ids = [myId, otherId]..sort();
    return 'dm_${teamId}_${ids[0]}_${ids[1]}';
  }

  /// 그룹 스레드 생성 (Drive에 저장)
  Future<String> createGroupThread({
    required String teamId,
    required String title,
    required List<String> memberIds,
  }) async {
    final threadId = 'grp_${teamId}_${const Uuid().v4()}';
    final thread = ChatThread(
      id: threadId,
      teamId: teamId,
      type: 'group',
      title: title,
      memberIds: memberIds,
      updatedAt: DateTime.now(),
    );
    _threads.add(thread);
    notifyListeners();
    await _syncThreads();
    return threadId;
  }

  List<ChatThread> threadsForTeam(String teamId) {
    // team 채널은 가상으로 넣어도 되지만, UI에서는 TeamProvider에서 이름을 사용
    return _threads.where((t) => t.teamId == teamId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ChatMessage> getMessages(String threadId) {
    return _allMessages.where((m) => m.teamId == threadId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  void startPolling() {
    _syncAll();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncAll());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

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

    // 스레드 updatedAt 갱신 (그룹만 저장, DM/team은 제목은 UI에서 계산)
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      _threads[idx] = ChatThread(
        id: _threads[idx].id,
        teamId: _threads[idx].teamId,
        type: _threads[idx].type,
        title: _threads[idx].title,
        memberIds: _threads[idx].memberIds,
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();

    await _syncMessages();
    await _syncThreads();
  }

  Future<void> clearThreadMessages(String threadId) async {
    _allMessages = _allMessages.where((m) => m.teamId != threadId).toList();
    notifyListeners();
    await _syncMessages();
  }

  Future<void> deleteGroupThread(String threadId) async {
    _threads.removeWhere((t) => t.id == threadId);
    await clearThreadMessages(threadId);
    await _syncThreads();
    notifyListeners();
  }

  Future<void> _syncAll() async {
    await _syncThreads();
    await _syncMessages();
  }

  Future<void> _syncThreads() async {
    final data = await _driveService.syncJsonData(
      _threads.map((e) => e.toJson()).toList(),
      'worknote_chat_threads.json',
    );
    if (data != null) {
      _threads = data.map((e) => ChatThread.fromJson(e)).toList();
      // 정렬
      _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
  }

  Future<void> _syncMessages() async {
    final data = await _driveService.syncJsonData(
      _allMessages.map((e) => e.toJson()).toList(),
      'worknote_chats.json',
    );
    if (data != null) {
      _allMessages = data.map((e) => ChatMessage.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
