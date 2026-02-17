import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/admin_dashboard.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();
    
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인사말 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now()), 
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("안녕하세요 ${authProv.currentUser?.name ?? '관리자'}님! 👋", 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                child: Text(authProv.currentUser?.name != null && authProv.currentUser!.name.isNotEmpty ? authProv.currentUser!.name[0] : "U", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // 프로젝트 현황 섹션
          const Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          
          ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((project) {
            final pTasks = tasks.where((t) => t.projectId == project.id).toList();
            final pDone = pTasks.where((t) => t.isDone).length;
            final pTotal = pTasks.length;
            final pRate = pTotal == 0 ? 0.0 : (pDone / pTotal);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: project.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      Text("${(pRate * 100).toInt()}%", style: TextStyle(color: project.color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pRate,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: project.color,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$pDone 완료 / $pTotal 전체", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),
          
          // 팀원 리스트 섹션
          const Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMemberAvatar(context, "나", "👷", true),
                ...teamProv.currentTeam.memberIds.where((id) => id != 'me').map((name) => 
                  _buildMemberAvatar(context, name, "👤", false)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(BuildContext context, String name, String emoji, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openDmDialog(context, name, isMe),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: isMe ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isMe ? const Color(0xFF2563EB) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  void _openDmDialog(BuildContext ctx, String otherId, bool isMe) {
    if (isMe) return;

    showDialog(
      context: ctx,
      builder: (dialogCtx) {
        final ctrl = TextEditingController(); 
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('$otherId 에게 메시지'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '메시지 입력'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('취소')),
              ElevatedButton(
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isNotEmpty) {
                    final auth = dialogCtx.read<AuthProvider>();
                    final chat = dialogCtx.read<ChatProvider>();
                    final team = dialogCtx.read<TeamProvider>().currentTeam;

                    final myId = auth.currentUser?.id ?? 'me';
                    final myName = auth.currentUser?.name ?? '관리자';
                    final threadId = chat.dmThreadId(team.id, myId, otherId);

                    await chat.sendMessage(threadId, text, myId, myName);
                  }
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                },
                child: const Text('전송'),
              ),
            ],
          ),
        );
      },
    );
  }
}
