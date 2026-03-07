import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/empty_state_placeholder.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/add_task_sheet.dart';
import 'package:worknote/features/tasks/ui/task_sort_field.dart';
import 'package:worknote/features/tasks/ui/widgets/task_card.dart';
import 'package:worknote/features/tasks/ui/widgets/task_filter_bar.dart';
import 'package:worknote/features/tasks/ui/widgets/task_masonry_card.dart';
import 'package:worknote/features/team/state/team_provider.dart';

enum TaskCardLayout { classic, gallery }

enum TaskGroupPeriod { day, week, month, quarter, year }

class TeamTaskTab extends StatefulWidget {
  const TeamTaskTab({super.key});

  @override
  State<TeamTaskTab> createState() => _TeamTaskTabState();
}

class _TeamTaskTabState extends State<TeamTaskTab> {
  String? _lastTeamId;
  TaskCardLayout _layout = TaskCardLayout.classic;
  TaskGroupPeriod _period = TaskGroupPeriod.day;
  TaskSortField _sortField = TaskSortField.dueDate;
  bool _isDescending = true;
  final bool _showGroupHeaders = true;
  String _selProjectId = 'all';

  final Set<String> _collapsedGroupIds = <String>{};
  final ScrollController _scrollController = ScrollController();

  String _periodLabel(TaskGroupPeriod period) {
    switch (period) {
      case TaskGroupPeriod.day:
        return '일';
      case TaskGroupPeriod.week:
        return '주';
      case TaskGroupPeriod.month:
        return '월';
      case TaskGroupPeriod.quarter:
        return '분기';
      case TaskGroupPeriod.year:
        return '연';
    }
  }

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
    final tabPalette = _TaskTabPalette.fromMode(
      teamProv.currentThemeMode.toLowerCase(),
    );

    final teamId = teamProv.currentTeamId;
    if (_lastTeamId != null && _lastTeamId != teamId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selProjectId = 'all';
        });
        context.read<TaskProvider>().resetTeamScopedFilters();
      });
    }
    _lastTeamId = teamId;

    final baseTasks = taskProv.tasksForTeam(teamId);
    final filteredTasks = baseTasks.where((task) {
      if (_selProjectId != 'all' &&
          (_selProjectId == 'none'
              ? task.projectId != null
              : task.projectId != _selProjectId)) {
        return false;
      }
      return true;
    }).toList();

    final grouped = <String, List<Task>>{};
    final groupInfo = <String, _GroupInfo>{};
    for (final task in filteredTasks) {
      final base = taskProv.effectiveTimelineDate(task);
      final group = _groupFor(base, _period);
      grouped.putIfAbsent(group.id, () => []).add(task);
      groupInfo[group.id] = group;
    }

    final displayKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da =
            groupInfo[a]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            groupInfo[b]?.start ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _isDescending ? db.compareTo(da) : da.compareTo(db);
      });

    return Scaffold(
      backgroundColor: tabPalette.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '업무 보기',
                      style: TextStyle(
                        color: tabPalette.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '프로젝트와 기간 기준으로 업무를 빠르게 훑어보세요.',
                      style: TextStyle(
                        color: tabPalette.subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tabPalette.summaryChipColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tabPalette.summaryChipBorder),
                  ),
                  child: Text(
                    '${filteredTasks.length}건',
                    style: TextStyle(
                      color: tabPalette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TaskFilterBar(
              taskProv: taskProv,
              groupValue: _periodLabel(_period),
              groupItems: TaskGroupPeriod.values.map(_periodLabel).toList(),
              onGroupChanged: (value) {
                if (value == null) return;
                setState(() {
                  _period = TaskGroupPeriod.values.firstWhere(
                    (period) => _periodLabel(period) == value,
                  );
                  _collapsedGroupIds.clear();
                });
              },
              sortValue: _sortField,
              sortItems: TaskSortField.values,
              onSortChanged: (value) =>
                  setState(() => _sortField = value ?? TaskSortField.dueDate),
              newestFirst: _isDescending,
              onToggleNewestFirst: () =>
                  setState(() => _isDescending = !_isDescending),
              isGallery: _layout == TaskCardLayout.gallery,
              onToggleGallery: () => setState(() {
                _layout = _layout == TaskCardLayout.classic
                    ? TaskCardLayout.gallery
                    : TaskCardLayout.classic;
              }),
              selProjectId: _selProjectId,
              onProjectChanged: (value) => setState(() => _selProjectId = value),
            ),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? EmptyStatePlaceholder(
                    icon: Icons.task_alt_rounded,
                    title: '조건에 맞는 업무가 없어요',
                    description: '필터를 조정하거나 새 업무를 추가해 보세요.',
                    ctaLabel: '+ 첫 업무 추가하기',
                    onTap: () => showAddTaskSheet(context: context),
                    compact: true,
                    dark: tabPalette.isDark,
                  )
                : _showGroupHeaders
                ? _GroupedTaskView(
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
                  )
                : _FlatTaskView(
                    tasks: filteredTasks,
                    sortField: _sortField,
                    newestFirst: _isDescending,
                    layout: _layout,
                    taskProv: taskProv,
                    scrollController: _scrollController,
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _TaskAddButton(
        onPressed: () => showAddTaskSheet(context: context),
      ),
    );
  }
}

class _FlatTaskView extends StatelessWidget {
  const _FlatTaskView({
    required this.tasks,
    required this.sortField,
    required this.newestFirst,
    required this.layout,
    required this.taskProv,
    required this.scrollController,
  });

  final List<Task> tasks;
  final TaskSortField sortField;
  final bool newestFirst;
  final TaskCardLayout layout;
  final TaskProvider taskProv;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final sortedTasks = [...tasks];
    sortedTasks.sort((a, b) {
      final da = _dateForSort(taskProv, a, sortField);
      final db = _dateForSort(taskProv, b, sortField);
      return newestFirst ? db.compareTo(da) : da.compareTo(db);
    });

    if (layout == TaskCardLayout.gallery) {
      return GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 132),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 252,
        ),
        itemCount: sortedTasks.length,
        itemBuilder: (ctx, index) => TaskMasonryCard(
          task: sortedTasks[index],
          taskProv: taskProv,
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 132),
      itemCount: sortedTasks.length,
      itemBuilder: (ctx, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TaskCard(task: sortedTasks[index], taskProv: taskProv),
      ),
    );
  }
}

class _GroupedTaskView extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 132),
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
            if (!collapsed) ...[
              if (layout == TaskCardLayout.classic)
                Column(
                  children: [
                    for (final task in items) ...[
                      TaskCard(task: task, taskProv: taskProv),
                      const SizedBox(height: 12),
                    ],
                  ],
                )
              else
                _HorizontalGalleryRow(items: items, taskProv: taskProv),
            ],
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

class _HorizontalGalleryRow extends StatelessWidget {
  const _HorizontalGalleryRow({
    required this.items,
    required this.taskProv,
  });

  final List<Task> items;
  final TaskProvider taskProv;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 40 - 12) / 2;
    final singleCardWidth = screenWidth - 40;

    return Container(
      height: 252,
      margin: const EdgeInsets.only(top: 4, bottom: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final width = items.length == 1 ? singleCardWidth : cardWidth;
          return SizedBox(
            width: width,
            child: TaskMasonryCard(task: items[index], taskProv: taskProv),
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.collapsed,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tabPalette = _TaskTabPalette.fromMode(
      context.watch<TeamProvider>().currentThemeMode.toLowerCase(),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: tabPalette.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: tabPalette.textColor,
                ),
              ),
            ),
            Text(
              '$count건',
              style: TextStyle(
                color: tabPalette.subTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
              color: tabPalette.subTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskAddButton extends StatelessWidget {
  const _TaskAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tabPalette = _TaskTabPalette.fromMode(
      context.watch<TeamProvider>().currentThemeMode.toLowerCase(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: tabPalette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: tabPalette.isDark ? 0 : 10,
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          '업무 추가',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _GroupInfo {
  const _GroupInfo({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
  });

  final String id;
  final String label;
  final DateTime start;
  final DateTime end;
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
      return _GroupInfo(
        id: 'W:$key',
        label:
            '주간 ${DateFormat('MM-dd').format(weekStart)} ~ ${DateFormat('MM-dd').format(weekEnd)}',
        start: weekStart,
        end: weekEnd,
      );
    case TaskGroupPeriod.month:
      final start = DateTime(d.year, d.month, 1);
      final end = DateTime(d.year, d.month + 1, 0);
      return _GroupInfo(
        id: 'M:${DateFormat('yyyy-MM').format(start)}',
        label: DateFormat('yyyy-MM').format(start),
        start: start,
        end: end,
      );
    case TaskGroupPeriod.quarter:
      final q = ((d.month - 1) ~/ 3) + 1;
      final startMonth = (q - 1) * 3 + 1;
      final start = DateTime(d.year, startMonth, 1);
      final end = DateTime(d.year, startMonth + 3, 0);
      return _GroupInfo(
        id: 'Q:${d.year}-Q$q',
        label: '${d.year}-Q$q',
        start: start,
        end: end,
      );
    case TaskGroupPeriod.year:
      final start = DateTime(d.year, 1, 1);
      final end = DateTime(d.year, 12, 31);
      return _GroupInfo(
        id: 'Y:${d.year}',
        label: '${d.year}년',
        start: start,
        end: end,
      );
  }
}

DateTime _dateForSort(TaskProvider prov, Task task, TaskSortField field) {
  switch (field) {
    case TaskSortField.createdAt:
      return task.createdAt;
    case TaskSortField.updatedAt:
      return task.updatedAt;
    case TaskSortField.dueDate:
      return task.dueDate;
    case TaskSortField.scheduleStart:
      return (prov.effectiveScheduleRange(task)?.start) ?? task.dueDate;
    case TaskSortField.completedAt:
      return task.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _TaskTabPalette {
  const _TaskTabPalette({
    required this.isDark,
    required this.backgroundColor,
    required this.textColor,
    required this.subTextColor,
    required this.accent,
    required this.summaryChipColor,
    required this.summaryChipBorder,
  });

  final bool isDark;
  final Color backgroundColor;
  final Color textColor;
  final Color subTextColor;
  final Color accent;
  final Color summaryChipColor;
  final Color summaryChipBorder;

  factory _TaskTabPalette.fromMode(String mode) {
    switch (mode) {
      case 'dark':
        return const _TaskTabPalette(
          isDark: true,
          backgroundColor: AppColors.darkBg,
          textColor: AppColors.darkText,
          subTextColor: AppColors.darkHint,
          accent: AppColors.premiumBlue,
          summaryChipColor: AppColors.darkSurface2,
          summaryChipBorder: AppColors.darkBorder,
        );
      case 'blue':
        return const _TaskTabPalette(
          isDark: false,
          backgroundColor: Color(0xFFF0F7FF),
          textColor: AppColors.text,
          subTextColor: Color(0xFF527199),
          accent: AppColors.premiumBlueStrong,
          summaryChipColor: Color(0xFFDDEAFF),
          summaryChipBorder: Color(0xFFB9D2FF),
        );
      default:
        return const _TaskTabPalette(
          isDark: false,
          backgroundColor: AppColors.bg,
          textColor: AppColors.text,
          subTextColor: AppColors.text2,
          accent: AppColors.primary,
          summaryChipColor: Color(0xFFE8F0FF),
          summaryChipBorder: Color(0xFFD8E4FF),
        );
    }
  }
}
