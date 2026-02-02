import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';
import '../pages/admin_dashboard.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider 구독
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    
    final isDark = teamProv.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final bgColor = isDark ? const Color(0xFF1F2937) : Colors.white;

    // 현재 팀의 업무만 필터링
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);
    final projects = taskProv.projects;

    // 파이 차트 데이터 계산
    final doneCount = tasks.where((t) => t.isDone).length;
    final totalCount = tasks.length;
    final doneRate = totalCount == 0 ? 0.0 : (doneCount / totalCount) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단 헤더 (관리자 히든 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), 
                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {}, // 1번 탭 (무반응)
                    onDoubleTap: () {}, // 2번 탭 (무반응)
                    onLongPress: () {
                      // 길게 누르면 관리자 페이지 이동
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                    },
                    child: Text("안녕하세요 ${teamProv.currentTeam.name}님! 👷", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE0E7FF),
                child: const Icon(Icons.person, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // 2. 파이 차트 (업무 현황)
          Text("업무 진행률", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF2563EB),
                          value: doneCount == 0 && totalCount == 0 ? 0 : (doneCount == 0 ? 0.01 : doneCount.toDouble()),
                          title: '${doneRate.toInt()}%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                          value: (totalCount - doneCount) == 0 && totalCount == 0 ? 1 : (totalCount - doneCount).toDouble(),
                          title: '',
                          radius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chartLegend("완료됨", const Color(0xFF2563EB), doneCount, isDark),
                    const SizedBox(height: 8),
                    _chartLegend("진행 중", isDark ? Colors.grey[600]! : Colors.grey[300]!, totalCount - doneCount, isDark),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 3. 프로젝트 리스트
          Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 16),
          ...projects.map((p) {
             return Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: bgColor,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
               ),
               child: Row(
                 children: [
                   Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                   const SizedBox(width: 12),
                   Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                 ],
               ),
             );
          }).toList(),
        ],
      ),
    );
  }

  Widget _chartLegend(String title, Color color, int count, bool isDark) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12)),
        const SizedBox(width: 4),
        Text("($count)", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}
