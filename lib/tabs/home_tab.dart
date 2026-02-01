import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class HomeTab extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final List<TeamMember> members;
  final AppTone tone;

  const HomeTab({super.key, required this.tasks, required this.projects, required this.members, required this.tone});

  @override
  Widget build(BuildContext context) {
    final isDark = tone == AppTone.black;
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
                  Text(DateFormat('M월 d일 E요일', 'ko_KR').format(DateTime.now()), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text("안녕하세요 관리자님! 👷", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              const CircleAvatar(radius: 25, child: Icon(Icons.person)),
            ],
          ),
          const SizedBox(height: 32),
          Text("프로젝트 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            const Center(child: Text("등록된 프로젝트가 없습니다."))
          else
            ...projects.map((p) {
              final pTasks = tasks.where((t) => t.projectId == p.id).toList();
              final done = pTasks.where((t) => t.isDone).length;
              final total = pTasks.length;
              final progress = total == 0 ? 0.0 : done / total;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.w900, color: p.color)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: progress, minHeight: 8, color: p.color, backgroundColor: p.color.withValues(alpha: 0.1)),
                    ),
                    const SizedBox(height: 8),
                    Text("진행 $done / 전체 $total", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          Text("팀원 리스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    CircleAvatar(radius: 30, backgroundColor: Colors.blue.shade50, child: Text(members[i].emoji, style: const TextStyle(fontSize: 24))),
                    const SizedBox(height: 4),
                    Text(members[i].name, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
