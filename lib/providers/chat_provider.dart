import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/drive_service.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  List<ChatMessage> _allMessages = [];
  Timer? _pollingTimer;

  // 특정 팀의 메시지만 가져오기
  List<ChatMessage> getMessages(String teamId) {
    return _allMessages.where((m) => m.teamId == teamId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt)); // 최신순 정렬
  }

  // 채팅 시작 (5초마다 자동 동기화)
  void startPolling() {
    _sync(); // 즉시 1회 실행
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _sync());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> sendMessage(String teamId, String content, String userName) async {
    final newMsg = ChatMessage(
      id: const Uuid().v4(),
      teamId: teamId,
      senderId: 'me', // 내 ID는 항상 'me'로 가정
      senderName: userName,
      content: content,
      sentAt: DateTime.now(),
    );

    _allMessages.add(newMsg); // 로컬 선반영 (Optimistic UI)
    notifyListeners();

    await _sync(); // 드라이브 저장
  }

  Future<void> _sync() async {
    final data = await _driveService.syncJsonData(
      _allMessages.map((e) => e.toJson()).toList(), 
      'worknote_chats.json'
    );
    if (data != null) {
      _allMessages = data.map((e) => ChatMessage.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
