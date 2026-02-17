import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("설정 및 관리"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("내 정보"),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(authProv.currentUser?.name ?? "사용자"),
            subtitle: Text("ID: ${authProv.currentUser?.id}"),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text("현재 팀 직책"),
            // [수정 포인트] 최신 메서드 사용
            subtitle: Text(teamProv.getMyRole(myId), style: const TextStyle(color: Colors.grey)),
          ),
          
          const Divider(),
          _buildSectionHeader("앱 설정"),
          
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text("테마 설정"),
            // [수정 포인트] 최신 다이얼로그 연결
            onTap: () => _showThemeDialog(context, teamProv),
            trailing: Icon(
              teamProv.currentThemeMode == 'dark' ? Icons.dark_mode : 
              (teamProv.currentThemeMode == 'light' ? Icons.light_mode : Icons.water_drop)
            ),
          ),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("로그아웃", style: TextStyle(color: Colors.red)),
            onTap: () {
              authProv.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  void _showThemeDialog(BuildContext context, TeamProvider prov) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("테마 선택"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text("다크 모드"), onTap: () { prov.changeTheme('dark'); Navigator.pop(ctx); }),
          ListTile(title: const Text("화이트 모드"), onTap: () { prov.changeTheme('light'); Navigator.pop(ctx); }),
          ListTile(title: const Text("블루 모드"), onTap: () { prov.changeTheme('blue'); Navigator.pop(ctx); }),
        ],
      ),
    ));
  }
}