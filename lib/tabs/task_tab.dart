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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. [이미지 컨셉] 드롭다운 필터 섹션
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A0E1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildDropdownFilter(
                          flex: 2,
                          label: "프로젝트",
                          value: taskProv.projectIdFilter,
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text("전체 프로젝트")),
                            const DropdownMenuItem(value: 'none', child: Text("프로젝트 없음")),
                            ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                          ],
                          onChanged: (v) => taskProv.setFilter(projectId: v),
                        ),
                        const SizedBox(width: 12),
                        _buildDropdownFilter(
                          flex: 1,
                          label: "상태",
                          value: taskProv.statusFilter,
                          items: const [
                            DropdownMenuItem(value: '전체', child: Text("전체")),
                            DropdownMenuItem(value: '진행 중', child: Text("진행")),
                            DropdownMenuItem(value: '완료됨', child: Text("완료")),
                          ],
                          onChanged: (v) => taskProv.setFilter(status: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDropdownFilter(
                          flex: 1,
                          label: "중요도",
                          value: taskProv.priorityFilter,
                          items: [
                            const DropdownMenuItem(value: null, child: Text("중요도 전체")),
                            ...TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))),
                          ],
                          onChanged: (v) => taskProv.setFilter(priority: v),
                        ),
                        const SizedBox(width: 12),
                        _buildDropdownFilter(
                          flex: 1,
                          label: "기한",
                          value: taskProv.dateFilter,
                          items: const [
                            DropdownMenuItem(value: DateFilter.all, child: Text("전체 기간")),
                            DropdownMenuItem(value: DateFilter.today, child: Text("오늘 마감")),
                            DropdownMenuItem(value: DateFilter.week, child: Text("이번 주")),
                          ],
                          onChanged: (v) => taskProv.setFilter(date: v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. 업무 리스트
              Expanded(
                child: tasks.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(context, taskProv, task, isDark);
                      },
                    ),
              ),
            ],
          ),

          // 3. [이미지 컨셉] 하단 대형 블루 버튼
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _showAddTaskModal(context, taskProv, teamProv),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 8,
                  shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text("ADD TASK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({required int flex, required String label, required dynamic value, required List<DropdownMenuItem> items, required Function(dynamic) onChanged}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.blueAccent),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            dropdownColor: const Color(0xFF161C2C),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskProvider prov, Task task, bool isDark) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => prov.deleteTask(task.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161C2C) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: task.isDone ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => prov.updateTaskStatus(task, !task.isDone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: task.isDone ? Colors.green : Colors.grey.withValues(alpha: 0.5), width: 2),
                  color: task.isDone ? Colors.green : Colors.transparent,
                ),
                child: task.isDone ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: task.isDone ? Colors.white24 : Colors.white,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Text(DateFormat('yyyy.MM.dd').format(task.dueDate), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => prov.cycleTaskPriority(task),
              child: Icon(Icons.flag_rounded, color: _getPriorityColor(task.priority), size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    if (p == TaskPriority.high) return Colors.redAccent;
    if (p == TaskPriority.medium) return Colors.orangeAccent;
    if (p == TaskPriority.low) return Colors.blueAccent;
    return Colors.white10;
  }

  Widget _buildEmptyState() {
    return Center(child: Text("업무가 없습니다.", style: TextStyle(color: Colors.white.withValues(alpha: 0.2))));
  }

  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    String? selectedProjectId;
    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Color(0xFF161C2C), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("새 업무 추가", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "제목 (#프로젝트)",
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: selectedProjectId,
                dropdownColor: const Color(0xFF161C2C),
                decoration: InputDecoration(
                  labelText: "관련 프로젝트",
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text("프로젝트 없음")),
                  ...prov.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (v) => setModalState(() => selectedProjectId = v),
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
                      projectId: selectedProjectId,
                      createdAt: DateTime.now(), dueDate: selectedDate,
                      priority: selectedPriority,
                    ));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("업무 등록하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}