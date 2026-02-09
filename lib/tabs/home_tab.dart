import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../pages/admin_dashboard.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();
    
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (날짜 + 인사말 + 설정)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now()), 
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[600], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("안녕하세요 ${authProv.currentUser?.name ?? '사용자'}님! 👋", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_outlined, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // 2. 프로젝트 현황 (캡처 이미지 컨셉 카드)
          const Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          
          if (taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).isEmpty)
            _buildEmptyHint("등록된 프로젝트가 없습니다.")
          else
            ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((project) {
              final pTasks = tasks.where((t) => t.projectId == project.id).toList();
              final pDone = pTasks.where((t) => t.isDone).length;
              final pTotal = pTasks.length;
              final pRate = pTotal == 0 ? 0.0 : (pDone / pTotal);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 16, decoration: BoxDecoration(color: project.color, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Text("${(pRate * 100).toInt()}%", style: TextStyle(color: project.color, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pRate,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        color: project.color,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$pDone 완료 / $pTotal 전체 업무", style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 24),
          
          // 3. 팀원 리스트 (캡처 이미지 컨셉 가로 리스트)
          const Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMemberAvatar("나", "👷", true, isDark),
                ...teamProv.currentTeam.memberIds.where((id) => id != 'me').map((name) => 
                  _buildMemberAvatar(name, "👤", false, isDark)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(String name, String emoji, bool isMe, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isMe ? Colors.blueAccent : Colors.transparent, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontSize: 13, fontWeight: isMe ? FontWeight.w900 : FontWeight.w600, color: isMe ? Colors.blueAccent : (isDark ? Colors.white70 : Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white24))),
    );
  }
}