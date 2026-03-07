import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/app/widgets/profile_avatar.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/data/services/app_reset_service.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/auth/ui/profile_selection_page.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/settings/ui/feedback_page.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/team/ui/team_management_page.dart';

class MasterDrawer extends StatelessWidget {
  const MasterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final current = authProv.currentUser;
    final myId = current?.id ?? 'me';
    final myName =
        current?.name.trim().isNotEmpty == true ? current!.name : '사용자';
    final avatar = current?.profileImage;
    final initial = myName.isNotEmpty ? myName[0] : 'U';

    return Drawer(
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            _ProfileHeader(
              authProv: authProv,
              teamProv: teamProv,
              myId: myId,
              myName: myName,
              avatar: avatar,
              initial: initial,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _sectionTitle('관리'),
                  const SizedBox(height: 8),
                  _drawerCard(
                    children: [
                      _drawerItem(
                        icon: Icons.groups_rounded,
                        title: '팀 관리',
                        subtitle: '그룹 멤버와 기본 설정을 관리합니다.',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TeamManagementPage(),
                            ),
                          );
                        },
                      ),
                      _drawerItem(
                        icon: Icons.cloud_sync_rounded,
                        title: authProv.isDriveConnected
                            ? '구글 드라이브 재연결'
                            : '구글 드라이브 연동',
                        subtitle: authProv.isGoogleLinked
                            ? '클라우드 공유와 Drive 연동 상태를 확인합니다.'
                            : '로컬 프로필을 구글 계정과 연결합니다.',
                        color: authProv.isDriveConnected
                            ? AppColors.success
                            : AppColors.premiumBlue,
                        onTap: () async {
                          final ok = await _ensureCloudReadyWithPrompt(
                            context,
                            authProv,
                          );
                          if (!context.mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authProv.isGoogleLinked
                                      ? '클라우드 기능을 사용할 준비가 되었습니다.'
                                      : '연동이 완료되었습니다.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _drawerItem(
                        icon: Icons.switch_account_rounded,
                        title: '프로필 관리 / 전환',
                        subtitle: '로컬·구글 프로필을 선택하거나 관리합니다.',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                              reverseTransitionDuration: const Duration(
                                milliseconds: 220,
                              ),
                              pageBuilder: (_, animation, __) => FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                                child: const ProfileSelectionPage(
                                  manageMode: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      _drawerItem(
                        icon: Icons.palette_outlined,
                        title: '테마 설정',
                        subtitle: '앱의 기본 색상 방향을 선택합니다.',
                        onTap: () => _showThemeDialog(context, teamProv),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('내 팀 목록'),
                  const SizedBox(height: 8),
                  _drawerCard(
                    padding: EdgeInsets.zero,
                    children: teamProv.teams.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                '참여 중인 팀이 없습니다.',
                                style: TextStyle(color: AppColors.darkHint),
                              ),
                            ),
                          ]
                        : teamProv.teams.map((t) {
                            final isCurrent = t.id == teamProv.currentTeamId;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: Icon(
                                Icons.hub_rounded,
                                color: isCurrent
                                    ? AppColors.premiumBlue
                                    : AppColors.darkHint,
                                size: 20,
                              ),
                              title: Text(
                                t.name,
                                style: TextStyle(
                                  color: AppColors.darkText,
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${t.memberIds.length}명',
                                style: const TextStyle(
                                  color: AppColors.darkHint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: isCurrent
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.premiumBlue,
                                    )
                                  : null,
                              onTap: () {
                                teamProv.switchTeam(t.id);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('지원'),
                  const SizedBox(height: 8),
                  _drawerCard(
                    children: [
                      _drawerItem(
                        icon: Icons.feedback_rounded,
                        title: '의견 보내기',
                        subtitle: '개선 의견이나 버그를 기록합니다.',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeedbackPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('위험 구역'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.destructive.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        _drawerItem(
                          icon: Icons.restart_alt_rounded,
                          title: '앱 초기화',
                          subtitle: '로컬 데이터만 삭제하고 프로필은 유지합니다.',
                          color: AppColors.destructive,
                          onTap: () => _showResetDialog(context),
                        ),
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.darkBorder,
                        ),
                        _drawerItem(
                          icon: Icons.logout_rounded,
                          title: '로그아웃',
                          subtitle: '현재 프로필 세션에서 나갑니다.',
                          color: AppColors.destructive,
                          onTap: () => authProv.logout(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkHint,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _drawerCard({
    EdgeInsetsGeometry padding = const EdgeInsets.all(6),
    required List<Widget> children,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.darkText;
    final textColor = color ?? AppColors.darkText;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.darkHint,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<bool> _ensureCloudReadyWithPrompt(
    BuildContext context,
    AuthProvider authProv,
  ) async {
    if (authProv.isDriveConnected) return true;

    final profile = authProv.currentUser;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '구글 연동 필요',
          style: TextStyle(color: AppColors.darkText),
        ),
        content: Text(
          profile == null
              ? '클라우드 기능을 사용하려면 먼저 프로필이 필요합니다.'
              : profile.isLocal
              ? '현재 프로필은 로컬 전용입니다.\n구글 계정을 연결하면 팀 초대, 공유, Drive 동기화를 사용할 수 있습니다.'
              : '현재 프로필(${profile.linkedGoogleEmail ?? '구글 계정'})의 Drive 연결을 복구합니다.',
          style: const TextStyle(color: AppColors.darkHint, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.premiumBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('연결하기'),
          ),
        ],
      ),
    );

    if (ok != true) return false;
    final result = await authProv.connectGoogleDrive(bridgeCurrentLocal: true);
    if (!context.mounted) return false;
    if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
    return result.ok;
  }

  void _showEditNameDialog(BuildContext context, AuthProvider prov) {
    final ctrl = TextEditingController(text: prov.currentUser?.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '이름 변경',
          style: TextStyle(color: AppColors.darkText),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '새 이름 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              final ok = await prov.updateName(v);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? '이름이 변경되었습니다.' : '이름 변경에 실패했습니다.',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.premiumBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AuthProvider authProv) {
    final avatars = ['👷', '👨‍🔧', '👩‍🔬', '👨‍💻', '👩‍💼', '🦸'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: AppGradients.messengerPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '캐릭터 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: avatars.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () async {
                  await authProv.updateProfileImage(avatars[i]);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.darkSurface,
                  child: Text(avatars[i], style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, TeamProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          '테마 선택',
          style: TextStyle(color: AppColors.darkText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                '다크 모드',
                style: TextStyle(color: AppColors.darkText),
              ),
              onTap: () {
                prov.changeTheme('dark');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text(
                '화이트 모드',
                style: TextStyle(color: AppColors.darkText),
              ),
              onTap: () {
                prov.changeTheme('light');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text(
                '블루 모드',
                style: TextStyle(color: AppColors.darkText),
              ),
              onTap: () {
                prov.changeTheme('blue');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    bool withSample = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text(
              '앱 초기화',
              style: TextStyle(color: AppColors.darkText),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '로컬 데이터를 모두 삭제합니다.\n(사용자 프로필은 유지됩니다.)',
                  style: TextStyle(color: AppColors.darkHint, height: 1.5),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: withSample,
                  onChanged: (v) => setState(() => withSample = v ?? true),
                  checkColor: Colors.white,
                  activeColor: AppColors.premiumBlue,
                  title: const Text(
                    '초기화 후 샘플 데이터 넣기',
                    style: TextStyle(color: AppColors.darkText),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final authProv = context.read<AuthProvider>();
                  final teamProv = context.read<TeamProvider>();
                  final taskProv = context.read<TaskProvider>();
                  final journalProv = context.read<JournalProvider>();
                  final chatProv = context.read<ChatProvider>();
                  final myId = authProv.currentUser?.id ?? 'me';
                  final myName = authProv.currentUser?.name ?? '관리자';

                  await AppResetService().reset(
                    withSampleData: withSample,
                    myId: myId,
                    myName: myName,
                  );

                  await teamProv.loadTeams();
                  await taskProv.loadData();
                  await journalProv.loadJournals();
                  chatProv.reloadLocal();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('초기화 완료')));
                  }
                },
                child: const Text('초기화'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AuthProvider authProv;
  final TeamProvider teamProv;
  final String myId;
  final String myName;
  final String? avatar;
  final String initial;

  const _ProfileHeader({
    required this.authProv,
    required this.teamProv,
    required this.myId,
    required this.myName,
    required this.avatar,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final current = authProv.currentUser;
    final typeLabel = current == null
        ? '프로필 없음'
        : current.isGoogleProfile
        ? 'Google • 슬롯 ${((current.slotIndex ?? 0) + 1)}'
        : 'Local';
    final subText = current?.linkedGoogleEmail ?? '직책: ${teamProv.getMyRole(myId)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        gradient: AppGradients.messengerPanel,
        borderRadius: BorderRadius.only(topRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                emoji: avatar ?? initial,
                userId: current?.id ?? 'me',
                radius: 28,
                heroPrefix: 'drawer',
                onTap: () => const MasterDrawer()._showAvatarPicker(context, authProv),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            myName,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => const MasterDrawer()._showEditNameDialog(
                            context,
                            authProv,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppColors.premiumBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: const TextStyle(color: AppColors.darkHint),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.premiumBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    color: AppColors.premiumBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: authProv.profiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final profile = authProv.profiles[i];
                final selected = profile.id == current?.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () async {
                    await authProv.switchProfile(profile.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.premiumBlue
                          : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? AppColors.premiumBlue
                            : AppColors.darkBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: selected
                              ? Colors.white.withValues(alpha: 0.18)
                              : AppColors.darkSurface2,
                          child: Text(
                            (profile.profileImage?.trim().isNotEmpty ?? false)
                                ? profile.profileImage!
                                : (profile.name.trim().isNotEmpty
                                      ? profile.name[0]
                                      : '🙂'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile.name.trim().isEmpty ? '이름 미설정' : profile.name,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.darkText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
