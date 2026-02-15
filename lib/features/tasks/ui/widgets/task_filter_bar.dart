import 'package:flutter/material.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';

/// Task filter bar used at the top of the Task tab.
///
/// Extracted from the previous monolithic `task_tab.dart` to improve
/// maintainability.
class TaskFilterBar extends StatelessWidget {
  final TaskProvider taskProv;
  final TeamProvider teamProv;
  final String myId;

  const TaskFilterBar({
    super.key,
    required this.taskProv,
    required this.teamProv,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _fixedMenuAnchor(
            label: '프로젝트',
            currentValue: taskProv.projectIdFilter,
            menuEntries: [
              _menuEntry('all', '전체 프로젝트', Colors.black87),
              _menuEntry('none', '프로젝트 없음', Colors.grey),
              ...taskProv.projects
                  .where((p) => p.teamId == teamProv.currentTeamId)
                  .map((p) => _menuEntry(p.id, p.name, p.color)),
            ],
            onSelected: (v) => taskProv.setProjectIdFilter(v as String?),
          ),

          _fixedMenuAnchor(
            label: '상태',
            currentValue: taskProv.statusFilter,
            menuEntries: [
              _menuEntry('전체', '전체 상태', Colors.black87),
              _menuEntry('진행 중', '진행 중', Colors.orange),
              _menuEntry('완료됨', '완료됨', Colors.green),
            ],
            onSelected: (v) => taskProv.setStatusFilter(v as String?),
          ),

          _fixedMenuAnchor(
            label: '중요도',
            currentValue: taskProv.priorityFilter,
            menuEntries: const [
              _MenuEntryWidget(value: null, label: '전체 중요도', color: Colors.black87),
              _MenuEntryWidget(value: TaskPriority.high, label: '상', color: Colors.redAccent),
              _MenuEntryWidget(value: TaskPriority.medium, label: '중', color: Colors.orangeAccent),
              _MenuEntryWidget(value: TaskPriority.low, label: '하', color: Colors.blueAccent),
              _MenuEntryWidget(value: TaskPriority.none, label: '-', color: Colors.grey),
            ],
            onSelected: (v) => taskProv.setPriorityFilter(v as TaskPriority?),
          ),

          _fixedMenuAnchor(
            label: '작성일',
            currentValue: taskProv.dateFilter,
            menuEntries: const [
              _MenuEntryWidget(value: DateFilter.all, label: '전체 기간', color: Colors.black87),
              _MenuEntryWidget(value: DateFilter.today, label: '오늘', color: Colors.blueAccent),
              _MenuEntryWidget(value: DateFilter.week, label: '최근 7일', color: Colors.blueAccent),
              _MenuEntryWidget(value: DateFilter.twoWeeks, label: '최근 14일', color: Colors.blueAccent),
              _MenuEntryWidget(value: DateFilter.oneMonth, label: '최근 30일', color: Colors.blueAccent),
            ],
            onSelected: (v) => taskProv.setDateFilter(v as DateFilter?),
          ),

          _fixedMenuAnchor(
            label: '담당자',
            currentValue: taskProv.assigneeFilter,
            menuEntries: [
              _menuEntry('all', '전체 담당자', Colors.black87),
              _menuEntry('me', '나', Colors.blueAccent),
              ...teamProv.currentTeam.memberIds
                  .where((id) => id != myId)
                  .map((id) => _menuEntry(id, id, Colors.black87)),
            ],
            onSelected: (v) => taskProv.setAssigneeFilter(v as String?),
          ),
        ],
      ),
    );
  }

  static _MenuEntryWidget _menuEntry(dynamic value, String label, Color color) {
    return _MenuEntryWidget(value: value, label: label, color: color);
  }

  Widget _fixedMenuAnchor({
    required String label,
    required dynamic currentValue,
    required List<_MenuEntryWidget> menuEntries,
    required ValueChanged<dynamic> onSelected,
  }) {
    final bool isDefault =
        (currentValue == null || currentValue == 'all' || currentValue == '전체' || currentValue == DateFilter.all);
    final Color displayColor = isDefault ? Colors.black87 : AppPalette.primary;

    return Expanded(
      flex: 1,
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 10),
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(8),
          minimumSize: WidgetStateProperty.all(const Size(160, 0)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          alignment: Alignment.bottomLeft,
        ),
        builder: (context, controller, child) {
          return GestureDetector(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: AppPalette.textMuted, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDisplayValue(label, currentValue),
                  style: TextStyle(fontSize: 11, color: displayColor, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        menuChildren: menuEntries
            .map(
              (item) => MenuItemButton(
                onPressed: () => onSelected(item.value),
                child: item,
              ),
            )
            .toList(),
      ),
    );
  }

  String _getDisplayValue(String label, dynamic value) {
    if (value == null || value == 'all' || value == '전체' || value == DateFilter.all) return '전체';
    if (value == 'none') return '없음';
    if (value == 'me') return '나';

    if (value is TaskPriority) return _priorityText(value);

    if (value is DateFilter) {
      switch (value) {
        case DateFilter.today:
          return '오늘';
        case DateFilter.week:
          return '7일';
        case DateFilter.twoWeeks:
          return '14일';
        case DateFilter.oneMonth:
          return '30일';
        case DateFilter.all:
          return '전체';
      }
    }

    if (label == '프로젝트') {
      return taskProv.getProjectName(value.toString());
    }

    return value.toString();
  }

  static String _priorityText(TaskPriority p) {
    return switch (p) {
      TaskPriority.high => '상',
      TaskPriority.medium => '중',
      TaskPriority.low => '하',
      TaskPriority.none => '-',
    };
  }
}

class _MenuEntryWidget extends StatelessWidget {
  final dynamic value;
  final String label;
  final Color color;

  const _MenuEntryWidget({
    required this.value,
    required this.label,
    required this.color,
  });

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
