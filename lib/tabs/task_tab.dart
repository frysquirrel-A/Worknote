import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers/task_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart'; // [추가]

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
          // 1. [Fix] 필터 드롭다운 UI (MenuAnchor & 너비 확장)
          _buildFixedFilterBar(context, taskProv, teamProv),

          // 2. 업무 리스트
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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
      floatingActionButton: _buildCustomFAB(context, taskProv, teamProv),
    );
  }

  // 필터 바 레이아웃: MenuAnchor 도입으로 위치 고정
  Widget _buildFixedFilterBar(BuildContext context, TaskProvider taskProv, TeamProvider teamProv) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuAnchorFilter("프로젝트", taskProv.projectIdFilter, [
            _menuEntry('all', "전체 프로젝트", Colors.black87),
            _menuEntry('none', "프로젝트 없음", Colors.grey),
            ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => _menuEntry(p.id, p.name, p.color)),
          ], (v) => taskProv.setProjectIdFilter(v), taskProv),
          
          _menuAnchorFilter("상태", taskProv.statusFilter, [
            _menuEntry('전체', "전체 상태", Colors.black87),
            _menuEntry('진행 중', "진행 중", Colors.orange),
            _menuEntry('완료됨', "완료됨", Colors.green),
          ], (v) => taskProv.setStatusFilter(v), taskProv),

          _menuAnchorFilter("중요도", taskProv.priorityFilter, [
            _menuEntry(null, "전체 중요도", Colors.black87), // [Fix] 전체 버튼 클릭 가능
            _menuEntry(TaskPriority.high, "상 (High)", Colors.redAccent),
            _menuEntry(TaskPriority.medium, "중 (Medium)", Colors.orangeAccent),
            _menuEntry(TaskPriority.low, "하 (Low)", Colors.blueAccent),
            _menuEntry(TaskPriority.none, "없음 (-)", Colors.grey),
          ], (v) => taskProv.setPriorityFilter(v), taskProv),

          _menuAnchorFilter("작성일", taskProv.dateFilter, [
            _menuEntry(DateFilter.all, "전체 기간", Colors.black87),
            _menuEntry(DateFilter.today, "오늘", Colors.blueAccent),
            _menuEntry(DateFilter.week, "이번 주", Colors.blueAccent),
            _menuEntry(DateFilter.oneMonth, "이번 달", Colors.blueAccent),
            _menuEntry(DateFilter.twoWeeks, "올해", Colors.blueAccent),
          ], (v) => taskProv.setDateFilter(v), taskProv),

          _menuAnchorFilter("담당자", taskProv.assigneeFilter, [
            _menuEntry('all', "전체 담당자", Colors.black87),
            _menuEntry('me', "나", Colors.blueAccent),
            ...teamProv.currentTeam.memberIds.where((id) => id != 'me').map((id) => _menuEntry(id, id, Colors.black87)),
          ], (v) => taskProv.setAssigneeFilter(v), taskProv),
        ],
      ),
    );
  }

  Widget _menuAnchorFilter(String label, dynamic currentValue, List<Widget> menuItems, Function(dynamic) onSelected, TaskProvider prov) {
    final bool isDefault = (currentValue == null || currentValue == 'all' || currentValue == '전체');
    final Color displayColor = isDefault ? Colors.black87 : const Color(0xFF2563EB);

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        minimumSize: WidgetStateProperty.all(const Size(160, 0)), // [Fix] 너비 확장
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () {
            if (controller.isOpen) controller.close();
            else controller.open();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                _getDisplayValue(label, currentValue, prov),
                style: TextStyle(fontSize: 11, color: displayColor, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        );
      },
      menuChildren: menuItems.map((item) {
        if (item is _MenuEntryWidget) {
          return MenuItemButton(
            onPressed: () => onSelected(item.value),
            child: item,
          );
        }
        return item;
      }).toList(),
    );
  }

  // [Layout] 업무 카드 정보 전면 재배치 (날짜 좌측 뭉치 + 담당자 우측 강조)
  Widget _buildMasterpieceTaskCard(BuildContext context, TaskProvider prov, TeamProvider teamProv, Task task) {
    final project = prov.projects.firstWhere(
      (p) => p.id == task.projectId, 
      orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8)
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 좌측 영역: 체크박스 & 중요도 배지
            Column(
              children: [
                const SizedBox(height: 38),
                GestureDetector(
                  onTap: () => prov.updateTaskStatus(task, !task.isDone),
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isDone ? const Color(0xFF2563EB) : Colors.white,
                      border: Border.all(color: task.isDone ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 2.5),
                    ),
                    child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => prov.cycleTaskPriority(task),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _getPriorityColor(task.priority), width: 2.5), color: _getPriorityColor(task.priority).withValues(alpha: 0.05)),
                    child: Center(child: Text(_getPriorityText(task.priority), style: TextStyle(color: _getPriorityColor(task.priority), fontWeight: FontWeight.w900, fontSize: 14))),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            
            // 2. 중앙 영역: 프로젝트 + 제목 + 날짜 뭉치(2열 2행)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: project.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text("#${project.name}", style: TextStyle(color: project.color, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 4),
                  Text(task.title, style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900, 
                    color: task.isDone ? Colors.grey[400] : const Color(0xFF1E293B),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  )),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5)),
                  
                  // [수정] 날짜 정보 좌측 집결 (2열 2행 Grid 스타일)
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
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

            // 3. 우측 영역: 상(작성자) / 하(담당자) 분할 및 겹침 효과
            const VerticalDivider(width: 32, thickness: 1, color: Color(0xFFF1F5F9)),
            SizedBox(
              width: 65,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("작성자", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(task.creatorName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54), overflow: TextOverflow.ellipsis),
                  
                  const SizedBox(height: 12),
                  
                  const Text("담당", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildAssigneeAvatars(task),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [UX] 담당자 겹침(Stack) 효과 위젯
  Widget _buildAssigneeAvatars(Task task) {
    if (task.assigneeId == 'all') {
      return const Text("ALL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)));
    }

    final emojis = task.assigneeEmojis.isNotEmpty ? task.assigneeEmojis : [task.assigneeEmoji];
    if (emojis.length == 1) {
      return Text(emojis[0], style: const TextStyle(fontSize: 28));
    }

    // 다중 담당자 겹침
    return SizedBox(
      height: 35,
      width: 55,
      child: Stack(
        children: List.generate(emojis.length > 3 ? 3 : emojis.length, (index) {
          return Positioned(
            left: index * 14.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(emojis[index], style: const TextStyle(fontSize: 22)),
            ),
          );
        }) + [
          if (emojis.length > 3)
            Positioned(
              left: 38,
              top: 8,
              child: Text("+${emojis.length - 3}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            )
        ],
      ),
    );
  }

  Widget _compactDate(String label, DateTime date, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label: ", style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
        Text(DateFormat('yy.MM.dd').format(date), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _menuEntry(dynamic value, String label, Color color) {
    return _MenuEntryWidget(value: value, label: label, color: color);
  }

  String _getDisplayValue(String label, dynamic value, TaskProvider prov) {
    if (value == null || value == 'all' || value == '전체') return "전체";
    if (value == 'none') return "없음";
    if (value == 'me') return "나";
    if (value is TaskPriority) return _getPriorityText(value);
    if (label == "프로젝트") return prov.getProjectName(value.toString());
    return value.toString();
  }

  Widget _buildCustomFAB(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _showAddTaskModal(context, prov, teamProv),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), 
          foregroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
          elevation: 10
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text("ADD TASK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    if (p == TaskPriority.high) return const Color(0xFFEF4444);
    if (p == TaskPriority.medium) return const Color(0xFFF59E0B);
    if (p == TaskPriority.low) return const Color(0xFF3B82F6);
    return Colors.grey;
  }

  String _getPriorityText(TaskPriority p) {
    if (p == TaskPriority.high) return "상";
    if (p == TaskPriority.medium) return "중";
    if (p == TaskPriority.low) return "하";
    return "-";
  }

  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    final authProv = context.read<AuthProvider>();
    String? selectedProjectId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("새 업무 등록", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String?>(
                value: selectedProjectId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("프로젝트 없음")),
                  ...prov.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => DropdownMenuItem(
                    value: p.id, child: Text(p.name),
                  )),
                ],
                onChanged: (v) => setModalState(() => selectedProjectId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "업무 내용", hintText: "무엇을 해야 하나요?", filled: true, fillColor: Color(0xFFF1F5F9)),
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
                      creatorId: authProv.currentUser?.id ?? 'me',
                      creatorName: authProv.currentUser?.name ?? '나',
                      assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
                      projectId: selectedProjectId, createdAt: DateTime.now(), dueDate: DateTime.now().add(const Duration(days: 3)),
                    ));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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

class _MenuEntryWidget extends StatelessWidget {
  final dynamic value;
  final String label;
  final Color color;
  const _MenuEntryWidget({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}
