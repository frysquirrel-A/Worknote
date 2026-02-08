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
    
    // [Logic] Provider에서 필터링된 업무 목록 가져오기
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
          // [Section 1] 필터 영역 (가로 스크롤)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // 1. 프로젝트 필터
                _FilterChip(
                  label: "전체 프로젝트", 
                  isSelected: taskProv.projectIdFilter == 'all', 
                  onTap: () => taskProv.setFilter(projectId: 'all')
                ),
                ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => _FilterChip(
                  label: p.name, 
                  isSelected: taskProv.projectIdFilter == p.id, 
                  onTap: () => taskProv.setFilter(projectId: p.id),
                  activeColor: p.color,
                )),
                _vDivider(),
                
                // 2. 상태 필터
                _FilterChip(label: "전체 상태", isSelected: taskProv.statusFilter == '전체', onTap: () => taskProv.setFilter(status: '전체')),
                _FilterChip(label: "진행 중", isSelected: taskProv.statusFilter == '진행 중', onTap: () => taskProv.setFilter(status: '진행 중')),
                _FilterChip(label: "완료됨", isSelected: taskProv.statusFilter == '완료됨', onTap: () => taskProv.setFilter(status: '완료됨')),
                _vDivider(),

                // 3. 중요도 필터 (복원됨)
                _FilterChip(label: "중요도 전체", isSelected: taskProv.priorityFilter == null, onTap: () => taskProv.setFilter(priority: null)), 
                _FilterChip(label: "상(High)", isSelected: taskProv.priorityFilter == TaskPriority.high, onTap: () => taskProv.setFilter(priority: TaskPriority.high)),
                _vDivider(),

                // 4. 날짜 필터 (복원됨)
                _FilterChip(label: "전체 기간", isSelected: taskProv.dateFilter == DateFilter.all, onTap: () => taskProv.setFilter(date: DateFilter.all)),
                _FilterChip(label: "오늘 마감", isSelected: taskProv.dateFilter == DateFilter.today, onTap: () => taskProv.setFilter(date: DateFilter.today)),
                _FilterChip(label: "이번 주", isSelected: taskProv.dateFilter == DateFilter.week, onTap: () => taskProv.setFilter(date: DateFilter.week)),
              ],
            ),
          ),
          
          // [Section 2] 업무 리스트 영역
          Expanded(
            child: tasks.isEmpty 
              ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.white.withOpacity(0.3))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final project = taskProv.projects.firstWhere(
                      (p) => p.id == task.projectId, 
                      orElse: () => Project(id: '?', teamId: '', name: '알 수 없음', colorValue: 0xFF9E9E9E)
                    );
                    
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => taskProv.deleteTask(task.id),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: task.isDone ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: task.isDone ? Colors.green.withOpacity(0.3) : Colors.transparent),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. 체크박스 및 중요도 배지
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                                  child: Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: task.isDone ? Colors.green : Colors.grey, width: 2),
                                      color: task.isDone ? Colors.green.withOpacity(0.2) : null,
                                    ),
                                    child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.green) : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => taskProv.cycleTaskPriority(task),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task.priority).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _getPriorityColor(task.priority).withOpacity(0.5)),
                                    ),
                                    child: Text(_getPriorityText(task.priority), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(task.priority))),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            
                            // 2. 업무 내용 (제목, 프로젝트, 날짜)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: project.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(project.name, style: TextStyle(fontSize: 11, color: project.color, fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      if (task.isDone && task.completedAt != null)
                                        Text("완료: ${DateFormat('MM.dd').format(task.completedAt!)}", style: const TextStyle(fontSize: 10, color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(task.title, style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold,
                                    color: task.isDone ? Colors.white30 : Colors.white,
                                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                                  )),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("기한: ${DateFormat('yyyy.MM.dd').format(task.dueDate)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // 3. 담당자 이모지
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(task.assigneeEmoji, style: const TextStyle(fontSize: 24)),
                            ),
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

  // [Helper] 구분선 위젯
  Widget _vDivider() => Container(width: 1, height: 16, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8));

  // [Helper] 중요도 색상 및 텍스트
  Color _getPriorityColor(TaskPriority p) {
    if (p == TaskPriority.high) return Colors.redAccent;
    if (p == TaskPriority.medium) return Colors.orangeAccent;
    if (p == TaskPriority.low) return Colors.blueAccent;
    return Colors.grey;
  }
  String _getPriorityText(TaskPriority p) {
    if (p == TaskPriority.high) return "상";
    if (p == TaskPriority.medium) return "중";
    if (p == TaskPriority.low) return "하";
    return "-";
  }

  // [Modal] 업무 추가 모달 (기능 확장됨)
  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    String selectedProjectId = prov.projects.where((p) => p.teamId == teamProv.currentTeamId).isNotEmpty 
        ? prov.projects.firstWhere((p) => p.teamId == teamProv.currentTeamId).id 
        : 'default';
    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3)); 
    
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
              const Text("새 업무 등록", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: selectedProjectId,
                dropdownColor: const Color(0xFF1E293B),
                decoration: InputDecoration(
                  labelText: "프로젝트", labelStyle: const TextStyle(color: Colors.blueAccent),
                  filled: true, fillColor: Colors.black12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
                items: prov.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(
                  value: p.id, child: Text(p.name),
                )).toList(),
                onChanged: (v) => setModalState(() => selectedProjectId = v!),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "업무 내용", labelStyle: const TextStyle(color: Colors.blueAccent),
                  hintText: "무엇을 해야 하나요?", hintStyle: const TextStyle(color: Colors.white24),
                  filled: true, fillColor: Colors.black12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: selectedPriority,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        labelText: "중요도", labelStyle: const TextStyle(color: Colors.blueAccent),
                        filled: true, fillColor: Colors.black12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: TaskPriority.values.map((p) => DropdownMenuItem(
                        value: p, child: Text(_getPriorityText(p)),
                      )).toList(),
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
                          builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
                        );
                        if(d != null) setModalState(() => selectedDate = d);
                      },
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("마감일", style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                            Text(DateFormat('yy.MM.dd').format(selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    prov.addTask(Task(
                      id: const Uuid().v4(),
                      teamId: teamProv.currentTeamId,
                      title: titleCtrl.text,
                      assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
                      projectId: selectedProjectId,
                      createdAt: DateTime.now(), 
                      dueDate: selectedDate,
                      priority: selectedPriority, 
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text("등록하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
  final Color? activeColor;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? const Color(0xFF3B82F6);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.1)),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey, 
            fontSize: 12, 
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }
}