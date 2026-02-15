import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';

class MessengerTab extends StatefulWidget {
  const MessengerTab({super.key});

  @override
  State<MessengerTab> createState() => _MessengerTabState();
}

class _MessengerTabState extends State<MessengerTab> {
  final TextEditingController _ctrl = TextEditingController();
  late ChatProvider _chatProvider;
  bool _started = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (!_started) {
      _started = true;
      _chatProvider.startPolling();
    }
  }

  @override
  void dispose() {
    _chatProvider.stopPolling();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final chatProv = context.watch<ChatProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final messages = chatProv.getMessages(teamProv.currentTeamId);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // 전체 통일된 화이트 배경
      body: Column(
        children: [
          // 1. 메시지 리스트 영역
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == myId;
                return _buildMessageBubble(msg, isMe);
              },
            ),
          ),

          // 2. 하단 입력창 (Pixel Style White Round)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_ctrl.text.trim().isEmpty) return;
                    chatProv.sendMessage(teamProv.currentTeamId, _ctrl.text, myId, myName);
                    _ctrl.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black54)),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end, // [수정] bottom -> end (에러 해결)
            children: [
              if (isMe) _buildTime(msg.sentAt),
              const SizedBox(width: 4),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    if (!isMe) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(width: 4),
              if (!isMe) _buildTime(msg.sentAt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTime(DateTime time) {
    return Text(
      DateFormat('a h:mm', 'ko').format(time),
      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
    );
  }
}
