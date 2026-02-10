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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. [수정] 1줄 가로 스크롤 필터 바
          _buildSingleLineFilterBar(taskProv, teamProv),

          // 2. 업무 리스트
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildMasterpieceTaskCard(context, taskProv, teamProv, task);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => _showAddTaskModal(context, taskProv, teamProv),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 10,
              shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.add, size: 24),
            label: const Text("ADD TASK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }

  // [수정] 모든 필터를 한 줄에 배치 (가로 스크롤)
  Widget _buildSingleLineFilterBar(TaskProvider taskProv, TeamProvider teamProv) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterDropdown("프로젝트", taskProv.projectIdFilter, [
            const DropdownMenuItem(value: 'all', child: Text("전체")),
            const DropdownMenuItem(value: 'none', child: Text("없음")),
            ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
          ], (v) => taskProv.setFilter(projectId: v)),
          _vDivider(),
          _filterDropdown("상태", taskProv.statusFilter, const [
            DropdownMenuItem(value: '전체', child: Text("전체")),
            DropdownMenuItem(value: '진행 중', child: Text("진행")),
            DropdownMenuItem(value: '완료됨', child: Text("완료")),
          ], (v) => taskProv.setFilter(status: v)),
          _vDivider(),
          _filterDropdown("중요도", taskProv.priorityFilter, [
            const DropdownMenuItem(value: null, child: Text("전체")),
            ...TaskPriority.values.where((p)=>p != TaskPriority.none).map((p) => DropdownMenuItem(value: p, child: Text(_getPriorityText(p)))),
          ], (v) => taskProv.setFilter(priority: v)),
          _vDivider(),
          _filterDropdown("기한", taskProv.dateFilter, const [
            DropdownMenuItem(value: DateFilter.all, child: Text("전체")),
            DropdownMenuItem(value: DateFilter.today, child: Text("오늘")),
            DropdownMenuItem(value: DateFilter.week, child: Text("이번 주")),
          ], (v) => taskProv.setFilter(date: v)),
          _vDivider(),
          _filterDropdown("작성자", taskProv.memberFilter, [
            const DropdownMenuItem(value: 'all', child: Text("전체")),
            const DropdownMenuItem(value: 'me', child: Text("나")),
            ...teamProv.currentTeam.memberIds.where((id) => id != 'me').map((id) => DropdownMenuItem(value: id, child: Text(id))),
          ], (v) => taskProv.setFilter(member: v)),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, dynamic value, List<DropdownMenuItem> items, Function(dynamic) onChanged) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        DropdownButtonHideUnderline(
          child: DropdownButton(
            value: value,
            isDense: true,
            items: items,
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF2563EB)),
            style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 20, color: Colors.grey[100], margin: const EdgeInsets.symmetric(horizontal: 12));

  Widget _buildMasterpieceTaskCard(BuildContext context, TaskProvider prov, TeamProvider teamProv, Task task) {
    final project = prov.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측 영역: 체크박스(제목 위치로 내림) + 중요도 배지(최하단 배치)
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 28), // [수정] 제목 선상으로 하향
                GestureDetector(
                  onTap: () => prov.updateTaskStatus(task, !task.isDone),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isDone ? const Color(0xFF2563EB) : Colors.transparent,
                      border: Border.all(color: task.isDone ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 2),
                    ),
                    child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _getPriorityColor(task.priority), width: 1.5),
                    color: _getPriorityColor(task.priority).withValues(alpha: 0.05),
                  ),
                  child: Center(
                    child: Text(
                      _getPriorityText(task.priority),
                      style: TextStyle(color: _getPriorityColor(task.priority), fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // [수정] 투명한 음영이 들어간 세련된 프로젝트 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("#${project.name}", style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(task.assigneeEmoji, style: const TextStyle(fontSize: 18)),
                          Text(task.assigneeName, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(task.title, style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900, 
                    color: task.isDone ? Colors.grey[400] : const Color(0xFF0F172A),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                  ),
                  // [수정] 라벨과 날짜 색상을 동일하게 처리
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dateInfoWithColor("작성", task.createdAt, Colors.black54),
                      _dateInfoWithColor("기한", task.dueDate, task.isDone ? Colors.grey : Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dateInfoWithColor("수정", task.updatedAt, const Color(0xFF2563EB)),
                      if (task.isDone && task.completedAt != null)
                        _dateInfoWithColor("완료", task.completedAt!, const Color(0xFF10B981)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [수정] 라벨과 값이 같은 색상을 사용하도록 헬퍼 수정
  Widget _dateInfoWithColor(String label, DateTime date, Color color) {
    return Row(
      children: [
        Text("$label: ", style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900)),
        Text(DateFormat('yy.MM.dd').format(date), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    if (p == TaskPriority.high) return Colors.redAccent;
    if (p == TaskPriority.medium) return Colors.orangeAccent;
    return Colors.blueAccent;
  }

  String _getPriorityText(TaskPriority p) {
    if (p == TaskPriority.high) return "상";
    if (p == TaskPriority.medium) return "중";
    return "하";
  }

  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    // (기존 업무 추가 로직...)
  }
}
