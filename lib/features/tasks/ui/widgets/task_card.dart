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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusCircle(task.isDone),
                    const SizedBox(width: 10),
                    Expanded(child: _projectChip(projectName)),
                    const SizedBox(width: 10),
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
                const SizedBox(height: 10),
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: task.isDone
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _priorityBadge(task.priority),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _metaText(
                                      '작성: ${_fmt(task.createdAt)}',
                                      const Color(0xFF6B7280),
                                    ),
                                    _metaText(
                                      '기한: ${_fmt(task.dueDate)}',
                                      const Color(0xFFEF4444),
                                    ),
                                    if (task.isDone && task.completedAt != null)
                                      _metaText(
                                        '완료: ${_fmt(task.completedAt!)}',
                                        AppColors.primary,
                                      )
                                    else
                                      _metaText(
                                        '수정: ${_fmt(task.updatedAt)}',
                                        AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (hasSchedule && scheduleRange != null) ...[
                            const SizedBox(height: 4),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 78,
                      color: const Color(0xFFE5E7EB),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 86,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '작성자: ${_lastWord(task.creatorName)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '담당',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            task.assigneeEmoji.isEmpty
                                ? '📦'
                                : task.assigneeEmoji,
                            style: const TextStyle(fontSize: 17),
                          ),
                          Text(
                            _lastWord(task.assigneeName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
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

  Widget _metaText(String text, Color color) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          hasSchedule
              ? Icons.calendar_month_rounded
              : Icons.calendar_today_outlined,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _statusCircle(bool isDone) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? AppColors.primary : const Color(0xFF9CA3AF),
          width: 2,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }

  Widget _priorityBadge(TaskPriority priority) {
    if (priority == TaskPriority.none) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.6),
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
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
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
