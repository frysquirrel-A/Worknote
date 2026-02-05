import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; 
import '../providers/team_provider.dart';
import '../providers/task_provider.dart';
import '../pages/admin_dashboard.dart'; 
import '../models.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), 
                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("${teamProv.currentTeam.name} 대시보드", 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.settings, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          Container(
            height: 180,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("전체 업무 달성률", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text("${doneRate.toInt()}%", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                      Text("총 $totalCount건 중 $doneCount건 완료", style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100, height: 100,
                  child: PieChart(PieChartData(sections: [
                    PieChartSectionData(color: Colors.blueAccent, value: doneCount.toDouble(), radius: 10, showTitle: false),
                    PieChartSectionData(color: Colors.white10, value: (totalCount - doneCount).toDouble(), radius: 8, showTitle: false),
                  ])),
                )
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("진행 중인 프로젝트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text("추가"),
                onPressed: () => _showAddProjectDialog(context, taskProv, teamProv.currentTeamId),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((project) {
            final pTasks = tasks.where((t) => t.projectId == project.id).toList();
            final pDone = pTasks.where((t) => t.isDone).length;
            final pTotal = pTasks.length;
            final pRate = pTotal == 0 ? 0.0 : (pDone / pTotal);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 16, decoration: BoxDecoration(color: project.color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      Text("${(pRate * 100).toInt()}%", style: TextStyle(color: project.color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pRate,
                      backgroundColor: Colors.white10,
                      color: project.color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, TaskProvider prov, String teamId) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text("새 프로젝트"),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "프로젝트명")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
        ElevatedButton(onPressed: () {
          if(ctrl.text.isNotEmpty) {
            prov.addProject(Project(
              id: const Uuid().v4(),
              teamId: teamId,
              name: ctrl.text,
              colorValue: prov.getRandomProjectColor().value,
            ));
          }
          Navigator.pop(ctx);
        }, child: const Text("생성")),
      ],
    ));
  }
}
