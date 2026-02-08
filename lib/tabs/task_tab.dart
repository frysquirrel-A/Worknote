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

    // [최신 문법] withValues 사용
    final dropdownDeco = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      isDense: true,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("새 업무", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddTaskModal(context, taskProv, teamProv),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black.withValues(alpha: 0.1),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: taskProv.projectIdFilter,
                        decoration: dropdownDeco.copyWith(labelText: "프로젝트"),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text("전체")),
                          const DropdownMenuItem(value: 'none', child: Text("없음")),
                          ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(
                            value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )),
                        ],
                        onChanged: (v) => taskProv.setFilter(projectId: v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: taskProv.statusFilter,
                        decoration: dropdownDeco.copyWith(labelText: "상태"),
                        items: const [
                          DropdownMenuItem(value: '전체', child: Text("전체")),
                          DropdownMenuItem(value: '진행 중', child: Text("진행")),
                          DropdownMenuItem(value: '완료됨', child: Text("완료")),
                        ],
                        onChanged: (v) => taskProv.setFilter(status: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority?>(
                        value: taskProv.priorityFilter,
                        decoration: dropdownDeco.copyWith(labelText: "중요도"),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("전체")),
                          ...TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.toString().split('.').last.toUpperCase()))),
                        ],
                        onChanged: (v) => taskProv.setFilter(priority: v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<DateFilter>(
                        value: taskProv.dateFilter,
                        decoration: dropdownDeco.copyWith(labelText: "기간"),
                        items: const [
                          DropdownMenuItem(value: DateFilter.all, child: Text("전체")),
                          DropdownMenuItem(value: DateFilter.today, child: Text("오늘")),
                          DropdownMenuItem(value: DateFilter.week, child: Text("이번 주")),
                        ],
                        onChanged: (v) => taskProv.setFilter(date: v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: tasks.isEmpty 
              ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final project = taskProv.projects.firstWhere(
                      (p) => p.id == task.projectId, 
                      orElse: () => Project(id: 'none', teamId: '', name: '프로젝트 없음', colorValue: 0xFF9E9E9E)
                    );
                    
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => taskProv.deleteTask(task.id),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: task.isDone ? Colors.grey.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: GestureDetector(
                            onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                            child: Icon(task.isDone ? Icons.check_circle : Icons.circle_outlined, color: task.isDone ? Colors.green : Colors.grey),
                          ),
                          title: Text(task.title, style: TextStyle(
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            color: task.isDone ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color
                          )),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if(task.projectId != null)
                                Row(children: [
                                  Icon(Icons.circle, size: 8, color: project.color),
                                  const SizedBox(width: 4),
                                  Text(project.name, style: TextStyle(fontSize: 12, color: project.color)),
                                ]),
                              Text("기한: ${DateFormat('MM.dd').format(task.dueDate)}", style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getPriorityColor(task.priority).withValues(alpha: 0.3)),
                            ),
                            child: Text(_getPriorityText(task.priority), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(task.priority))),
                          ),
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
  
  Color _getPriorityColor(TaskPriority p) {
    if (p == TaskPriority.high) return Colors.redAccent;
    if (p == TaskPriority.medium) return Colors.orangeAccent;
    return Colors.blueAccent;
  }
  String _getPriorityText(TaskPriority p) => p == TaskPriority.high ? "상" : (p == TaskPriority.medium ? "중" : "하");

  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    String selectedProjectId = 'none';
    if(prov.projects.any((p) => p.teamId == teamProv.currentTeamId)) {
      selectedProjectId = prov.projects.firstWhere((p) => p.teamId == teamProv.currentTeamId).id;
    }

    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("새 업무 등록", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedProjectId,
                decoration: const InputDecoration(labelText: "프로젝트", filled: true),
                items: [
                   const DropdownMenuItem(value: 'none', child: Text("프로젝트 없음")),
                   ...prov.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setModalState(() => selectedProjectId = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "업무 내용", hintText: "무엇을 해야 하나요?", filled: true),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: "중요도", filled: true),
                      items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(_getPriorityText(p)))).toList(),
                      onChanged: (v) => setModalState(() => selectedPriority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context, 
                          initialDate: selectedDate, 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime(2030),
                        );
                        if(d != null) setModalState(() => selectedDate = d);
                      },
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("마감일", style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                            Text(DateFormat('yy.MM.dd').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    prov.addTask(Task(
                      id: const Uuid().v4(),
                      teamId: teamProv.currentTeamId,
                      title: titleCtrl.text,
                      assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
                      projectId: selectedProjectId == 'none' ? null : selectedProjectId,
                      createdAt: DateTime.now(), 
                      dueDate: selectedDate,
                      priority: selectedPriority,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text("등록하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}