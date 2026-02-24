import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/chat/state/chat_provider.dart';
import 'package:worknote/features/team/ui/team_management_page.dart';
import 'package:worknote/data/services/app_reset_service.dart';
import 'package:worknote/features/admin/ui/system_monitor_page.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/data/services/auth_service.dart'; // ✨ AuthService 임포트

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

          // ✨ 구글 드라이브 연동 상태를 예쁜 '배지(Badge)'로 보여주는 스마트 토글 버튼
          StatefulBuilder(
            builder: (context, setState) {
              final isLinked = DriveService().isReady; 
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(
                  isLinked ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                  color: isLinked ? Colors.blue : Colors.black54, 
                ),
                title: Row(
                  children: [
                    const Text('구글 드라이브', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLinked ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        border: Border.all(
                          color: isLinked ? Colors.blue.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isLinked ? '연동 완료' : '미연동',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLinked ? Colors.blue : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (isLinked) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('연동 해제', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('구글 드라이브 연동을 해제하시겠습니까?\n(오프라인 데이터는 유지됩니다)'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false), 
                            child: const Text('취소', style: TextStyle(color: Colors.grey))
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true), 
                            child: const Text('해제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await DriveService().signOut();
                      setState(() {}); 
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('구글 드라이브 연동이 해제되었습니다.')),
                        );
                      }
                    }
                  } else {
                    final success = await DriveService().signIn();
                    if (success) {
                      setState(() {});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('구글 드라이브에 성공적으로 연결되었습니다! ✅'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),

          _drawerItem(Icons.palette_outlined, "테마 설정", () => _showThemeDialog(context, teamProv)),

          _drawerItem(Icons.restart_alt_rounded, "앱 초기화", () => _showResetDialog(context), color: Colors.deepOrange),
          
          _drawerItem(Icons.monitor_heart_rounded, "시스템 모니터링 (관리자)", () {
            Navigator.pop(context); 
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SystemMonitorPage()),
            );
          }, color: Colors.blueGrey),

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
                  title: Text(t.name, style: TextStyle(color: Colors.black, fontWeight: t.id == teamProv.currentTeamId ? FontWeight.bold : FontWeight.normal)),
                  onTap: () {
                    teamProv.switchTeam(t.id);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),

          // ✨ 로그아웃 버튼: AuthService 연동 및 화면 강제 이동 적용
          _drawerItem(Icons.logout_rounded, "로그아웃", () async {
            // 1. 파이어베이스 & 구글 세션 종료 (AuthProvider 로직 포함)
            await authProv.logout(); // 내부적으로 AuthService().signOut() 및 GoogleSignIn().signOut() 호출됨
            
            // 2. 로그인 화면으로 강제 이동
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          }, color: Colors.redAccent),
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
