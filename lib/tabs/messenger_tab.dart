import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/team_provider.dart';

class MessengerTab extends StatefulWidget {
  const MessengerTab({super.key});

  @override
  State<MessengerTab> createState() => _MessengerTabState();
}

class _MessengerTabState extends State<MessengerTab> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 탭 진입 시 폴링 시작
    Future.microtask(() => context.read<ChatProvider>().startPolling());
  }

  @override
  void dispose() {
    // 탭 이탈 시 폴링 중단
    context.read<ChatProvider>().stopPolling();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final chatProv = context.watch<ChatProvider>();
    final isDark = teamProv.isDarkMode;
    
    final messages = chatProv.getMessages(teamProv.currentTeamId);

    return Column(
      children: [
        // 채팅 리스트
        Expanded(
          child: ListView.builder(
            reverse: true, // 최신 메시지가 아래에서 위로 쌓임
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.senderId == 'me';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 250),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF2563EB) : (isDark ? Colors.white10 : Colors.white),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? Radius.zero : null,
                      bottomLeft: !isMe ? Radius.zero : null,
                    ),
                    boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Text(msg.senderName, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                      ],
                      Text(msg.content, style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(DateFormat('a h:mm', 'ko').format(msg.sentAt), 
                          style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.grey)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // 입력창
        Container(
          padding: const EdgeInsets.all(12),
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "메시지 입력...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      if (_ctrl.text.trim().isEmpty) return;
                      chatProv.sendMessage(
                        teamProv.currentTeamId, 
                        _ctrl.text, 
                        "나(관리자)"
                      );
                      _ctrl.clear();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
