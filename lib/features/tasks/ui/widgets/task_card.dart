import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/theme/premium_theme.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/premium_button.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskCard({super.key, required this.task, required this.taskProv});

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () =>
                          taskProv.updateTaskStatus(task, !task.isDone),
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: _statusCircle(task.isDone),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: _projectChip(projectName)),
                    const SizedBox(width: 6),
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
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: task.isDone
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _priorityBadge(task.priority),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '작성: ${_fmt(task.createdAt)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '기한: ${_fmt(task.dueDate)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '중요도: ${_priorityLabel(task.priority)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  if (task.isDone && task.completedAt != null)
                                    Text(
                                      '완료: ${_fmt(task.completedAt!)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  if (hasSchedule && scheduleRange != null)
                                    Text(
                                      '일정: ${_fmt(scheduleRange.start)}~${_fmt(scheduleRange.end)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 1,
                        height: 50,
                        color: const Color(0xFFD1D5DB),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '작성자 ${_lastWord(task.creatorName)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF374151),
                              ),
                            ),
                            Text(
                              '담당 ${_lastWord(task.assigneeName)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              task.assigneeEmoji.isEmpty
                                  ? '👤'
                                  : task.assigneeEmoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '# $projectName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
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
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          hasSchedule
              ? Icons.calendar_month_rounded
              : Icons.calendar_today_outlined,
          size: 17,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _statusCircle(bool isDone) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? AppColors.primary : const Color(0xFF9CA3AF),
          width: 1.9,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _priorityBadge(TaskPriority priority) {
    if (priority == TaskPriority.none) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
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
      width: 26,
      height: 26,
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
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => '상',
      TaskPriority.medium => '중',
      TaskPriority.low => '하',
      TaskPriority.none => '없음',
    };
  }

  String _fmt(DateTime date) => DateFormat('yy.MM.dd').format(date);

  String _lastWord(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    return trimmed.split(RegExp(r'\s+')).last;
  }
}
