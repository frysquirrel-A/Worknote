import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/add_task_sheet.dart';
import 'package:worknote/features/tasks/ui/widgets/task_card.dart';
import 'package:worknote/features/tasks/ui/widgets/task_filter_bar.dart';
import 'package:worknote/features/tasks/ui/widgets/task_masonry_card.dart';
import 'package:worknote/features/team/state/team_provider.dart';

/// v5 - Simplified & Optimized Spacing
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
  bool _newestFirst = true;

  // Date-group UX
  bool _showGroupHeaders = true;
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

    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId, myId: myId);

    // Group by selected period
    final Map<String, List<Task>> grouped = <String, List<Task>>{};
    final Map<String, _GroupInfo> groupInfo = <String, _GroupInfo>{};

    for (final t in tasks) {
      final base = taskProv.effectiveTimelineDate(t);
      final g = _groupFor(base, _period);
      grouped.putIfAbsent(g.id, () => []).add(t);
      groupInfo[g.id] = g;
    }

    // Order group keys
    final displayKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = groupInfo[a]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = groupInfo[b]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _newestFirst ? db.compareTo(da) : da.compareTo(db);
      });

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Column(
        children: [
          TaskFilterBar(taskProv: taskProv, teamProv: teamProv, myId: myId),

          // Integrated Controls Card
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _chipMenu<TaskGroupPeriod>(
                        label: _periodLabel(_period),
                        icon: Icons.view_day_rounded,
                        value: _period,
                        items: TaskGroupPeriod.values,
                        itemLabel: _periodLabel,
                        onSelected: (p) => setState(() {
                          _period = p;
                          _collapsedGroupIds.clear();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: _chipMenu<TaskSortField>(
                        label: _sortLabel(_sortField),
                        icon: Icons.sort_rounded,
                        value: _sortField,
                        items: TaskSortField.values,
                        itemLabel: _sortLabel,
                        onSelected: (f) => setState(() => _sortField = f),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _newestFirst = !_newestFirst),
                      icon: Icon(
                        _newestFirst ? Icons.south_rounded : Icons.north_rounded,
                        color: AppPalette.primary,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _layout = _layout == TaskCardLayout.classic ? TaskCardLayout.gallery : TaskCardLayout.classic;
                      }),
                      icon: Icon(
                        _layout == TaskCardLayout.classic ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                        color: AppPalette.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 4), 

          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      '조건에 맞는 업무가 없습니다.',
                      style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
                    ),
                  )
                : _GroupedTaskView(
                    groupIds: displayKeys,
                    groupInfo: groupInfo,
                    grouped: grouped,
                    sortField: _sortField,
                    newestFirst: _newestFirst,
                    layout: _layout,
                    showGroupHeaders: _showGroupHeaders,
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
  final bool showGroupHeaders;
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
    required this.showGroupHeaders,
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
            if (showGroupHeaders)
              _GroupHeader(
                label: label,
                count: items.length,
                collapsed: collapsed,
                onTap: () => onToggleCollapse(id),
              )
            else
              const SizedBox(height: 4),

            if (!collapsed)
              ...[
                if (layout == TaskCardLayout.classic)
                  Column(
                    children: [
                      for (final t in items) ...[
                        TaskCard(task: t, taskProv: taskProv),
                        const SizedBox(height: 10), // 카드 간 간격 10 고정
                      ],
                    ],
                  )
                else
                  _HorizontalGalleryRow(items: items, taskProv: taskProv),
              ],

            const SizedBox(height: 4), // 그룹 사이 빈 공간 축소
          ],
        );
      },
    );
  }
}

class _HorizontalGalleryRow extends StatelessWidget {
  final List<Task> items;
  final TaskProvider taskProv;

  const _HorizontalGalleryRow({
    required this.items,
    required this.taskProv,
  });

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
          return SizedBox(
            width: cardW,
            child: TaskMasonryCard(task: items[i], taskProv: taskProv),
          );
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

  const _GroupHeader({
    required this.label,
    required this.count,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6), // 헤더 위 10, 아래 6 고정
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: AppPalette.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTextColor.primary),
              ),
            ),
            Text(
              '${count}건',
              style: const TextStyle(color: AppTextColor.secondary, fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Icon(
              collapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              color: AppTextColor.hint,
              size: 20,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          '업무 추가',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

// --- Helpers ---

class _GroupInfo {
  final String id;
  final String label;
  final DateTime start;
  final DateTime end;

  const _GroupInfo({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
  });
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
      final label = '${DateFormat('yyyy-MM-dd').format(weekStart)} ~ ${DateFormat('yyyy-MM-dd').format(weekEnd)}';
      return _GroupInfo(id: 'W:$key', label: '주간 $label', start: weekStart, end: weekEnd);
    case TaskGroupPeriod.month:
      final start = DateTime(d.year, d.month, 1);
      final end = DateTime(d.year, d.month + 1, 0);
      final key = DateFormat('yyyy-MM').format(start);
      return _GroupInfo(id: 'M:$key', label: '$key', start: start, end: end);
    case TaskGroupPeriod.quarter:
      final q = ((d.month - 1) ~/ 3) + 1;
      final startMonth = (q - 1) * 3 + 1;
      final start = DateTime(d.year, startMonth, 1);
      final end = DateTime(d.year, startMonth + 3, 0);
      final key = '${d.year}-Q$q';
      return _GroupInfo(id: 'Q:$key', label: '$key', start: start, end: end);
    case TaskGroupPeriod.year:
      final start = DateTime(d.year, 1, 1);
      final end = DateTime(d.year, 12, 31);
      final key = '${d.year}';
      return _GroupInfo(id: 'Y:$key', label: key, start: start, end: end);
  }
}

DateTime _dateForSort(TaskProvider prov, Task t, TaskSortField field) {
  switch (field) {
    case TaskSortField.createdAt:
      return t.createdAt;
    case TaskSortField.updatedAt:
      return t.updatedAt;
    case TaskSortField.dueDate:
      return t.dueDate;
    case TaskSortField.scheduleStart:
      return (prov.effectiveScheduleRange(t)?.start) ?? t.dueDate;
    case TaskSortField.completedAt:
      return t.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

String _periodLabel(TaskGroupPeriod p) {
  switch (p) {
    case TaskGroupPeriod.day:
      return '일';
    case TaskGroupPeriod.week:
      return '주';
    case TaskGroupPeriod.month:
      return '월';
    case TaskGroupPeriod.quarter:
      return '분기';
    case TaskGroupPeriod.year:
      return '년';
  }
}

String _sortLabel(TaskSortField f) {
  switch (f) {
    case TaskSortField.createdAt:
      return '작성일';
    case TaskSortField.updatedAt:
      return '수정일';
    case TaskSortField.dueDate:
      return '기한';
    case TaskSortField.scheduleStart:
      return '일정';
    case TaskSortField.completedAt:
      return '완료일';
  }
}

Widget _chipMenu<T>({
  required String label,
  required IconData icon,
  required T value,
  required List<T> items,
  required String Function(T) itemLabel,
  required ValueChanged<T> onSelected,
}) {
  return PopupMenuButton<T>(
    onSelected: onSelected,
    itemBuilder: (context) {
      return items
          .map(
            (e) => PopupMenuItem<T>(
              value: e,
              child: Row(
                children: [
                  if (e == value) const Icon(Icons.check_rounded, size: 18) else const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(itemLabel(e), style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          )
          .toList();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTextColor.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: AppTextColor.hint),
        ],
      ),
    ),
  );
}
