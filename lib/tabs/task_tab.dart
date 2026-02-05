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
    
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("새 업무", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddTaskModal(context, taskProv, teamProv),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: "전체 프로젝트", 
                  isSelected: taskProv.projectIdFilter == 'all', 
                  onTap: () => taskProv.setFilter(projectId: 'all')
                ),
                ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => _FilterChip(
                  label: p.name, 
                  isSelected: taskProv.projectIdFilter == p.id, 
                  onTap: () => taskProv.setFilter(projectId: p.id)
                )),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(label: "전체 상태", isSelected: taskProv.statusFilter == '전체', onTap: () => taskProv.setFilter(status: '전체')),
                _FilterChip(label: "진행 중", isSelected: taskProv.statusFilter == '진행 중', onTap: () => taskProv.setFilter(status: '진행 중')),
                _FilterChip(label: "완료됨", isSelected: taskProv.statusFilter == '완료됨', onTap: () => taskProv.setFilter(status: '완료됨')),
              ],
            ),
          ),
          
          Expanded(
            child: tasks.isEmpty 
              ? Center(child: Text("업무가 없습니다.", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final project = taskProv.projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: '?', teamId: '', name: '알 수 없음', colorValue: 0xFF9E9E9E));
                    
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => taskProv.deleteTask(task.id),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: task.isDone ? Colors.green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                              child: Icon(
                                task.isDone ? Icons.check_circle : Icons.circle_outlined, 
                                color: task.isDone ? Colors.green : Colors.grey
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: project.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(project.name, style: TextStyle(fontSize: 10, color: project.color, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(task.title, style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold,
                                    color: task.isDone ? Colors.white30 : Colors.white,
                                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                                  )),
                                ],
                              ),
                            ),
                            Text(task.assigneeEmoji, style: const TextStyle(fontSize: 20)),
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

  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    String selectedProjectId = prov.projects.where((p) => p.teamId == teamProv.currentTeamId).isNotEmpty 
        ? prov.projects.firstWhere((p) => p.teamId == teamProv.currentTeamId).id 
        : 'default';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("새 업무 추가", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("프로젝트 선택", style: TextStyle(color: Colors.grey, fontSize: 12)),
              DropdownButton<String>(
                value: selectedProjectId,
                dropdownColor: const Color(0xFF1E293B),
                isExpanded: true,
                underline: Container(),
                items: prov.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (v) => setModalState(() => selectedProjectId = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "업무 내용을 입력하세요",
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    prov.addTask(Task(
                      id: const Uuid().v4(),
                      teamId: teamProv.currentTeamId,
                      title: titleCtrl.text,
                      assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
                      projectId: selectedProjectId,
                      createdAt: DateTime.now(), dueDate: DateTime.now().add(const Duration(days: 3)),
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text("등록하기", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
