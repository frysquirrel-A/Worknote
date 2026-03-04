import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/auth/ui/profile_selection_page.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/team/ui/team_management_page.dart';
import 'package:worknote/features/settings/ui/feedback_page.dart';
import 'package:worknote/data/services/app_reset_service.dart';
import 'package:worknote/app/widgets/profile_avatar.dart';

class MasterDrawer extends StatelessWidget {
  const MasterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final current = authProv.currentUser;
    final myId = current?.id ?? 'me';
    final myName = current?.name.trim().isNotEmpty == true ? current!.name : '사용자';
    final avatar = current?.profileImage;
    final initial = myName.isNotEmpty ? myName[0] : 'U';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
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
          _drawerItem(Icons.groups_rounded, '팀 관리', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementPage()));
          }),
          _drawerItem(
            Icons.cloud_sync_rounded,
            authProv.isDriveConnected ? '구글 드라이브 재연결' : '구글 드라이브 연동',
            () async {
              final ok = await _ensureCloudReadyWithPrompt(context, authProv);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authProv.isGoogleLinked ? '클라우드 기능을 사용할 준비가 되었습니다.' : '연동이 완료되었습니다.')),
                );
              }
            },
            color: authProv.isDriveConnected ? Colors.green : null,
          ),
          _drawerItem(
            Icons.switch_account_rounded,
            '프로필 관리 / 전환',
            () {
              Navigator.pop(context);
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  reverseTransitionDuration: const Duration(milliseconds: 220),
                  pageBuilder: (_, animation, __) => FadeTransition(
                    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    child: const ProfileSelectionPage(manageMode: true),
                  ),
                ),
              );
            },
          ),
          _drawerItem(Icons.palette_outlined, '테마 설정', () => _showThemeDialog(context, teamProv)),
          _drawerItem(Icons.restart_alt_rounded, '앱 초기화', () => _showResetDialog(context), color: Colors.deepOrange),
          const Divider(indent: 20, endIndent: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text('내 팀 목록', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                ...teamProv.teams.map(
                  (t) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(
                      Icons.hub_rounded,
                      color: t.id == teamProv.currentTeamId ? const Color(0xFF2563EB) : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      t.name,
                      style: TextStyle(color: Colors.black, fontWeight: t.id == teamProv.currentTeamId ? FontWeight.bold : FontWeight.normal),
                    ),
                    onTap: () {
                      teamProv.switchTeam(t.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.feedback_rounded, '의견 보내기', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage()));
          }),
          _drawerItem(Icons.logout_rounded, '로그아웃', () => authProv.logout(), color: Colors.redAccent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color ?? Colors.black54),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Future<bool> _ensureCloudReadyWithPrompt(BuildContext context, AuthProvider authProv) async {
    if (authProv.isDriveConnected) return true;

    final profile = authProv.currentUser;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('구글 연동 필요'),
        content: Text(
          profile == null
              ? '클라우드 기능을 사용하려면 먼저 프로필이 필요합니다.'
              : profile.isLocal
                  ? '현재 프로필은 로컬 전용입니다.\n구글 계정을 연결하면 팀 초대/공유/Drive 동기화 기능을 사용할 수 있어요.'
                  : '현재 프로필(${profile.linkedGoogleEmail ?? '구글 계정'})의 Drive 연결을 복구합니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('연결하기')),
        ],
      ),
    );

    if (ok != true) return false;
    final result = await authProv.connectGoogleDrive(bridgeCurrentLocal: true);
    if (!context.mounted) return false;
    if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
    return result.ok;
  }

  void _showEditNameDialog(BuildContext context, AuthProvider prov) {
    final ctrl = TextEditingController(text: prov.currentUser?.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '새 이름 입력')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              final ok = await prov.updateName(v);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '이름이 변경되었습니다.' : '이름 변경에 실패했습니다.')));
              }
            },
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('캐릭터 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(avatars[i], style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, TeamProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('다크 모드'), onTap: () { prov.changeTheme('dark'); Navigator.pop(ctx); }),
            ListTile(title: const Text('화이트 모드'), onTap: () { prov.changeTheme('light'); Navigator.pop(ctx); }),
            ListTile(title: const Text('블루 모드'), onTap: () { prov.changeTheme('blue'); Navigator.pop(ctx); }),
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
            title: const Text('앱 초기화'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('로컬 데이터를 모두 삭제합니다.\n(사용자 프로필은 유지됩니다.)'),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: withSample,
                  onChanged: (v) => setState(() => withSample = v ?? true),
                  title: const Text('초기화 후 샘플 데이터 넣기'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                onPressed: () async {
                  final authProv = context.read<AuthProvider>();
                  final myId = authProv.currentUser?.id ?? 'me';
                  final myName = authProv.currentUser?.name ?? '관리자';

                  await AppResetService().reset(withSampleData: withSample, myId: myId, myName: myName);

                  await context.read<TeamProvider>().loadTeams();
                  await context.read<TaskProvider>().loadData();
                  await context.read<JournalProvider>().loadJournals();
                  context.read<ChatProvider>().reloadLocal();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초기화 완료')));
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
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
                onTap: () => MasterDrawer()._showAvatarPicker(context, authProv),
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
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => MasterDrawer()._showEditNameDialog(context, authProv),
                          child: const Icon(Icons.edit_rounded, size: 16, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subText, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(typeLabel, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 11)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: selected ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF1F5F9),
                          child: Text(
                            (profile.profileImage?.trim().isNotEmpty ?? false) ? profile.profileImage! : (profile.name.trim().isNotEmpty ? profile.name[0] : '🙂'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile.name.trim().isEmpty ? '이름 미설정' : profile.name,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
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
