import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';
import '../pages/admin_dashboard.dart'; 

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);
    final doneCount = tasks.where((t) => t.isDone).length;
    final totalCount = tasks.length;
    final doneRate = totalCount == 0 ? 0.0 : (doneCount / totalCount) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), 
                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text("안녕하세요 ", style: TextStyle(fontSize: 20, color: Colors.white70)),
                    Text("${teamProv.currentTeam.name}님", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                ],
              ),
              // 설정 버튼 (Glass Style)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                  icon: const Icon(Icons.settings, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // [디자인 복구] 대시보드 카드 (유리 질감)
          Container(
            height: 220,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05), // 반투명
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF3B82F6),
                          value: doneCount.toDouble(),
                          title: '${doneRate.toInt()}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(color: Colors.white10, value: (totalCount - doneCount).toDouble(), title: '', radius: 40),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legend("완료", const Color(0xFF3B82F6), doneCount),
                      const SizedBox(height: 12),
                      _legend("진행중", Colors.grey, totalCount - doneCount),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 퀵 메뉴 복구
          Row(
            children: [
              Expanded(child: _quickActionCard(Icons.add_task, "새 업무", Colors.orangeAccent)),
              const SizedBox(width: 16),
              Expanded(child: _quickActionCard(Icons.camera_alt, "사진 촬영", Colors.greenAccent)),
            ],
          )
        ],
      ),
    );
  }

  Widget _legend(String title, Color color, int count) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("$count건", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        )
      ],
    );
  }

  Widget _quickActionCard(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}