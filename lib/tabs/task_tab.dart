import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../models.dart';
import '../providers/task_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';

class TeamTaskTab extends StatefulWidget {
  const TeamTaskTab({super.key});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  String _groupMode = "일별"; 
  bool _isDescending = true;

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);

    final Map<String, List<Task>> groupedTasks = _groupTasks(tasks);
    final sortedKeys = groupedTasks.keys.toList()
      ..sort((a, b) => _isDescending ? b.compareTo(a) : a.compareTo(b));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHardFixedFilterBar(context, taskProv, teamProv),
          _buildTimelineControlBar(),
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final dateTasks = groupedTasks[dateKey]!;
                      return _buildTimelineGroup(dateKey, dateTasks, context, taskProv, teamProv);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCustomFAB(context, taskProv, teamProv),
    );
  }

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
            _menuEntry('all', "전체", Colors.black87),
            _menuEntry('none', "없음", Colors.grey),
            ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => _menuEntry(p.id, p.name, p.color)),
          ], (v) => taskProv.setProjectIdFilter(v), taskProv),
          
          _fixedMenuAnchor("상태", taskProv.statusFilter, [
            _menuEntry('전체', "전체", Colors.black87),
            _menuEntry('진행 중', "진행", Colors.orange),
            _menuEntry('완료됨', "완료", Colors.green),
          ], (v) => taskProv.setStatusFilter(v), taskProv),

          // [Fix] 'all' 값을 사용하여 '전체' 클릭 활성화
          _fixedMenuAnchor("중요도", taskProv.priorityFilter, [
            _menuEntry('all', "전체", Colors.black87),
            _menuEntry(TaskPriority.high, "상", Colors.redAccent),
            _menuEntry(TaskPriority.medium, "중", Colors.orangeAccent),
            _menuEntry(TaskPriority.low, "하", Colors.blueAccent),
            _menuEntry(TaskPriority.none, "-", Colors.grey),
          ], (v) => taskProv.setPriorityFilter(v == 'all' ? null : v), taskProv),

          _fixedMenuAnchor("작성일", taskProv.dateFilter, [
            _menuEntry(DateFilter.all, "전체", Colors.black87),
            _menuEntry(DateFilter.today, "오늘", Colors.blueAccent),
            _menuEntry(DateFilter.week, "이번 주", Colors.blueAccent),
            _menuEntry(DateFilter.oneMonth, "이번 달", Colors.blueAccent),
            _menuEntry(DateFilter.twoWeeks, "올해", Colors.blueAccent),
          ], (v) => taskProv.setDateFilter(v), taskProv),

          _fixedMenuAnchor("담당자", taskProv.assigneeFilter, [
            _menuEntry('all', "전체", Colors.black87),
            _menuEntry('me', "나", Colors.blueAccent),
            ...teamProv.currentTeam.memberIds.where((id) => id != 'me').map((id) => _menuEntry(id, id, Colors.black87)),
          ], (v) => taskProv.setAssigneeFilter(v), taskProv),
        ],
      ),
    );
  }

  Widget _fixedMenuAnchor(String label, dynamic currentValue, List<Widget> menuItems, Function(dynamic) onSelected, TaskProvider prov) {
    final bool isDefault = (currentValue == null || currentValue == 'all' || currentValue == '전체');
    final Color displayColor = isDefault ? Colors.black87 : const Color(0xFF2563EB);

    return Expanded(
      flex: 1,
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 10),
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
          minimumSize: WidgetStateProperty.all(const Size(160, 0)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          alignment: Alignment.bottomLeft,
        ),
        builder: (context, controller, child) {
          return GestureDetector(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: Container(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    _getDisplayValue(label, currentValue, taskProv: prov),
                    style: TextStyle(fontSize: 11, color: displayColor, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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

  Widget _buildTimelineControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: "일별", label: Text("일", style: TextStyle(fontSize: 11))),
              ButtonSegment(value: "월별", label: Text("월", style: TextStyle(fontSize: 11))),
              ButtonSegment(value: "연별", label: Text("연", style: TextStyle(fontSize: 11))),
            ],
            selected: {_groupMode},
            onSelectionChanged: (val) => setState(() => _groupMode = val.first),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          IconButton(
            icon: Icon(_isDescending ? Icons.south_rounded : Icons.north_rounded, size: 18, color: Colors.blueAccent),
            onPressed: () => setState(() => _isDescending = !_isDescending),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGroup(String dateKey, List<Task> dateTasks, BuildContext context, TaskProvider taskProv, TeamProvider teamProv) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text(_formatGroupHeader(dateKey), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(width: 8),
            Text("${dateTasks.length}", style: TextStyle(fontSize: 12, color: Colors.blueAccent.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          ],
        ),
        children: dateTasks.map((task) => _buildStrictFixedCard(context, taskProv, teamProv, task)).toList(),
      ),
    );
  }

  Widget _buildStrictFixedCard(BuildContext context, TaskProvider prov, TeamProvider teamProv, Task task) {
    final project = prov.projects.firstWhere(
      (p) => p.id == task.projectId, 
      orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8)
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  const SizedBox(height: 24), 
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
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("작성자", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(task.creatorName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black54), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  const Text("담당", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                  _buildAssigneeAvatars(task),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeAvatars(Task task) {
    final emojis = task.assigneeEmojis.isNotEmpty ? task.assigneeEmojis : [task.assigneeEmoji];
    if (emojis.length == 1) return Text(emojis[0], style: const TextStyle(fontSize: 22));
    return SizedBox(
      height: 30, width: 50,
      child: Stack(
        children: List.generate(emojis.length > 3 ? 3 : emojis.length, (i) => Positioned(left: i * 12.0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: Text(emojis[i], style: const TextStyle(fontSize: 18))))),
      ),
    );
  }

  Map<String, List<Task>> _groupTasks(List<Task> tasks) {
    if (_groupMode == "연별") return groupBy(tasks, (t) => DateFormat('yyyy').format(t.createdAt));
    if (_groupMode == "월별") return groupBy(tasks, (t) => DateFormat('yyyy-MM').format(t.createdAt));
    return groupBy(tasks, (t) => DateFormat('yyyy-MM-dd').format(t.createdAt));
  }

  String _formatGroupHeader(String key) {
    try {
      final date = _groupMode == "연별" ? DateTime(int.parse(key)) : (_groupMode == "월별" ? DateFormat('yyyy-MM').parse(key) : DateTime.parse(key));
      return _groupMode == "연별" ? key + "년" : (_groupMode == "월별" ? DateFormat('yyyy년 M월').format(date) : DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(date));
    } catch (e) { return key; }
  }

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

  void _showTaskDetailModal(BuildContext context, Task task, TaskProvider prov) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7, padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("업무 상세 정보", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]),
          const Divider(height: 32),
          Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _detailRow("우선순위", _getPriorityText(task.priority), _getPriorityColor(task.priority)),
          _detailRow("기한", DateFormat('yyyy.MM.dd').format(task.dueDate), Colors.redAccent),
          _detailRow("작성일", DateFormat('yyyy.MM.dd').format(task.createdAt), Colors.grey),
          const Spacer(),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () { prov.deleteTask(task.id); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.1), foregroundColor: Colors.redAccent), child: const Text("삭제"))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () { prov.updateTaskStatus(task, !task.isDone); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white), child: Text(task.isDone ? "진행 중으로 변경" : "완료 처리"))),
          ])
        ]),
      ),
    );
  }

  Widget _detailRow(String l, String v, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Text("$l: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900))]));

  void _showAddTaskModal(BuildContext context, TaskProvider prov, TeamProvider teamProv) {
    final titleCtrl = TextEditingController();
    final authProv = context.read<AuthProvider>();
    DateTime selDate = DateTime.now().add(const Duration(days: 3));
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Container(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("새 업무 등록", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 24), TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "업무 내용", border: OutlineInputBorder())), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () { if (titleCtrl.text.isEmpty) return; prov.addTask(Task(id: const Uuid().v4(), teamId: teamProv.currentTeamId, title: titleCtrl.text, creatorId: authProv.currentUser?.id ?? 'me', creatorName: authProv.currentUser?.name ?? '나', assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷', projectId: null, createdAt: DateTime.now(), dueDate: selDate)); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white), child: const Text("등록하기")))],),),),);
  }
}

class _MenuEntryWidget extends StatelessWidget {
  final dynamic value;
  final String label;
  final Color color;
  const _MenuEntryWidget({required this.value, required this.label, required this.color});
  @override Widget build(BuildContext context) => Container(constraints: const BoxConstraints(minWidth: 140), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)));
}
