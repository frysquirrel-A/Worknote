import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers/task_provider.dart';
import '../providers/team_provider.dart';

class TeamTaskTab extends StatelessWidget {
  const TeamTaskTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final isDark = teamProv.isDarkMode;
    
    // 현재 팀의 필터링된 업무 가져오기
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("새 업무", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddTaskModal(context, taskProv, teamProv.currentTeamId),
      ),
      body: Column(
        children: [
          // 필터 바
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(label: "전체", isSelected: taskProv.statusFilter == '전체', onTap: () => taskProv.setFilter(status: '전체')),
                _FilterChip(label: "진행 중", isSelected: taskProv.statusFilter == '진행 중', onTap: () => taskProv.setFilter(status: '진행 중')),
                _FilterChip(label: "완료됨", isSelected: taskProv.statusFilter == '완료됨', onTap: () => taskProv.setFilter(status: '완료됨')),
              ],
            ),
          ),
          
          // 업무 리스트
          Expanded(
            child: tasks.isEmpty 
              ? Center(child: Text("등록된 업무가 없습니다.", style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: task.isDone ? Border.all(color: Colors.green.withOpacity(0.5)) : null,
                        ),
                        child: Row(
                          children: [
                            // 체크박스
                            GestureDetector(
                              onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: task.isDone ? Colors.green : Colors.transparent,
                                  border: Border.all(color: task.isDone ? Colors.green : Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 내용
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.title, style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                                    decorationColor: Colors.grey,
                                  )),
                                  const SizedBox(height: 4),
                                  Text("기한: ${DateFormat('yyyy.MM.dd').format(task.dueDate)}", 
                                    style: TextStyle(fontSize: 12, color: task.dueDate.isBefore(DateTime.now()) && !task.isDone ? Colors.red : Colors.grey)),
                                ],
                              ),
                            ),
                            // 중요도 뱃지
                            GestureDetector(
                              onTap: () => taskProv.cycleTaskPriority(task),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task.priority).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_getPriorityText(task.priority), 
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(task.priority))),
                              ),
                            )
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

  void _showAddTaskModal(BuildContext context, TaskProvider prov, String teamId) {
    final titleCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("새 업무 추가", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "무슨 업무인가요?",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true, fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: () {
                  if (titleCtrl.text.isEmpty) return;
                  prov.addTask(Task(
                    id: const Uuid().v4(),
                    teamId: teamId, // 현재 팀 ID
                    title: titleCtrl.text,
                    assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👤',
                    projectId: 'p1',
                    createdAt: DateTime.now(), dueDate: DateTime.now().add(const Duration(days: 3)),
                  ));
                  Navigator.pop(context);
                },
                child: const Text("등록하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch(p) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(TaskPriority p) {
    switch(p) {
      case TaskPriority.high: return "긴급";
      case TaskPriority.medium: return "중요";
      case TaskPriority.low: return "보통";
      default: return "-";
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.5)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
