import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../models.dart';
import '../providers/task_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/journal_provider.dart'; 

enum TaskCardLayout { classic, gallery }
enum TaskSortField { createdAt, updatedAt, dueDate, schedule, completedAt }

class TeamTaskTab extends StatefulWidget {
  const TeamTaskTab({super.key});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  // 1. 필터 상태
  String _selProjectId = 'all';
  String _selStatus = '진행중'; 
  TaskPriority? _selPriority;
  String _selAssignee = 'all';

  // 2. 그룹/정렬/레이아웃 상태
  String _groupMode = '일'; 
  TaskSortField _sortField = TaskSortField.dueDate;
  bool _isDescending = true;
  TaskCardLayout _cardLayout = TaskCardLayout.classic;
  final Map<String, bool> _groupExpandedStatus = {}; 

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';

    final filteredTasks = taskProv.tasks.where((t) {
      if (t.teamId != teamProv.currentTeamId) return false;
      if (_selProjectId != 'all' && (_selProjectId == 'none' ? t.projectId != null : t.projectId != _selProjectId)) return false;
      if (_selStatus == '진행중' && t.isDone) return false;
      if (_selStatus == '완료' && !t.isDone) return false;
      if (_selPriority != null && t.priority != _selPriority) return false;
      if (_selAssignee != 'all' && !t.assigneeIds.contains(_selAssignee == 'me' ? myId : _selAssignee)) return false;
      return true;
    }).toList();

    final Map<String, List<Task>> grouped = _groupAndSortTasks(filteredTasks, taskProv);
    final sortedGroupKeys = grouped.keys.toList()..sort((a, b) => _isDescending ? b.compareTo(a) : a.compareTo(b));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildIntegratedControlPanel(context, taskProv, teamProv, myId),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(child: Text("조건에 맞는 업무가 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), 
                    itemCount: sortedGroupKeys.length,
                    itemBuilder: (context, index) {
                      final key = sortedGroupKeys[index];
                      return _buildTimelineGroup(key, grouped[key]!, context, taskProv, teamProv);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCustomFAB(context, taskProv, teamProv),
    );
  }

  // --- [통합 컨트롤 패널] 촘촘한 한 줄 배치 및 아이콘 복귀 ---
  Widget _buildIntegratedControlPanel(BuildContext context, TaskProvider taskProv, TeamProvider teamProv, String myId) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          // 1. 왼쪽: 필터 영역 (가로 스크롤)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipBox(label: "프로젝트", value: _getDisplayValue("프로젝트", _selProjectId, taskProv: taskProv), width: 84, onTap: () => _openFilterSheet("프로젝트 선택", [_option("all", "전체"), _option("none", "없음"), ...taskProv.projects.where((p) => p.teamId == teamProv.currentTeamId).map((p) => _option(p.id, p.name))], _selProjectId, (v) => setState(() => _selProjectId = v))),
                  _FilterChipBox(label: "상태", value: _selStatus, width: 84, onTap: () => _openFilterSheet("상태 선택", [_option("진행중", "진행중"), _option("완료", "완료")], _selStatus, (v) => setState(() => _selStatus = v))),
                  _FilterChipBox(label: "중요도", value: _getPriorityText(_selPriority), width: 84, onTap: () => _openFilterSheet("중요도 선택", [_option(null, "전체"), _option(TaskPriority.high, "상"), _option(TaskPriority.medium, "중"), _option(TaskPriority.low, "하")], _selPriority, (v) => setState(() => _selPriority = v))),
                  _FilterChipBox(label: "담당자", value: _getDisplayValue("담당자", _selAssignee, taskProv: taskProv), width: 84, onTap: () => _openFilterSheet("담당자 선택", [_option("all", "전체"), _option("me", "나"), ...teamProv.currentTeam.memberIds.where((id) => id != myId).map((id) => _option(id, id))], _selAssignee, (v) => setState(() => _selAssignee = v))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.2)), // 세로 구분선
          const SizedBox(width: 8),
          // 2. 오른쪽: 컨트롤 영역 (고정)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterChipBox(label: "그룹", value: _groupMode, width: 48, onTap: () => _openFilterSheet("그룹 기준", [_option("일", "일별"), _option("주", "주별"), _option("월", "월별"), _option("분기", "분기별"), _option("년", "연별")], _groupMode, (v) => setState(() => _groupMode = v))),
              _FilterChipBox(label: "정렬", value: _getSortLabel(_sortField), width: 48, onTap: () => _openFilterSheet("정렬 기준", TaskSortField.values.map((f) => _option(f, _getSortLabel(f))).toList(), _sortField, (v) => setState(() => _sortField = v))),
              _iconButton(_isDescending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, () => setState(() => _isDescending = !_isDescending)),
              _iconButton(_cardLayout == TaskCardLayout.classic ? Icons.view_agenda_outlined : Icons.grid_view_outlined, () => setState(() => _cardLayout = _cardLayout == TaskCardLayout.classic ? TaskCardLayout.gallery : TaskCardLayout.classic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _FilterChipBox({required String label, required String value, required VoidCallback onTap, double width = 84}) {
    final bool isHighlighted = (value != "전체" && value != "진행중" && value != "일" && value != "기한");
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHighlighted ? const Color(0xFF2563EB).withOpacity(0.2) : Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 10, color: isHighlighted ? const Color(0xFF2563EB) : Colors.black87, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) => Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: Container(width: 36, height: 36, child: Icon(icon, size: 20, color: const Color(0xFF2563EB)))));

  // --- 2. 카드 UI (리스트 모드) ---
  Widget _buildStrictFixedCard(BuildContext context, TaskProvider prov, TeamProvider teamProv, Task task) {
    final project = prov.projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8));
    final hasSchedule = prov.isIncludedInSchedule(task.id);
    final scheduleRange = prov.effectiveScheduleRange(task);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showTaskDetailModal(context, task, prov),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckbox(prov, task),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildProjectChip(project), const SizedBox(height: 4), _buildTitle(task, maxLines: 1)])),
                          _buildFixedScheduleIcon(context, prov, task, hasSchedule),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.only(top: 2), child: _buildPriorityBadge(prov, task)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildFixedMetaLines(task, scheduleRange, prov)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildAuthorZone(task), 
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorZone(Task task) => SizedBox(
    width: 88,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("담당", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _buildAssigneeAvatars(task),
        const SizedBox(height: 6),
        Text(task.assigneeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, maxLines: 1),
      ],
    ),
  );

  Widget _buildFixedMetaLines(Task task, DateTimeRange? scheduleRange, TaskProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [_metaText("작성", task.createdAt), const SizedBox(width: 12), _metaText("기한", task.dueDate, isDeadLine: true)]),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(task.isDone ? Icons.check_circle_outline_rounded : Icons.history_rounded, size: 12, color: task.isDone ? Colors.green : Colors.grey),
            const SizedBox(width: 4),
            Text(
              task.isDone ? "완료: ${DateFormat('MM/dd').format(task.completedAt ?? task.updatedAt)}" : "수정: ${DateFormat('MM/dd').format(task.updatedAt)}", 
              style: TextStyle(fontSize: 10, color: task.isDone ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)
            ),
            if (scheduleRange != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Expanded(child: Text("${DateFormat('MM/dd').format(scheduleRange.start)}~${DateFormat('MM/dd').format(scheduleRange.end)}", style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ],
        ),
      ],
    );
  }

  // --- 3. 카드 UI (갤러리 모드) ---
  Widget _buildGalleryCard(BuildContext context, TaskProvider prov, TeamProvider teamProv, Task task) {
    final project = prov.projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8));
    final hasSchedule = prov.isIncludedInSchedule(task.id);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTaskDetailModal(context, task, prov),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckbox(prov, task),
                    const SizedBox(height: 10),
                    _buildProjectChip(project),
                    const SizedBox(height: 4),
                    _buildTitle(task, maxLines: 1),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriorityBadge(prov, task),
                        Text(DateFormat('MM/dd').format(task.dueDate), style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
                Positioned(top: 0, right: 0, child: Row(children: [if (hasSchedule) const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF2563EB)), const SizedBox(width: 4), Text(task.assigneeEmoji, style: const TextStyle(fontSize: 14))])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 4. 헬퍼 및 기타 UI ---
  void _openFilterSheet(String title, List<Map<String, dynamic>> options, dynamic currentVal, Function(dynamic) onSelect) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))), builder: (ctx) => Container(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 16), ...options.map((opt) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 32), title: Text(opt['label'], style: TextStyle(fontWeight: opt['value'] == currentVal ? FontWeight.w900 : FontWeight.normal, color: opt['value'] == currentVal ? const Color(0xFF2563EB) : Colors.black87)), trailing: opt['value'] == currentVal ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null, onTap: () { onSelect(opt['value']); Navigator.pop(ctx); })), const SizedBox(height: 24)])));
  }
  Map<String, dynamic> _option(dynamic val, String label) => {'value': val, 'label': label};

  void _showTaskDetailModal(BuildContext context, Task task, TaskProvider prov) {
    final journalProv = context.read<JournalProvider>();
    final relatedJournals = journalProv.journals.where((j) => j.content.contains(task.title) || j.title.contains(task.title)).take(3).toList();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))), builder: (ctx) => DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.5, expand: false, builder: (_, scrollController) => Container(padding: const EdgeInsets.all(24), child: ListView(controller: scrollController, children: [_buildProjectChip(prov.projects.firstWhere((p) => p.id == task.projectId, orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8))), const SizedBox(height: 12), Text(task.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const Divider(height: 32), _detailRow(Icons.flag_rounded, "중요도", _getPriorityText(task.priority), color: _getPriorityColor(task.priority)), _detailRow(Icons.event_available_rounded, "기한", DateFormat('yyyy.MM.dd').format(task.dueDate), color: Colors.redAccent), _detailRow(Icons.person_outline_rounded, "담당자", task.assigneeName), if (prov.isIncludedInSchedule(task.id)) _detailRow(Icons.timer_outlined, "일정", "${DateFormat('MM.dd').format(prov.effectiveScheduleRange(task)!.start)} ~ ${DateFormat('MM.dd').format(prov.effectiveScheduleRange(task)!.end)}", color: const Color(0xFF2563EB)), const SizedBox(height: 32), const Text("관련 일지", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))), const SizedBox(height: 12), if (relatedJournals.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("연결된 일지가 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 13)))) else ...relatedJournals.map((j) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_note_rounded, color: Colors.grey), title: Text(j.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(DateFormat('MM/dd').format(j.date), style: const TextStyle(fontSize: 11)), trailing: const Icon(Icons.chevron_right_rounded, size: 18), onTap: () { Navigator.pop(ctx); })), const SizedBox(height: 40)]))));
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Icon(icon, size: 18, color: color ?? Colors.grey[600]), const SizedBox(width: 12), Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)), const Spacer(), Text(value, style: TextStyle(color: color ?? const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14))]));
  Widget _buildFixedScheduleIcon(BuildContext context, TaskProvider prov, Task task, bool hasSchedule) => Material(color: Colors.transparent, child: InkWell(onTap: () => _showScheduleSetter(context, task, prov), borderRadius: BorderRadius.circular(8), child: Container(width: 36, height: 36, alignment: Alignment.topRight, child: Icon(Icons.calendar_month_rounded, size: 22, color: hasSchedule ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)))));
  void _showScheduleSetter(BuildContext context, Task task, TaskProvider prov) { bool isIncluded = prov.isIncludedInSchedule(task.id); DateTimeRange? currentRange = prov.effectiveScheduleRange(task); showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))), builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("일정 설정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 24), SwitchListTile(title: const Text("전체 스케줄에 포함", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("체크 시 달력 및 홈 화면에 기간이 표시됩니다."), value: isIncluded, activeColor: const Color(0xFF2563EB), onChanged: (v) => setModalState(() => isIncluded = v)), const Divider(), ListTile(leading: const Icon(Icons.date_range_rounded, color: Color(0xFF2563EB)), title: const Text("기간 선택", style: TextStyle(fontWeight: FontWeight.bold)), trailing: Text(currentRange == null ? "미설정" : "${DateFormat('MM/dd').format(currentRange!.start)} ~ ${DateFormat('MM/dd').format(currentRange!.end)}", style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900)), onTap: () async { final picked = await showDateRangePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDateRange: currentRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 1))), builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB))), child: child!)); if (picked != null) { setModalState(() => currentRange = picked); } }), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: () async { await prov.setScheduleOptions(taskId: task.id, includeInSchedule: isIncluded, range: currentRange); if (context.mounted) Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("저장하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))), const SizedBox(height: 12)])))); }
  Widget _metaText(String label, DateTime date, {bool isDeadLine = false}) => Text("$label: ${DateFormat('MM/dd').format(date)}", style: TextStyle(fontSize: 10, color: isDeadLine ? Colors.redAccent : Colors.grey[600], fontWeight: FontWeight.bold));
  Widget _buildCheckbox(TaskProvider prov, Task task) => GestureDetector(onTap: () => prov.updateTaskStatus(task, !task.isDone), child: Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: task.isDone ? const Color(0xFF2563EB) : Colors.white, border: Border.all(color: task.isDone ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 2.5)), child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null));
  Widget _buildPriorityBadge(TaskProvider prov, Task task) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _getPriorityColor(task.priority).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(_getPriorityText(task.priority), style: TextStyle(color: _getPriorityColor(task.priority), fontWeight: FontWeight.w900, fontSize: 10)));
  Widget _buildAssigneeAvatars(Task task) { final emojis = task.assigneeEmojis.isNotEmpty ? task.assigneeEmojis : [task.assigneeEmoji]; if (emojis.length == 1) return Text(emojis[0], style: const TextStyle(fontSize: 22)); return SizedBox(height: 26, width: 44, child: Stack(children: List.generate(emojis.length > 3 ? 3 : emojis.length, (i) => Positioned(left: i * 10.0, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)), child: Text(emojis[i], style: const TextStyle(fontSize: 16))))))); }
  Widget _controlDropdown<T>({required T value, required List<T> items, String Function(T)? labelBuilder, required ValueChanged<T?> onChanged}) => DropdownButtonHideUnderline(child: DropdownButton<T>(value: value, items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(labelBuilder?.call(i) ?? i.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(), onChanged: onChanged, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold), icon: const Icon(Icons.arrow_drop_down_rounded, size: 20)));
  Widget _buildProjectChip(Project p) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: p.color.withOpacity(0.08), borderRadius: BorderRadius.circular(4)), child: Text("#${p.name}", style: TextStyle(color: p.color, fontSize: 9, fontWeight: FontWeight.w900)));
  Widget _buildTitle(Task t, {required int maxLines}) => Text(t.title, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: t.isDone ? Colors.grey[400] : const Color(0xFF1E293B), decoration: t.isDone ? TextDecoration.lineThrough : null));
  dynamic _getSortValue(Task t, TaskProvider prov) { switch (_sortField) { case TaskSortField.createdAt: return t.createdAt; case TaskSortField.updatedAt: return t.updatedAt; case TaskSortField.dueDate: return t.dueDate; case TaskSortField.completedAt: return t.completedAt ?? DateTime(1900); case TaskSortField.schedule: return prov.isIncludedInSchedule(t.id) ? (prov.effectiveScheduleRange(t)?.start ?? t.dueDate) : t.dueDate; } }
  String _getSortLabel(TaskSortField field) { switch (field) { case TaskSortField.createdAt: return '작성일'; case TaskSortField.updatedAt: return '수정일'; case TaskSortField.dueDate: return '기한'; case TaskSortField.schedule: return '일정'; case TaskSortField.completedAt: return '완료일'; } }
  String _getPriorityText(TaskPriority? p) => p == TaskPriority.high ? "상" : (p == TaskPriority.medium ? "중" : (p == TaskPriority.low ? "하" : "전체"));
  Color _getPriorityColor(TaskPriority p) => p == TaskPriority.high ? const Color(0xFFEF4444) : (p == TaskPriority.medium ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6));
  Widget _buildCustomFAB(BuildContext context, TaskProvider prov, TeamProvider teamProv) => Container(padding: const EdgeInsets.symmetric(horizontal: 20), width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10), icon: const Icon(Icons.add_rounded, size: 24), label: const Text("업무 추가", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.6))));
  String _getDisplayValue(String label, dynamic value, {required TaskProvider taskProv}) { if (value == null || value == 'all' || value == '전체' || value == DateFilter.all) return "전체"; if (value == 'none') return "없음"; if (value == 'me') return "나"; if (value is TaskPriority) return _getPriorityText(value); if (value is DateFilter) { if (value == DateFilter.today) return "오늘"; if (value == DateFilter.week) return "이번 주"; if (value == DateFilter.oneMonth) return "이번 달"; } if (label == "프로젝트") return taskProv.getProjectName(value.toString()); return value.toString(); }
  Map<String, List<Task>> _groupAndSortTasks(List<Task> tasks, TaskProvider prov) { final Map<String, List<Task>> grouped = groupBy(tasks, (t) { final date = t.createdAt; switch (_groupMode) { case '주': final startOfWeek = date.subtract(Duration(days: date.weekday - 1)); final endOfWeek = startOfWeek.add(const Duration(days: 6)); final weekNum = ((date.day + (startOfWeek.weekday - 1)) / 7).ceil(); return "${date.year}-${date.month.toString().padLeft(2, '0')}-W$weekNum|${DateFormat('MM/dd').format(startOfWeek)}~${DateFormat('MM/dd').format(endOfWeek)}"; case '월': return DateFormat('yyyy-MM').format(date); case '분기': return "${date.year}-Q${((date.month - 1) ~/ 3) + 1}"; case '년': return DateFormat('yyyy').format(date); default: return DateFormat('yyyy-MM-dd').format(date); } }); grouped.forEach((key, list) { list.sort((a, b) { final valA = _getSortValue(a, prov); final valB = _getSortValue(b, prov); return _isDescending ? valB.compareTo(valA) : valA.compareTo(valB); }); _groupExpandedStatus.putIfAbsent(key, () => true); }); return grouped; }
  Widget _buildTimelineGroup(String groupKey, List<Task> groupTasks, BuildContext context, TaskProvider taskProv, TeamProvider teamProv) { final bool isExpanded = _groupExpandedStatus[groupKey] ?? true; return Container(margin: const EdgeInsets.only(bottom: 12), child: Column(children: [InkWell(onTap: () => setState(() => _groupExpandedStatus[groupKey] = !isExpanded), borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(_formatGroupHeader(groupKey), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text("${groupTasks.length}", style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold))), const Spacer(), Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 22, color: Colors.grey)]))), if (isExpanded) _cardLayout == TaskCardLayout.classic ? Column(children: groupTasks.map((t) => _buildStrictFixedCard(context, taskProv, teamProv, t)).toList()) : Padding(padding: const EdgeInsets.only(top: 8), child: _buildGalleryView(context, taskProv, teamProv, groupTasks))])); }
  String _formatGroupHeader(String key) { if (_groupMode == '일') { try { return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(DateTime.parse(key)); } catch (_) { return key; } } if (_groupMode == '주') { final parts = key.split('|'); final dateParts = parts[0].split('-'); return "${dateParts[1]}월 ${dateParts[2].substring(1)}주 (${parts[1]})"; } if (_groupMode == '월') return "${key.split('-')[0]}년 ${key.split('-')[1]}월"; if (_groupMode == '분기') return "${key.split('-')[0]}년 ${key.split('-')[1]}"; if (_groupMode == '년') return "${key}년"; return key; }
  Widget _buildGalleryView(BuildContext context, TaskProvider prov, TeamProvider teamProv, List<Task> tasks) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 160), itemCount: tasks.length, itemBuilder: (context, i) => _buildGalleryCard(context, prov, teamProv, tasks[i]));
}
