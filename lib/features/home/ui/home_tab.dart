import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class HomeTab extends StatelessWidget {
  final void Function(String threadId, String? title) onOpenChatThread;

  const HomeTab({super.key, required this.onOpenChatThread});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();

    final me = auth.currentUser;
    final meId = me?.id ?? 'me';
    final meName = me?.name ?? '나';
    // NOTE: 이 프로젝트에서는 AppUser.profileImage 를 '이모지(또는 프로필 문자열)' 용도로 사용 중.
    final meEmoji = (me?.profileImage != null && me!.profileImage!.isNotEmpty)
        ? me.profileImage!
        : '🙂';

    final teamName = teamProv.currentTeam.name;
    final teamInitial = teamName.isNotEmpty ? teamName.characters.first : 'T';

    final usersBox = Hive.box<AppUser>('users');

    // Resolve team members safely.
    final memberIds = teamProv.currentTeam.memberIds;
    final members = memberIds
        .map(
          (id) => usersBox.get(id) ?? AppUser(id: id, password: '', name: id, profileImage: '👤'),
        )
        .toList(growable: false);

    final today = DateTime.now();
    final todayStr = '${today.year}.${today.month.toString().padLeft(2, '0')}.${today.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요, $meName',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todayStr,
                          style: TextStyle(fontSize: 14, color: AppColors.text2),
                        ),
                      ],
                    ),
                  ),
                  _ProfileAvatarWithTeamBadge(
                    emoji: meEmoji,
                    teamInitial: teamInitial,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Team selection (below greeting)
              _card(
                context,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showTeamPicker(context, teamProv),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            teamInitial,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '현재 팀',
                                style: TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                teamName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.text2),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Team members (above project status)
              _card(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '팀원',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text(
                            '${members.length}명',
                            style: TextStyle(fontSize: 12, color: AppColors.text2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final m in members)
                            _MemberAvatar(
                              user: m,
                              isMe: m.id == meId,
                              role: teamProv.currentTeam.memberRoles[m.id],
                              onTap: () => _showMemberProfileSheet(
                                context,
                                member: m,
                                role: teamProv.currentTeam.memberRoles[m.id],
                                myId: meId,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Project status
              _card(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('프로젝트 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ...taskProv.projects.map(
                        (p) {
                          final progress = taskProv.projectProgress(p.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 120,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.black12,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(progress * 100).round()}%'),
                              ],
                            ),
                          );
                        },
                      ),
                      if (taskProv.projects.isEmpty)
                        Text(
                          '프로젝트가 없습니다.\n업무를 등록하거나 샘플 데이터를 추가해보세요.',
                          style: TextStyle(color: AppColors.text2, fontSize: 13, height: 1.4),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Today tasks
              _card(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오늘 업무', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ...taskProv
                          .tasksForTeam(teamProv.currentTeamId)
                          .where((t) => t.dueDate != null && _isSameDay(t.dueDate!, today))
                          .take(5)
                          .map(
                            (t) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('기한: ${_fmtDate(t.dueDate)}'),
                            ),
                          ),
                      if (taskProv
                          .tasksForTeam(teamProv.currentTeamId)
                          .where((t) => t.dueDate != null && _isSameDay(t.dueDate!, today))
                          .isEmpty)
                        Text('오늘 마감 업무가 없습니다.', style: TextStyle(color: AppColors.text2, fontSize: 13)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Quick entry: open team thread
              _card(
                context,
                child: ListTile(
                  leading: Icon(Icons.forum_outlined, color: AppColors.primary),
                  title: const Text('팀 대화방 열기', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(teamName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    final chatProv = context.read<ChatProvider>();
                    final threadId = 'grp_${teamProv.currentTeamId}_main';
                    chatProv.setActiveThread(threadId, title: '${teamName} · 대화');
                    onOpenChatThread(threadId, '${teamName} · 대화');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  void _showTeamPicker(BuildContext context, TeamProvider teamProv) {
    final teams = teamProv.teams;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('팀 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 12),
                if (teams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('참여 중인 팀이 없습니다.', style: TextStyle(color: AppColors.text2)),
                  ),
                if (teams.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) {
                        final t = teams[i];
                        final isCurrent = t.id == teamProv.currentTeamId;
                        return ListTile(
                          title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                          subtitle: Text('${t.memberIds.length}명', style: TextStyle(color: AppColors.text2)),
                          trailing: isCurrent ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
                          onTap: () {
                            teamProv.switchTeam(t.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: teams.length,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMemberProfileSheet(
    BuildContext context, {
    required AppUser member,
    required String? role,
    required String myId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(member.profileImage ?? '👤', style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (member.id == myId)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text('나', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role == null || role!.trim().isEmpty ? '팀원' : role!,
                            style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final teamProv = context.read<TeamProvider>();
                      final chatProv = context.read<ChatProvider>();
                      final dmId = chatProv.dmThreadId(teamProv.currentTeamId, myId, member.id);
                      chatProv.setActiveThread(dmId, title: 'DM · ${member.name}');
                      Navigator.pop(ctx);
                      onOpenChatThread(dmId, 'DM · ${member.name}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('메시지 보내기', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatarWithTeamBadge extends StatelessWidget {
  final String emoji;
  final String teamInitial;

  const _ProfileAvatarWithTeamBadge({required this.emoji, required this.teamInitial});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              teamInitial,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final AppUser user;
  final bool isMe;
  final String? role;
  final VoidCallback onTap;

  const _MemberAvatar({
    required this.user,
    required this.isMe,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(user.profileImage ?? '👤', style: const TextStyle(fontSize: 20)),
              ),
              if (isMe)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text(
                      '나',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              user.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (role != null && role!.trim().isNotEmpty)
            SizedBox(
              width: 70,
              child: Text(
                role!,
                style: TextStyle(fontSize: 10, color: AppColors.text2, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
