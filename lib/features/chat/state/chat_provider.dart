import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/data/services/drive_service.dart';

class ChatProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  List<ChatMessage> _allMessages = [];
  Timer? _pollingTimer;

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

  List<ChatMessage> getMessages(String teamId) {
    return _allMessages.where((m) => m.teamId == teamId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
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

  Future<void> sendMessage(String teamId, String content, String senderId, String senderName) async {
    final newMsg = ChatMessage(
      id: const Uuid().v4(),
      teamId: teamId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: DateTime.now(),
    );

    _allMessages.add(newMsg);
    Hive.box<ChatMessage>('messages').put(newMsg.id, newMsg);
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
