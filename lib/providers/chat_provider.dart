import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/drive_service.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  List<ChatMessage> _allMessages = [];
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  List<ChatMessage> getMessages(String teamId) {
    return _allMessages.where((m) => m.teamId == teamId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  void startPolling() {
    _sync();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _sync());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> sendMessage(String teamId, String content, String senderId, String senderName) async {
    final newMsg = ChatMessage(
      id: const Uuid().v4(),
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
    );

    _allMessages.insert(0, newMsg);
    notifyListeners();

    await _sync();
  }

  Future<void> _sync() async {
    if (!_driveService.isReady) return;
    
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
