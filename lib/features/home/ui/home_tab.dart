import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:worknote/app/widgets/profile_avatar.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class HomeTab extends StatefulWidget {
  final void Function(String threadId, String? title) onOpenChatThread;

  const HomeTab({super.key, required this.onOpenChatThread});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final auth = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();

    final me = auth.currentUser;
    final myId = me?.id ?? 'me';
    final myName = me?.name ?? '사용자';
    final myEmoji = (me?.profileImage != null && me!.profileImage!.isNotEmpty)
        ? me.profileImage!
        : '👤';

    final teamId = teamProv.currentTeamId;
    final teamName = teamProv.currentTeam.name;
    final teamInitial = teamName.isNotEmpty ? teamName.characters.first : 'T';

    final usersBox = Hive.box<AppUser>('users');
    final members = teamProv.currentTeam.memberIds
        .map(
          (id) =>
              usersBox.get(id) ??
              AppUser(id: id, password: '', name: id, profileImage: '👤'),
        )
        .toList(growable: false);

    final teamProjects = taskProv.projects
        .where((p) => p.teamId == teamId)
        .toList(growable: false);
    final teamTasks = taskProv.tasksForTeam(teamId);
    final today = DateTime.now();
    final todayTasks = teamTasks
        .where(
          (t) =>
              t.dueDate.year == today.year &&
              t.dueDate.month == today.month &&
              t.dueDate.day == today.day,
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요, $myName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${today.year}.${today.month.toString().padLeft(2, '0')}.${today.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProfileAvatarWithTeamBadge(
                    emoji: myEmoji,
                    userId: myId,
                    teamInitial: teamInitial,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _surfaceCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showTeamPicker(context, teamProv),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            teamInitial,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '현재 팀',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkHint,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                teamName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.darkHint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '팀원',
                icon: Icons.people_alt_rounded,
                child: members.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            '팀원이 없습니다.',
                            style: TextStyle(color: AppColors.darkHint),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: members.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return _MemberAvatar(
                              user: member,
                              isMe: member.id == myId,
                              role: teamProv.currentTeam.memberRoles[member.id],
                              onTap: () => _showMemberSheet(
                                context,
                                member: member,
                                role:
                                    teamProv.currentTeam.memberRoles[member.id],
                                myId: myId,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '프로젝트 현황',
                icon: Icons.domain_rounded,
                child: teamProjects.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            '프로젝트가 없습니다.',
                            style: TextStyle(color: AppColors.darkHint),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                        child: Column(
                          children: [
                            for (final project in teamProjects)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ProjectProgressTile(
                                  project: project,
                                  tasks: teamTasks
                                      .where((t) => t.projectId == project.id)
                                      .toList(growable: false),
                                  progress: taskProv.projectProgress(
                                    project.id,
                                    teamId: teamId,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '오늘 할일',
                icon: Icons.checklist_rounded,
                child: todayTasks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            '오늘 마감 할일이 없습니다.',
                            style: TextStyle(color: AppColors.darkHint),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: Column(
                          children: [
                            for (final task in todayTasks)
                              ListTile(
                                dense: true,
                                leading: InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () => taskProv.updateTaskStatus(
                                    task,
                                    !task.isDone,
                                  ),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: task.isDone
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: task.isDone
                                            ? AppColors.primary
                                            : const Color(0xFF9CA3AF),
                                        width: 1.8,
                                      ),
                                    ),
                                    child: task.isDone
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isDone
                                        ? AppColors.darkHint
                                        : AppColors.darkText,
                                  ),
                                ),
                                subtitle: Text(
                                  '기한: ${task.dueDate.month}/${task.dueDate.day} · 중요도: ${_priorityLabel(task.priority)}',
                                  style: const TextStyle(
                                    color: AppColors.darkHint,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                trailing: Text(
                                  task.assigneeEmoji.isEmpty
                                      ? '👤'
                                      : task.assigneeEmoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _surfaceCard(
                child: ListTile(
                  leading: const Icon(
                    Icons.forum_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    '팀 대화방 열기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkHint),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    final chatProv = context.read<ChatProvider>();
                    final threadId = 'grp_${teamProv.currentTeamId}_main';
                    final title = '$teamName · 대화';
                    chatProv.setActiveThread(threadId, title: title);
                    widget.onOpenChatThread(threadId, title);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => '상',
      TaskPriority.medium => '중',
      TaskPriority.low => '하',
      TaskPriority.none => '없음',
    };
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
            gradient: AppGradients.messengerPanel,
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
                      color: AppColors.darkBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '팀 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 12),
                if (teams.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '참여 중인 팀이 없습니다.',
                        style: TextStyle(color: AppColors.darkHint),
                      ),
                    ),
                if (teams.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: teams.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final team = teams[i];
                        final isCurrent = team.id == teamProv.currentTeamId;
                        return ListTile(
                          title: Text(
                            team.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText,
                            ),
                          ),
                          subtitle: Text(
                            '${team.memberIds.length}명',
                            style: const TextStyle(color: AppColors.darkHint),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () {
                            teamProv.switchTeam(team.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMemberSheet(
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: const BoxDecoration(
            gradient: AppGradients.messengerPanel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  member.profileImage ?? '👤',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (role == null || role.trim().isEmpty) ? '팀원' : role,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final teamProv = context.read<TeamProvider>();
                    final chatProv = context.read<ChatProvider>();
                    final dmId = chatProv.dmThreadId(
                      teamProv.currentTeamId,
                      myId,
                      member.id,
                    );
                    final title = 'DM · ${member.name}';
                    chatProv.setActiveThread(dmId, title: title);
                    Navigator.pop(ctx);
                    widget.onOpenChatThread(dmId, title);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    '메시지 보내기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _surfaceCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
        ],
      ),
    );
  }
}

class _ProjectProgressTile extends StatelessWidget {
  final Project project;
  final List<Task> tasks;
  final double progress;

  const _ProjectProgressTile({
    required this.project,
    required this.tasks,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = tasks.where((t) => t.isDone).length;
    final totalCount = tasks.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface2,
        border: Border.all(color: AppColors.darkBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProjectNameRow(
            name: project.name,
            colorValue: project.colorValue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _ProjectProgressBar(
            progress: progress,
            doneCount: doneCount,
            totalCount: totalCount,
          ),
        ],
      ),
    );
  }
}

class _ProjectNameRow extends StatelessWidget {
  final String name;
  final int colorValue;
  final TextStyle? style;

  const _ProjectNameRow({
    required this.name,
    required this.colorValue,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color(colorValue),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style:
                style ??
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProjectProgressBar extends StatelessWidget {
  final double progress;
  final int doneCount;
  final int totalCount;

  const _ProjectProgressBar({
    required this.progress,
    required this.doneCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final percent = (normalized * 100).round();

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 18,
            backgroundColor: AppColors.darkBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Text(
          '$doneCount/$totalCount건 | $percent%',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.darkText,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatarWithTeamBadge extends StatelessWidget {
  final String emoji;
  final String userId;
  final String teamInitial;

  const _ProfileAvatarWithTeamBadge({
    required this.emoji,
    required this.userId,
    required this.teamInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfileAvatar(emoji: emoji, userId: userId, heroPrefix: 'appbar'),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
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
              ProfileAvatar(
                emoji: user.profileImage ?? '👤',
                userId: user.id,
                radius: 26,
                heroPrefix: 'members',
              ),
              if (isMe)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text(
                      '나',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 66,
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          if (role != null && role!.trim().isNotEmpty)
            SizedBox(
              width: 66,
              child: Text(
                role!,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
