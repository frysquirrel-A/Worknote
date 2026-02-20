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

    // 홈은 “팀 필터” 개념: 선택된 팀 기준으로 프로젝트/팀원/업무 현황 표시
    final teamId = teamProv.currentTeamId;
    final team = teamProv.currentTeam;

    // 업무는 팀 기준으로 (필터는 업무 탭에서)
    final tasks = taskProv.getFilteredTasks(teamId, myId: myId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, teamProv, authProv, initial),
          const SizedBox(height: 12),

          // 팀 선택 + 단체채팅 진입 (리뷰: “안녕하세요 …” 영역에서 팀을 고를 수 있게)
          _buildTeamSelector(context, teamProv),

          const SizedBox(height: 14),

          // 리뷰: 팀원 리스트를 상단에 먼저 배치
          const Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 10),
          SizedBox(
            height: 94,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 나(내 프로필)
                GestureDetector(
                  onTap: () => _showMemberProfileSheet(
                    context,
                    memberId: myId,
                    name: myName,
                    role: teamProv.getMyRole(myId),
                    isMe: true,
                    onSendMessage: null,
                  ),
                  child: _buildMemberAvatar(myName, "👷", true),
                ),
                ...team.memberIds.where((id) => id != myId).map((uid) {
                  final userBox = Hive.isBoxOpen('users') ? Hive.box<AppUser>('users') : null;
                  final name = userBox?.get(uid)?.name ?? uid;
                  final role = team.memberRoles[uid] ?? '팀원';

                  return GestureDetector(
                    onTap: () {
                      final tid = chatProv.dmThreadId(teamId, myId, uid);
                      _showMemberProfileSheet(
                        context,
                        memberId: uid,
                        name: name,
                        role: role,
                        isMe: false,
                        onSendMessage: () => onOpenChatThread(tid, 'DM · $name'),
                      );
                    },
                    child: _buildMemberAvatar(name, "👤", false),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 12),

          ...taskProv.projects.where((p) => p.teamId == teamId).map((project) {
            final pTasks = tasks.where((t) => t.projectId == project.id).toList();
            final pDone = pTasks.where((t) => t.isDone).length;
            final pTotal = pTasks.length;
            final pRate = pTotal == 0 ? 0.0 : (pDone / pTotal);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: project.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text("${(pRate * 100).toInt()}%", style: TextStyle(color: project.color, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "$pDone 완료 / $pTotal 전체",
                      style: const TextStyle(fontSize: 11, color: AppColors.hint, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TeamProvider teamProv, AuthProvider authProv, String initial) {
    final myName = authProv.currentUser?.name ?? '관리자';
    final teamBadge = teamProv.currentTeam.name.isNotEmpty ? teamProv.currentTeam.name[0] : 'T';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now()),
              style: const TextStyle(fontSize: 13, color: AppColors.hint, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "안녕하세요 $myName님! 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text),
            ),
          ],
        ),
        // 프로필 + 팀 배지(리뷰: (서) 위치에 팀 배지를 만들 수 있게)
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(teamBadge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamSelector(BuildContext context, TeamProvider teamProv) {
    return GestureDetector(
      onTap: () => _showTeamSwitchSheet(context, teamProv),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.hub_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teamProv.currentTeam.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.text),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.hint),
            const SizedBox(width: 6),
            // 단체 채팅 바로가기
            IconButton(
              onPressed: () => onOpenChatThread(teamProv.currentTeamId, '단체 · ${teamProv.currentTeam.name}'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
              splashRadius: 18,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              tooltip: "단체 채팅",
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamSwitchSheet(BuildContext context, TeamProvider teamProv) {
    final teams = teamProv.teams.isNotEmpty ? teamProv.teams : [teamProv.currentTeam];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("팀 선택", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.text)),
              ),
              const SizedBox(height: 8),
              ...teams.map((t) {
                final selected = t.id == teamProv.currentTeamId;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bg,
                    child: Text(t.name.isNotEmpty ? t.name[0] : 'T', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    teamProv.switchTeam(t.id);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _showMemberProfileSheet(
    BuildContext context, {
    required String memberId,
    required String name,
    required String role,
    required bool isMe,
    VoidCallback? onSendMessage,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 14),
              CircleAvatar(
                radius: 34,
                backgroundColor: isMe ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bg,
                child: Text(isMe ? "👷" : "👤", style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(role, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text2)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onSendMessage == null ? null : () { Navigator.pop(ctx); onSendMessage(); },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("메시지 보내기", style: TextStyle(fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.bg,
                    disabledForegroundColor: AppColors.hint,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberAvatar(String name, String emoji, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isMe ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: AppColors.text2),
            ),
          ),
        ],
      ),
    );
  }
}
