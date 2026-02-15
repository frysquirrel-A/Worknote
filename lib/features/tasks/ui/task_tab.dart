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

/// v5
/// - 기본: "원래 카드"(TaskCard) 리스트
/// - 갤러리 카드(TaskMasonryCard)는 아이콘으로 선택
/// - 날짜 그룹 헤더 탭 → 해당 그룹 접기/펼치기
/// - 카드 바로 위: 그룹(일/주/월/분기/년) + 정렬(작성/수정/기한/일정/완료)
/// - "스케줄" 용어를 "일정"으로 통일 + 일정은 기간(DateTimeRange)

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
  TaskCardLayout _layout = TaskCardLayout.classic; // "원래대로" 기본
  TaskGroupPeriod _period = TaskGroupPeriod.day;
  TaskSortField _sortField = TaskSortField.dueDate;
  bool _newestFirst = true;

  // Date-group UX
  bool _showGroupToc = true;
  bool _showGroupHeaders = true;
  String? _pinnedGroupId;
  final Set<String> _collapsedGroupIds = <String>{};

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _pinGroup(String id) {
    setState(() => _pinnedGroupId = id);
    _scrollToTop();
  }

  void _clearPin() {
    if (_pinnedGroupId == null) return;
    setState(() => _pinnedGroupId = null);
    _scrollToTop();
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

    // Group by selected period (based on "타임라인 기준일": 일정 start 우선, 없으면 기한)
    final Map<String, List<Task>> grouped = <String, List<Task>>{};
    final Map<String, _GroupInfo> groupInfo = <String, _GroupInfo>{};

    for (final t in tasks) {
      final base = taskProv.effectiveTimelineDate(t);
      final g = _groupFor(base, _period);
      grouped.putIfAbsent(g.id, () => []).add(t);
      groupInfo[g.id] = g;
    }

    // Order group keys
    final baseKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = groupInfo[a]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = groupInfo[b]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _newestFirst ? db.compareTo(da) : da.compareTo(db);
      });

    final effectivePinned = baseKeys.contains(_pinnedGroupId) ? _pinnedGroupId : null;
    final displayKeys = [...baseKeys];
    if (effectivePinned != null) {
      displayKeys.remove(effectivePinned);
      displayKeys.insert(0, effectivePinned);
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Column(
        children: [
          TaskFilterBar(taskProv: taskProv, teamProv: teamProv, myId: myId),

          // Controls (group/sort/layout)
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _TaskViewControls(
                layout: _layout,
                period: _period,
                sortField: _sortField,
                newestFirst: _newestFirst,
                showToc: _showGroupToc,
                showHeaders: _showGroupHeaders,
                pinnedLabel: effectivePinned == null ? null : (groupInfo[effectivePinned]?.label ?? ''),
                onToggleLayout: () => setState(() {
                  _layout = _layout == TaskCardLayout.classic ? TaskCardLayout.gallery : TaskCardLayout.classic;
                }),
                onSelectPeriod: (p) => setState(() {
                  _period = p;
                  _pinnedGroupId = null;
                  _collapsedGroupIds.clear();
                }),
                onSelectSortField: (f) => setState(() => _sortField = f),
                onToggleSortOrder: () => setState(() => _newestFirst = !_newestFirst),
                onToggleToc: () => setState(() => _showGroupToc = !_showGroupToc),
                onToggleHeaders: () => setState(() => _showGroupHeaders = !_showGroupHeaders),
              ),
            ),

          if (tasks.isNotEmpty && _showGroupToc)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _GroupTocRow(
                groupIds: baseKeys,
                groupInfo: groupInfo,
                pinnedGroupId: effectivePinned,
                onSelect: _pinGroup,
                onClear: _clearPin,
              ),
            ),

          const SizedBox(height: 6),

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
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
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
                      for (final t in items) TaskCard(task: t, taskProv: taskProv),
                    ],
                  )
                else
                  _HorizontalGalleryRow(items: items, taskProv: taskProv),
              ],

            const SizedBox(height: 8),
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
    // page padding(20*2) + gap(12)
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppPalette.textDark),
              ),
            ),
            Text(
              '${count}건',
              style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Icon(
              collapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              color: AppPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskViewControls extends StatelessWidget {
  final TaskCardLayout layout;
  final TaskGroupPeriod period;
  final TaskSortField sortField;
  final bool newestFirst;
  final bool showToc;
  final bool showHeaders;
  final String? pinnedLabel;

  final VoidCallback onToggleLayout;
  final ValueChanged<TaskGroupPeriod> onSelectPeriod;
  final ValueChanged<TaskSortField> onSelectSortField;
  final VoidCallback onToggleSortOrder;
  final VoidCallback onToggleToc;
  final VoidCallback onToggleHeaders;

  const _TaskViewControls({
    required this.layout,
    required this.period,
    required this.sortField,
    required this.newestFirst,
    required this.showToc,
    required this.showHeaders,
    required this.pinnedLabel,
    required this.onToggleLayout,
    required this.onSelectPeriod,
    required this.onSelectSortField,
    required this.onToggleSortOrder,
    required this.onToggleToc,
    required this.onToggleHeaders,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '업무 보기',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppPalette.textDark),
            ),
            const SizedBox(width: 8),
            if (pinnedLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppPalette.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 14, color: AppPalette.primary),
                    const SizedBox(width: 6),
                    Text(
                      pinnedLabel!,
                      style: const TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Tooltip(
              message: layout == TaskCardLayout.classic ? '카드 디자인: 기본(리스트)' : '카드 디자인: 갤러리',
              child: IconButton(
                iconSize: 20,
                onPressed: onToggleLayout,
                icon: Icon(layout == TaskCardLayout.classic ? Icons.view_agenda_rounded : Icons.grid_view_rounded),
                color: AppPalette.primary,
              ),
            ),
            Tooltip(
              message: showToc ? '날짜 목차 숨기기' : '날짜 목차 보이기',
              child: IconButton(
                iconSize: 20,
                onPressed: onToggleToc,
                icon: Icon(showToc ? Icons.toc_rounded : Icons.toc_outlined),
                color: AppPalette.primary,
              ),
            ),
            Tooltip(
              message: showHeaders ? '그룹 헤더 숨기기' : '그룹 헤더 보이기',
              child: IconButton(
                iconSize: 20,
                onPressed: onToggleHeaders,
                icon: Icon(showHeaders ? Icons.label_rounded : Icons.label_outline_rounded),
                color: AppPalette.primary,
              ),
            ),
            Tooltip(
              message: newestFirst ? '정렬: 최신순(↓)' : '정렬: 오래된순(↑)',
              child: IconButton(
                iconSize: 20,
                onPressed: onToggleSortOrder,
                icon: Icon(newestFirst ? Icons.south_rounded : Icons.north_rounded),
                color: AppPalette.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _chipMenu<TaskGroupPeriod>(
            label: _periodLabel(period),
                icon: Icons.view_day_rounded,
                value: period,
                items: TaskGroupPeriod.values,
                itemLabel: _periodLabel,
                onSelected: onSelectPeriod,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _chipMenu<TaskSortField>(
            label: _sortLabel(sortField),
                icon: Icons.sort_rounded,
                value: sortField,
                items: TaskSortField.values,
                itemLabel: _sortLabel,
                onSelected: onSelectSortField,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupTocRow extends StatelessWidget {
  final List<String> groupIds;
  final Map<String, _GroupInfo> groupInfo;
  final String? pinnedGroupId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  const _GroupTocRow({
    required this.groupIds,
    required this.groupInfo,
    required this.pinnedGroupId,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tocChip(
            label: '전체',
            selected: pinnedGroupId == null,
            onTap: onClear,
            leading: Icons.all_inclusive_rounded,
          ),
          const SizedBox(width: 8),
          for (final id in groupIds) ...[
            _tocChip(
              label: groupInfo[id]?.tocLabel ?? id,
              selected: pinnedGroupId == id,
              onTap: () => onSelect(id),
              leading: pinnedGroupId == id ? Icons.push_pin_rounded : Icons.calendar_today_rounded,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _tocChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData leading,
  }) {
    final bg = selected ? AppPalette.primary : Colors.white;
    final fg = selected ? Colors.white : AppPalette.textDark;
    final borderColor = selected ? AppPalette.primary : AppPalette.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(leading, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
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
  final String tocLabel;
  final DateTime start;
  final DateTime end;

  const _GroupInfo({
    required this.id,
    required this.label,
    required this.tocLabel,
    required this.start,
    required this.end,
  });
}

_GroupInfo _groupFor(DateTime date, TaskGroupPeriod period) {
  final d = DateTime(date.year, date.month, date.day);
  switch (period) {
    case TaskGroupPeriod.day:
      final key = DateFormat('yyyy-MM-dd').format(d);
      return _GroupInfo(
        id: 'D:$key',
        label: key,
        tocLabel: DateFormat('MM/dd').format(d),
        start: d,
        end: d,
      );
    case TaskGroupPeriod.week:
      final weekStart = d.subtract(Duration(days: d.weekday - DateTime.monday));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final key = DateFormat('yyyy-MM-dd').format(weekStart);
      final label = '${DateFormat('yyyy-MM-dd').format(weekStart)} ~ ${DateFormat('yyyy-MM-dd').format(weekEnd)}';
      final toc = '${DateFormat('MM/dd').format(weekStart)}주';
      return _GroupInfo(id: 'W:$key', label: '주간 $label', tocLabel: toc, start: weekStart, end: weekEnd);
    case TaskGroupPeriod.month:
      final start = DateTime(d.year, d.month, 1);
      final end = DateTime(d.year, d.month + 1, 0);
      final key = DateFormat('yyyy-MM').format(start);
      return _GroupInfo(id: 'M:$key', label: '$key', tocLabel: '${start.month}월', start: start, end: end);
    case TaskGroupPeriod.quarter:
      final q = ((d.month - 1) ~/ 3) + 1;
      final startMonth = (q - 1) * 3 + 1;
      final start = DateTime(d.year, startMonth, 1);
      final end = DateTime(d.year, startMonth + 3, 0);
      final key = '${d.year}-Q$q';
      return _GroupInfo(id: 'Q:$key', label: '$key', tocLabel: 'Q$q', start: start, end: end);
    case TaskGroupPeriod.year:
      final start = DateTime(d.year, 1, 1);
      final end = DateTime(d.year, 12, 31);
      final key = '${d.year}';
      return _GroupInfo(id: 'Y:$key', label: key, tocLabel: key, start: start, end: end);
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
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppPalette.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: AppPalette.textMuted),
        ],
      ),
    ),
  );
}
