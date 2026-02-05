import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/drive_service.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  List<ChatMessage> _allMessages = [];
  Timer? _pollingTimer;

  List<ChatMessage> getMessages(String teamId) {
    return _allMessages.where((m) => m.teamId == teamId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  void startPolling() {
    _sync();
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
      senderId: 'me',
      senderName: userName,
      content: content,
      sentAt: DateTime.now(),
    );

    _allMessages.add(newMsg);
    notifyListeners();

    await _sync();
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
