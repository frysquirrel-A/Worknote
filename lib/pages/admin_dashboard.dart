import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';
import 'system_monitor_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();

    final isDark = teamProv.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("설정 및 관리", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.blue, child: Text(authProv.currentUser?.name[0] ?? "U", style: const TextStyle(color: Colors.white, fontSize: 24))),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(authProv.currentUser?.name ?? "사용자", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    Text(authProv.currentUser?.role ?? "팀원", style: const TextStyle(color: Colors.grey)),
                  ])
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildTile(context, "구글 드라이브 연동", Icons.add_to_drive, Colors.green, cardColor, textColor, onTap: () async {
              if (!authProv.isGoogleLinked) {
                final success = await authProv.connectGoogleDrive();
                if (!context.mounted) return;
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("연동 성공!")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("연동 실패 (SHA-1 확인 필요)")));
                }
              }
            }),
            const SizedBox(height: 12),
            _buildTile(context, "시스템 모니터", Icons.monitor_heart, Colors.redAccent, cardColor, textColor, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemMonitorPage()));
            }),
            const SizedBox(height: 12),
            _buildTile(context, "다크 모드", Icons.dark_mode, Colors.purpleAccent, cardColor, textColor, onTap: () {
               teamProv.toggleTheme();
            }),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1), elevation: 0),
                onPressed: () {
                  authProv.logout();
                  Navigator.pop(context);
                },
                child: const Text("로그아웃", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, Color iconColor, Color bgColor, Color textColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
