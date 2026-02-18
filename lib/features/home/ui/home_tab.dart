import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';

class HomeTab extends StatelessWidget {
  final void Function(String threadId, String title) onOpenChatThread;
  const HomeTab({super.key, required this.onOpenChatThread});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();
    final chatProv = context.read<ChatProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final initial = myName.isNotEmpty ? myName[0] : 'U';
    
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId, myId: myId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now()), 
                    style: const TextStyle(fontSize: 13, color: AppColors.hint, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("안녕하세요 ${authProv.currentUser?.name ?? '관리자'}님! 👋", 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          GestureDetector(
            onTap: () => onOpenChatThread(teamProv.currentTeamId, '단체 · ${teamProv.currentTeam.name}'),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  teamProv.currentTeam.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.hint),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: () => onOpenChatThread(teamProv.currentTeamId, '단체 · ${teamProv.currentTeam.name}'),
                  child: _buildMemberAvatar(myName, "👷", true),
                ),
                ...teamProv.currentTeam.memberIds
                    .where((id) => id != myId)
                    .map((uid) {
                      final name = Hive.box<AppUser>('users').get(uid)?.name ?? uid;
                      return GestureDetector(
                        onTap: () {
                          final tid = chatProv.dmThreadId(teamProv.currentTeamId, myId, uid);
                          onOpenChatThread(tid, 'DM · $name');
                        },
                        child: _buildMemberAvatar(name, "👤", false),
                      );
                    }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: project.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text))),
                      Text("${(pRate * 100).toInt()}%", style: TextStyle(color: project.color, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pRate,
                      backgroundColor: AppColors.bg,
                      color: project.color,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$pDone 완료 / $pTotal 전체", style: const TextStyle(fontSize: 11, color: AppColors.hint, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(String name, String emoji, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isMe ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 12, fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: AppColors.text2)),
        ],
      ),
    );
  }
}
