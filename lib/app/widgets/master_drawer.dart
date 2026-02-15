import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/team/ui/team_management_page.dart';
import 'package:worknote/data/services/app_reset_service.dart';

class MasterDrawer extends StatelessWidget {
  const MasterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '사용자';
    final avatar = authProv.currentUser?.profileImage;
    final initial = myName.isNotEmpty ? myName[0] : 'U';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            currentAccountPicture: GestureDetector(
              onTap: () => _showAvatarPicker(context, authProv),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  avatar ?? initial,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            accountName: Row(
              children: [
                Text(myName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showEditNameDialog(context, authProv),
                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.blueAccent),
                ),
              ],
            ),
            accountEmail: Text("직책: ${teamProv.getMyRole(myId)}", style: const TextStyle(color: Colors.grey)),
          ),

          _drawerItem(Icons.groups_rounded, "팀 관리", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementPage()));
          }),

          _drawerItem(Icons.cloud_sync_rounded, "구글 드라이브 연동", () async {
            if (!authProv.isGoogleLinked) {
              final success = await authProv.connectGoogleDrive();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("연동 성공!")));
              }
            }
          }, color: authProv.isGoogleLinked ? Colors.green : null),

          _drawerItem(Icons.palette_outlined, "테마 설정", () => _showThemeDialog(context, teamProv)),

          _drawerItem(Icons.restart_alt_rounded, "앱 초기화", () => _showResetDialog(context), color: Colors.deepOrange),
          const Divider(indent: 20, endIndent: 20),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text("내 팀 목록", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                ...teamProv.teams.map((t) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.hub_rounded, color: t.id == teamProv.currentTeamId ? const Color(0xFF2563EB) : Colors.grey, size: 20),
                  title: Text(t.name, style: TextStyle(fontWeight: t.id == teamProv.currentTeamId ? FontWeight.bold : FontWeight.normal)),
                  onTap: () {
                    teamProv.switchTeam(t.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),

          _drawerItem(Icons.logout_rounded, "로그아웃", () => authProv.logout(), color: Colors.redAccent),
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

  void _showEditNameDialog(BuildContext context, AuthProvider prov) {
    final ctrl = TextEditingController(text: prov.currentUser?.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("이름 변경"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              prov.updateName(v);
              Navigator.pop(ctx);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AuthProvider authProv) {
    final avatars = ["👷", "👨‍🔧", "👩‍🔬", "👨‍💻", "👩‍💼", "🦸"];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("캐릭터 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                onTap: () {
                  authProv.updateProfileImage(avatars[i]);
                  Navigator.pop(ctx);
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
        title: const Text("테마 선택"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text("다크 모드"), onTap: () { prov.changeTheme('dark'); Navigator.pop(ctx); }),
            ListTile(title: const Text("화이트 모드"), onTap: () { prov.changeTheme('light'); Navigator.pop(ctx); }),
            ListTile(title: const Text("블루 모드"), onTap: () { prov.changeTheme('blue'); Navigator.pop(ctx); }),
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
                const Text('로컬 데이터를 모두 삭제합니다.\n(사용자 계정은 유지됩니다.)'),
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
