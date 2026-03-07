import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/theme/premium_theme.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/premium_button.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/team/state/team_provider.dart';

class TaskMasonryCard extends StatelessWidget {
  const TaskMasonryCard({
    super.key,
    required this.task,
    required this.taskProv,
  });

  final Task task;
  final TaskProvider taskProv;

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<TeamProvider, String>(
      (prov) => prov.currentThemeMode.toLowerCase(),
    );
    final palette = _CardPalette.fromThemeMode(themeMode);
    final creatorName = _displayName(task.creatorName);
    final assigneeName = _displayName(task.assigneeName);
    final showOnCalendar = taskProv.isIncludedInSchedule(task.id);
    final configuredRange = taskProv.getScheduleRange(task.id);
    final effectiveRange =
        configuredRange ?? taskProv.effectiveScheduleRange(task);
    final projectName = _findProjectName(task.projectId, taskProv.projects);

    return Container(
      decoration: BoxDecoration(
        color: palette.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderColor),
        boxShadow: premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _projectChip(
                        projectName: projectName,
                        chipColor: palette.chipColor,
                        accent: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 5),
                    _priorityBadge(
                      priority: task.priority,
                      palette: palette,
                      onTap: _cyclePriority,
                    ),
                    const SizedBox(width: 5),
                    _scheduleButton(
                      showOnCalendar: showOnCalendar,
                      accent: palette.accent,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await taskProv.setScheduleOptions(
                          taskId: task.id,
                          includeInSchedule: !showOnCalendar,
                          range: effectiveRange ??
                              DateTimeRange(
                                start: task.dueDate,
                                end: task.dueDate,
                              ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await taskProv.updateTaskStatus(task, !task.isDone);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: _statusCircle(
                          isDone: task.isDone,
                          accent: palette.accent,
                          mutedColor: palette.mutedColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: task.isDone
                              ? palette.mutedColor
                              : palette.titleColor,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          height: 1.14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                  decoration: BoxDecoration(
                    color: palette.metaColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: palette.borderColor),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _metaText(
                                text: _metaLineOne(),
                                palette: palette,
                              ),
                              const SizedBox(height: 3),
                              _metaText(
                                text: _metaLineTwo(
                                  showOnCalendar: showOnCalendar,
                                  configuredRange: configuredRange,
                                ),
                                palette: palette,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          color: palette.dividerColor,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 54,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _roleBlock(
                                label: '작성자',
                                name: creatorName,
                                palette: palette,
                              ),
                              const SizedBox(height: 7),
                              _roleBlock(
                                label: '담당',
                                name: assigneeName,
                                palette: palette,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cyclePriority() async {
    HapticFeedback.selectionClick();
    await taskProv.cycleTaskPriority(task);
  }

  Widget _metaText({
    required String text,
    required _CardPalette palette,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: palette.mutedColor,
        height: 1.1,
      ),
    );
  }

  Widget _roleBlock({
    required String label,
    required String name,
    required _CardPalette palette,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: palette.mutedColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: palette.titleColor,
          ),
        ),
      ],
    );
  }

  String _findProjectName(String? projectId, List<Project> projects) {
    if (projectId == null) return '일반 업무';
    for (final project in projects) {
      if (project.id == projectId) return project.name;
    }
    return '일반 업무';
  }

  String _metaLineOne() {
    return '작성 ${_fmt(task.createdAt)} • 기한 ${_fmt(task.dueDate)} • 수정 ${_fmt(task.updatedAt)}';
  }

  String _metaLineTwo({
    required bool showOnCalendar,
    required DateTimeRange? configuredRange,
  }) {
    final parts = <String>[];
    if (task.completedAt != null) {
      parts.add('완료 ${_fmt(task.completedAt!)}');
    }
    if (configuredRange != null) {
      final sameDay = _fmt(configuredRange.start) == _fmt(configuredRange.end);
      final rangeText = sameDay
          ? _fmt(configuredRange.start)
          : '${_fmt(configuredRange.start)}~${_fmt(configuredRange.end)}';
      parts.add(showOnCalendar ? '캘린더 표시 $rangeText' : '캘린더 숨김 $rangeText');
    } else {
      parts.add('일정 미설정');
    }
    return parts.join(' • ');
  }

  Widget _projectChip({
    required String projectName,
    required Color chipColor,
    required Color accent,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '# $projectName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _scheduleButton({
    required bool showOnCalendar,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return PremiumButton(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: showOnCalendar ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          showOnCalendar
              ? Icons.calendar_month_rounded
              : Icons.calendar_today_outlined,
          size: 13,
          color: accent,
        ),
      ),
    );
  }

  Widget _statusCircle({
    required bool isDone,
    required Color accent,
    required Color mutedColor,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDone ? accent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? accent : mutedColor,
          width: 1.6,
        ),
      ),
      child: isDone
          ? Icon(
              Icons.check_rounded,
              size: size * 0.58,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _priorityBadge({
    required TaskPriority priority,
    required _CardPalette palette,
    required Future<void> Function() onTap,
  }) {
    final color = switch (priority) {
      TaskPriority.high => AppColors.destructive,
      TaskPriority.medium => AppColors.warning,
      TaskPriority.low => palette.accent,
      TaskPriority.none => palette.mutedColor,
    };
    final label = switch (priority) {
      TaskPriority.high => '상',
      TaskPriority.medium => '중',
      TaskPriority.low => '하',
      TaskPriority.none => '-',
    };

    return PremiumButton(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: priority == TaskPriority.none ? 0.08 : 0.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: priority == TaskPriority.none ? palette.borderColor : color,
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime date) => DateFormat('yy.MM.dd').format(date);

  String _displayName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    return trimmed.split(RegExp(r'\s+')).last;
  }
}

class _CardPalette {
  const _CardPalette({
    required this.cardColor,
    required this.metaColor,
    required this.chipColor,
    required this.borderColor,
    required this.dividerColor,
    required this.titleColor,
    required this.mutedColor,
    required this.accent,
  });

  final Color cardColor;
  final Color metaColor;
  final Color chipColor;
  final Color borderColor;
  final Color dividerColor;
  final Color titleColor;
  final Color mutedColor;
  final Color accent;

  factory _CardPalette.fromThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return const _CardPalette(
          cardColor: AppColors.darkSurface,
          metaColor: AppColors.darkSurface2,
          chipColor: AppColors.darkSurface2,
          borderColor: AppColors.darkBorder,
          dividerColor: AppColors.darkBorder,
          titleColor: AppColors.darkText,
          mutedColor: Color(0xFF9FB2D1),
          accent: AppColors.premiumBlue,
        );
      case 'blue':
        return const _CardPalette(
          cardColor: Color(0xFFEAF3FF),
          metaColor: Color(0xFFDCEAFF),
          chipColor: Color(0xFFD5E5FF),
          borderColor: Color(0xFFB9D2FF),
          dividerColor: Color(0xFFAEC7F6),
          titleColor: AppColors.text,
          mutedColor: Color(0xFF527199),
          accent: AppColors.premiumBlueStrong,
        );
      default:
        return const _CardPalette(
          cardColor: Colors.white,
          metaColor: Color(0xFFF3F4F6),
          chipColor: Color(0xFFE6EFFF),
          borderColor: Color(0xFFE5E7EB),
          dividerColor: Color(0xFFD1D5DB),
          titleColor: AppColors.text,
          mutedColor: Color(0xFF6B7280),
          accent: AppColors.primary,
        );
    }
  }
}
