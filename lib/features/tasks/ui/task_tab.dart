import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/add_task_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_schedule_sheet.dart';
import 'package:worknote/features/tasks/ui/widgets/task_card.dart';
import 'package:worknote/features/tasks/ui/widgets/task_filter_bar.dart';
import 'package:worknote/features/tasks/ui/widgets/task_masonry_card.dart';
import 'package:worknote/features/team/state/team_provider.dart';

/// v5 - Masterpiece Integration
enum TaskCardLayout { classic, gallery }
enum TaskGroupPeriod { day, week, month, quarter, year }
enum TaskSortField { createdAt, updatedAt, dueDate, scheduleStart, completedAt }

class TeamTaskTab extends StatefulWidget {
  const TeamTaskTab({super.key});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  // Controls
  TaskCardLayout _layout = TaskCardLayout.classic;
  TaskGroupPeriod _period = TaskGroupPeriod.day;
  TaskSortField _sortField = TaskSortField.dueDate;
  bool _isDescending = true;

  // Filter Local State
  String _selProjectId = 'all';
  String _selStatus = '진행중';
  TaskPriority? _selPriority;
  String _selAssignee = 'all';

  String _periodLabel(TaskGroupPeriod p) {
    switch (p) {
      case TaskGroupPeriod.day: return '일';
      case TaskGroupPeriod.week: return '주';
      case TaskGroupPeriod.month: return '월';
      case TaskGroupPeriod.quarter: return '분기';
      case TaskGroupPeriod.year: return '년';
    }
  }

  final Set<String> _collapsedGroupIds = <String>{};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleCollapse(String id) {
    setState(() {
      if (_collapsedGroupIds.contains(id)) {
        _collapsedGroupIds.remove(id);
      } else {
        _collapsedGroupIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.watch<AuthProvider>();
    final myId = authProv.currentUser?.id ?? 'me';

    final filteredTasks = taskProv.tasks.where((t) {
      if (t.teamId != teamProv.currentTeamId) return false;
      if (_selProjectId != 'all' && (_selProjectId == 'none' ? t.projectId != null : t.projectId != _selProjectId)) return false;
      
      // 상태 필터: 진행중(isDone false), 완료(isDone true)
      if (_selStatus == '진행중' && t.isDone) return false;
      if (_selStatus == '완료' && !t.isDone) return false;
      
      if (_selPriority != null && t.priority != _selPriority) return false;
      if (_selAssignee != 'all' && !t.assigneeIds.contains(_selAssignee == 'me' ? myId : _selAssignee)) return false;
      return true;
    }).toList();

    // Grouping
    final Map<String, List<Task>> grouped = <String, List<Task>>{};
    final Map<String, _GroupInfo> groupInfo = <String, _GroupInfo>{};

    for (final t in filteredTasks) {
      final base = taskProv.effectiveTimelineDate(t);
      final g = _groupFor(base, _period);
      grouped.putIfAbsent(g.id, () => []).add(t);
      groupInfo[g.id] = g;
    }

    final displayKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = groupInfo[a]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = groupInfo[b]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _isDescending ? db.compareTo(da) : da.compareTo(db);
      });

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Column(
        children: [
          // 상단 통합 컨트롤 바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TaskFilterBar(
              taskProv: taskProv,
              teamProv: teamProv,
              myId: myId,
              
              groupValue: _periodLabel(_period),
              groupItems: TaskGroupPeriod.values.map((p) => _periodLabel(p)).toList(),
              onGroupChanged: (v) {
                if (v == null) return;
                setState(() {
                  _period = TaskGroupPeriod.values.firstWhere((p) => _periodLabel(p) == v);
                  _collapsedGroupIds.clear();
                });
              },
              
              sortValue: _sortField,
              sortItems: TaskSortField.values,
              onSortChanged: (v) => setState(() => _sortField = v ?? TaskSortField.dueDate),
              
              newestFirst: _isDescending,
              onToggleNewestFirst: () => setState(() => _isDescending = !_isDescending),
              
              isGallery: _layout == TaskCardLayout.gallery,
              onToggleGallery: () => setState(() {
                _layout = _layout == TaskCardLayout.classic ? TaskCardLayout.gallery : TaskCardLayout.classic;
              }),
              
              selProjectId: _selProjectId,
              onProjectChanged: (v) => setState(() => _selProjectId = v ?? 'all'),
              selStatus: _selStatus,
              onStatusChanged: (v) => setState(() => _selStatus = v ?? 'all'),
              selPriority: _selPriority,
              onPriorityChanged: (v) => setState(() => _selPriority = v),
              selAssignee: _selAssignee,
              onAssigneeChanged: (v) => setState(() => _selAssignee = v ?? 'all'),
            ),
          ),

          Expanded(
            child: filteredTasks.isEmpty
                ? Center(child: Text('조건에 맞는 업무가 없습니다.', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)))
                : _GroupedTaskView(
                    groupIds: displayKeys,
                    groupInfo: groupInfo,
                    grouped: grouped,
                    sortField: _sortField,
                    newestFirst: _isDescending,
                    layout: _layout,
                    isCollapsed: (id) => _collapsedGroupIds.contains(id),
                    onToggleCollapse: _toggleCollapse,
                    taskProv: taskProv,
                    scrollController: _scrollController,
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _TaskAddButton(onPressed: () => showAddTaskSheet(context: context)),
    );
  }
}

class _GroupedTaskView extends StatelessWidget {
  final List<String> groupIds;
  final Map<String, _GroupInfo> groupInfo;
  final Map<String, List<Task>> grouped;
  final TaskSortField sortField;
  final bool newestFirst;
  final TaskCardLayout layout;
  final bool Function(String groupId) isCollapsed;
  final ValueChanged<String> onToggleCollapse;
  final TaskProvider taskProv;
  final ScrollController scrollController;

  const _GroupedTaskView({
    required this.groupIds,
    required this.groupInfo,
    required this.grouped,
    required this.sortField,
    required this.newestFirst,
    required this.layout,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.taskProv,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100), 
      itemCount: groupIds.length,
      itemBuilder: (context, index) {
        final id = groupIds[index];
        final info = groupInfo[id];
        final label = info?.label ?? id;
        final items = [...(grouped[id] ?? const <Task>[])];

        items.sort((a, b) {
          final da = _dateForSort(taskProv, a, sortField);
          final db = _dateForSort(taskProv, b, sortField);
          return newestFirst ? db.compareTo(da) : da.compareTo(db);
        });

        final collapsed = isCollapsed(id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(
              label: label,
              count: items.length,
              collapsed: collapsed,
              onTap: () => onToggleCollapse(id),
            ),
            if (!collapsed)
              ...[
                if (layout == TaskCardLayout.classic)
                  Column(
                    children: [
                      for (final t in items) ...[
                        TaskCard(task: t, taskProv: taskProv),
                        const SizedBox(height: 10), 
                      ],
                    ],
                  )
                else
                  _HorizontalGalleryRow(items: items, taskProv: taskProv),
              ],
            const SizedBox(height: 4), 
          ],
        );
      },
    );
  }
}

class _HorizontalGalleryRow extends StatelessWidget {
  final List<Task> items;
  final TaskProvider taskProv;
  const _HorizontalGalleryRow({required this.items, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW - 40 - 12) / 2;
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return SizedBox(width: cardW, child: TaskMasonryCard(task: items[i], taskProv: taskProv));
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool collapsed;
  final VoidCallback onTap;
  const _GroupHeader({required this.label, required this.count, required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6), 
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: AppPalette.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTextColor.primary))),
            Text('${count}건', style: const TextStyle(color: AppTextColor.secondary, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TaskAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _TaskAddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20), width: double.infinity, height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppPalette.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('업무 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
      ),
    );
  }
}

// --- Helpers ---
class _GroupInfo {
  final String id; final String label; final DateTime start; final DateTime end;
  const _GroupInfo({required this.id, required this.label, required this.start, required this.end});
}

_GroupInfo _groupFor(DateTime date, TaskGroupPeriod period) {
  final d = DateTime(date.year, date.month, date.day);
  switch (period) {
    case TaskGroupPeriod.day:
      final key = DateFormat('yyyy-MM-dd').format(d);
      return _GroupInfo(id: 'D:$key', label: key, start: d, end: d);
    case TaskGroupPeriod.week:
      final weekStart = d.subtract(Duration(days: d.weekday - DateTime.monday));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final key = DateFormat('yyyy-MM-dd').format(weekStart);
      return _GroupInfo(id: 'W:$key', label: '주간 ${DateFormat('MM-dd').format(weekStart)} ~ ${DateFormat('MM-dd').format(weekEnd)}', start: weekStart, end: weekEnd);
    case TaskGroupPeriod.month:
      final start = DateTime(d.year, d.month, 1);
      final end = DateTime(d.year, d.month + 1, 0);
      return _GroupInfo(id: 'M:${DateFormat('yyyy-MM').format(start)}', label: DateFormat('yyyy-MM').format(start), start: start, end: end);
    case TaskGroupPeriod.quarter:
      final q = ((d.month - 1) ~/ 3) + 1;
      final startMonth = (q - 1) * 3 + 1;
      final start = DateTime(d.year, startMonth, 1);
      final end = DateTime(d.year, startMonth + 3, 0);
      return _GroupInfo(id: 'Q:${d.year}-Q$q', label: '${d.year}-Q$q', start: start, end: end);
    case TaskGroupPeriod.year:
      final start = DateTime(d.year, 1, 1);
      final end = DateTime(d.year, 12, 31);
      return _GroupInfo(id: 'Y:${d.year}', label: '${d.year}년', start: start, end: end);
  }
}

DateTime _dateForSort(TaskProvider prov, Task t, TaskSortField field) {
  switch (field) {
    case TaskSortField.createdAt: return t.createdAt;
    case TaskSortField.updatedAt: return t.updatedAt;
    case TaskSortField.dueDate: return t.dueDate;
    case TaskSortField.scheduleStart: return (prov.effectiveScheduleRange(t)?.start) ?? t.dueDate;
    case TaskSortField.completedAt: return t.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

String _sortLabel(TaskSortField f) {
  switch (f) {
    case TaskSortField.dueDate: return '마감일';
    case TaskSortField.createdAt: return '생성일';
    case TaskSortField.updatedAt: return '수정일';
    case TaskSortField.scheduleStart: return '일정시작';
    case TaskSortField.completedAt: return '완료일';
  }
}
