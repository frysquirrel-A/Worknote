import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/theme/premium_theme.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/premium_button.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';

class TaskMasonryCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskMasonryCard({
    super.key,
    required this.task,
    required this.taskProv,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedule = taskProv.isIncludedInSchedule(task.id);
    final scheduleRange =
        taskProv.getScheduleRange(task.id) ??
        taskProv.effectiveScheduleRange(task);
    final projectName = _findProjectName(task.projectId, taskProv.projects);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusCircle(task.isDone),
                    const SizedBox(width: 7),
                    _priorityBadge(task.priority),
                    const Spacer(),
                    _scheduleButton(
                      hasSchedule: hasSchedule,
                      onTap: () => taskProv.setScheduleOptions(
                        taskId: task.id,
                        includeInSchedule: !hasSchedule,
                        range:
                            scheduleRange ??
                            DateTimeRange(
                              start: task.dueDate,
                              end: task.dueDate,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _projectChip(projectName),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: task.isDone
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metaRow(
                        '작성',
                        _fmt(task.createdAt),
                        const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 3),
                      _metaRow(
                        '기한',
                        _fmt(task.dueDate),
                        const Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 3),
                      if (task.isDone && task.completedAt != null)
                        _metaRow(
                          '완료',
                          _fmt(task.completedAt!),
                          AppColors.primary,
                        )
                      else
                        _metaRow('수정', _fmt(task.updatedAt), AppColors.primary),
                      if (hasSchedule && scheduleRange != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '일정 ${_fmt(scheduleRange.start)}~${_fmt(scheduleRange.end)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _lastWord(task.creatorName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: valueColor,
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

  Widget _projectChip(String projectName) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '#$projectName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _scheduleButton({
    required bool hasSchedule,
    required VoidCallback onTap,
  }) {
    return PremiumButton(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          hasSchedule
              ? Icons.calendar_month_rounded
              : Icons.calendar_today_outlined,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _statusCircle(bool isDone) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? AppColors.primary : const Color(0xFF9CA3AF),
          width: 1.8,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }

  Widget _priorityBadge(TaskPriority priority) {
    if (priority == TaskPriority.none) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.4),
        ),
      );
    }

    final color = switch (priority) {
      TaskPriority.high => const Color(0xFFEF4444),
      TaskPriority.medium => const Color(0xFFF59E0B),
      TaskPriority.low => AppColors.primary,
      TaskPriority.none => AppColors.primary,
    };
    final text = switch (priority) {
      TaskPriority.high => '상',
      TaskPriority.medium => '중',
      TaskPriority.low => '하',
      TaskPriority.none => '-',
    };

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _fmt(DateTime date) => DateFormat('yy.MM.dd').format(date);

  String _lastWord(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    return trimmed.split(RegExp(r'\s+')).last;
  }
}
