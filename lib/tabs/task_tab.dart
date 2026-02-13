import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers/task_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';

class TeamTaskTab extends StatelessWidget {
  const TeamTaskTab({super.key});

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // 1. [Rule] 5등분 강제 고정 필터 바
          _buildHardFixedFilterBar(context, taskProv, teamProv),

          // 2. 업무 리스트 (바닥 여백 0)
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), // [Rule] Bottom Padding 0
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildStrictFixedCard(context, taskProv, teamProv, task);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCustomFAB(context, taskProv, teamProv),
    );
  }

  // 필터 바: Row 내부 Expanded(flex:1) 5개를 사용하여 강제 5등분
  Widget _buildHardFixedFilterBar(BuildContext context, TaskProvider taskProv, TeamProvider teamProv) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _fixedMenuAnchor("프로젝트", taskProv.projectIdFilter, [
            _menuEntry('all', "전체 프로젝트", Colors.black87),
            _menuEntry('none', "프로젝트 없음", Colors.grey),
            ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => _menuEntry(p.id, p.name, p.color)),
          ], (v) => taskProv.setProjectIdFilter(v), taskProv),
          
          _fixedMenuAnchor("상태", taskProv.statusFilter, [
            _menuEntry('전체', "전체 상태", Colors.black87),
            _menuEntry('진행 중', "진행 중", Colors.orange),
            _menuEntry('완료됨', "완료됨", Colors.green),
          ], (v) => taskProv.setStatusFilter(v), taskProv),

          _fixedMenuAnchor("중요도", taskProv.priorityFilter, [
            _menuEntry(null, "전체 중요도", Colors.black87),
            _menuEntry(TaskPriority.high, "상", Colors.redAccent),
            _menuEntry(TaskPriority.medium, "중", Colors.orangeAccent),
            _menuEntry(TaskPriority.low, "하", Colors.blueAccent),
            _menuEntry(TaskPriority.none, "-", Colors.grey),
          ], (v) => taskProv.setPriorityFilter(v), taskProv),

          _fixedMenuAnchor("작성일", taskProv.dateFilter, [
            _menuEntry(DateFilter.all, "전체 기간", Colors.black87),
            _menuEntry(DateFilter.today, "오늘", Colors.blueAccent),
            _menuEntry(DateFilter.week, "이번 주", Colors.blueAccent),
            _menuEntry(DateFilter.oneMonth, "이번 달", Colors.blueAccent),
            _menuEntry(DateFilter.twoWeeks, "올해", Colors.blueAccent),
          ], (v) => taskProv.setDateFilter(v), taskProv),

          _fixedMenuAnchor("담당자", taskProv.assigneeFilter, [
            _menuEntry('all', "전체 담당자", Colors.black87),
            _menuEntry('me', "나", Colors.blueAccent),
            ...teamProv.currentTeam.memberIds.where((id) => id != 'me').map((id) => _menuEntry(id, id, Colors.black87)),
          ], (v) => taskProv.setAssigneeFilter(v), taskProv),
        ],
      ),
    );
  }

  // [Rule] Expanded로 너비를 가두고, MenuAnchor로 위치를 좌표 고정
  Widget _fixedMenuAnchor(String label, dynamic currentValue, List<Widget> menuItems, Function(dynamic) onSelected, TaskProvider prov) {
    final bool isDefault = (currentValue == null || currentValue == 'all' || currentValue == '전체' || currentValue == DateFilter.all);
    final Color displayColor = isDefault ? Colors.black87 : const Color(0xFF2563EB);

    return Expanded(
      flex: 1,
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 10), // [Rule] 수직 하단 10px 고정
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
          minimumSize: WidgetStateProperty.all(const Size(160, 0)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          alignment: Alignment.bottomLeft, // [Rule] 왼쪽 정렬 하단 개방
        ),
        builder: (context, controller, child) {
          return GestureDetector(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  _getDisplayValue(label, currentValue, taskProv: prov),
                  style: TextStyle(fontSize: 11, color: displayColor, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis, // [Rule] 넘치면 생략
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        menuChildren: menuItems.map((item) {
          if (item is _MenuEntryWidget) {
            return MenuItemButton(onPressed: () => onSelected(item.value), child: item);
          }
          return item;
        }).toList(),
      ),
    );
  }

  // [Rule] 3구역 철저 분리 카드 (40px | Expanded | 60px)
  Widget _buildStrictFixedCard(BuildContext context, TaskProvider prov, TeamProvider teamProv, Task task) {
    final project = prov.projects.firstWhere(
      (p) => p.id == task.projectId, 
      orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8)
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12), // [Rule] 패딩 최소화
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Zone 1: 좌측 고정 (40px) ---
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  const SizedBox(height: 14), 
                  GestureDetector(
                    onTap: () => prov.updateTaskStatus(task, !task.isDone),
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: task.isDone ? const Color(0xFF2563EB) : Colors.white, border: Border.all(color: task.isDone ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 2)),
                      child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => prov.cycleTaskPriority(task),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _getPriorityColor(task.priority), width: 2), color: _getPriorityColor(task.priority).withValues(alpha: 0.05)),
                      child: Center(child: Text(_getPriorityText(task.priority), style: TextStyle(color: _getPriorityColor(task.priority), fontWeight: FontWeight.w900, fontSize: 13))),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),

            // --- Zone 2: 중앙 가변 (Expanded) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: project.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text("#${project.name}", style: TextStyle(color: project.color, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 2),
                  Text(task.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: task.isDone ? Colors.grey[400] : const Color(0xFF1E293B), decoration: task.isDone ? TextDecoration.lineThrough : null)),
                  const Divider(color: Color(0xFFF1F5F9), height: 12, thickness: 1),
                  Wrap(
                    spacing: 12, runSpacing: 4,
                    children: [
                      _compactDate("작성", task.createdAt, Colors.black45),
                      _compactDate("기한", task.dueDate, task.isDone ? Colors.grey : Colors.redAccent),
                      _compactDate("수정", task.updatedAt, const Color(0xFF2563EB)),
                      if (task.isDone && task.completedAt != null)
                        _compactDate("완료", task.completedAt!, const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // --- Zone 3: 우측 고정 (60px) ---
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // [Rule] 가운데 정렬
                children: [
                  const Text("작성자", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(task.creatorName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black54), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  const Text("담당", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(task.assigneeEmoji, style: const TextStyle(fontSize: 22)),
                  Text(task.assigneeName, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black54), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 유틸리티 함수들
  Widget _compactDate(String label, DateTime date, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [Text("$label: ", style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)), Text(DateFormat('yy.MM.dd').format(date), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900))]);
  Widget _menuEntry(dynamic value, String label, Color color) => _MenuEntryWidget(value: value, label: label, color: color);
  
  String _getDisplayValue(String label, dynamic value, {required TaskProvider taskProv}) {
    if (value == null || value == 'all' || value == '전체' || value == DateFilter.all) return "전체";
    if (value == 'none') return "없음";
    if (value == 'me') return "나";
    if (value is TaskPriority) return _getPriorityText(value);
    if (value is DateFilter) {
      if (value == DateFilter.today) return "오늘";
      if (value == DateFilter.week) return "이번 주";
      if (value == DateFilter.oneMonth) return "이번 달";
      if (value == DateFilter.twoWeeks) return "올해";
    }
    if (label == "프로젝트") return taskProv.getProjectName(value.toString());
    return value.toString();
  }

  Widget _buildCustomFAB(BuildContext context, TaskProvider prov, TeamProvider teamProv) => Container(padding: const EdgeInsets.symmetric(horizontal: 20), width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => _showAddTaskModal(context, prov, teamProv), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10), icon: const Icon(Icons.add_rounded, size: 24), label: const Text("ADD TASK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2))));
  Color _getPriorityColor(TaskPriority p) => p == TaskPriority.high ? const Color(0xFFEF4444) : (p == TaskPriority.medium ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6));
  String _getPriorityText(TaskPriority p) => p == TaskPriority.high ? "상" : (p == TaskPriority.medium ? "중" : "하");

  void _showTaskDetailModal(BuildContext context, Task task, TaskProvider prov) {}
  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {}
}

class _MenuEntryWidget extends StatelessWidget {
  final dynamic value;
  final String label;
  final Color color;
  const _MenuEntryWidget({required this.value, required this.label, required this.color});
  @override Widget build(BuildContext context) => Container(constraints: const BoxConstraints(minWidth: 140), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)));
}
