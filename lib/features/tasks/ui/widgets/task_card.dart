import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_schedule_sheet.dart';

/// Single task card used in Task list.
class TaskCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskCard({
    super.key,
    required this.task,
    required this.taskProv,
  });

  @override
  Widget build(BuildContext context) {
    final project = taskProv.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project(
        id: '',
        teamId: '',
        name: '일반 업무',
        colorValue: 0xFF94A3B8,
      ),
    );

    final includedInSchedule = taskProv.isIncludedInSchedule(task.id);
    final scheduleRange = taskProv.effectiveScheduleRange(task);

    return GestureDetector(
      onTap: () => showTaskDetailSheet(context: context, task: task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone 1: left fixed (checkbox)
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isDone ? AppPalette.primary : Colors.white,
                          border: Border.all(
                            color: task.isDone ? AppPalette.primary : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Zone 2: middle flexible
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: project.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${project.name}',
                        style: TextStyle(color: project.color, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: task.isDone ? Colors.grey[400] : const Color(0xFF1E293B),
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Divider(color: AppPalette.border, height: 12, thickness: 1),

                    // Meta lines: keep everything on one grid (badge + labels)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: _priorityBadge(task.priority),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _compactDate('작성', task.createdAt, AppPalette.textMuted),
                                  const SizedBox(width: 14),
                                  _compactDate('수정', task.updatedAt, AppPalette.textMuted),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _compactDate('기한', task.dueDate, task.isDone ? AppPalette.textHint : AppPalette.danger),
                                  const SizedBox(width: 14),
                                  if (task.isDone && task.completedAt != null)
                                    _compactDate('완료', task.completedAt!, AppPalette.success)
                                  else if (includedInSchedule && scheduleRange != null)
                                    _compactRange('일정', scheduleRange, AppPalette.primary)
                                  else
                                    _compactText('상태', task.isDone ? '완료' : '진행', task.isDone ? AppPalette.success : AppPalette.textMuted),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Zone 3: right fixed (creator + assignee)
              const VerticalDivider(width: 1, thickness: 1, color: AppPalette.border),
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '일정 설정',
                      onPressed: () => showTaskScheduleSheet(context: context, task: task),
                      icon: Icon(
                        includedInSchedule ? Icons.calendar_month_rounded : Icons.calendar_month_outlined,
                        color: includedInSchedule ? AppPalette.primary : AppPalette.textMuted,
                        size: 22,
                      ),
                    ),
                    const Text(
                      '작성자',
                      style: TextStyle(fontSize: 8, color: AppPalette.textMuted, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      task.creatorName,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppPalette.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '담당',
                      style: TextStyle(fontSize: 8, color: AppPalette.textMuted, fontWeight: FontWeight.w800),
                    ),
                    Text(task.assigneeEmoji, style: const TextStyle(fontSize: 22)),
                    Text(
                      task.assigneeName,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppPalette.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _priorityBadge(TaskPriority p) {
  final c = _priorityColor(p);
  return Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withValues(alpha: 0.10),
      border: Border.all(color: c, width: 1.6),
    ),
    child: Text(
      _priorityText(p),
      style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12),
    ),
  );
}

Widget _compactDate(String label, DateTime date, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label: ',
        style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
      ),
      Text(
        DateFormat('yy.MM.dd').format(date),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

Widget _compactRange(String label, DateTimeRange? range, Color color) {
  if (range == null) return _compactText(label, '-', color);
  final s = DateFormat('yy.MM.dd').format(range.start);
  final e = DateFormat('yy.MM.dd').format(range.end);
  final text = (s == e) ? s : '$s~$e';
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label: ',
        style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
      ),
      Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

Widget _compactText(String label, String value, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label: ',
        style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
      ),
      Text(
        value,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

Color _priorityColor(TaskPriority p) {
  return switch (p) {
    TaskPriority.high => const Color(0xFFEF4444),
    TaskPriority.medium => const Color(0xFFF59E0B),
    TaskPriority.low => const Color(0xFF3B82F6),
    TaskPriority.none => const Color(0xFF94A3B8),
  };
}

String _priorityText(TaskPriority p) {
  return switch (p) {
    TaskPriority.high => '상',
    TaskPriority.medium => '중',
    TaskPriority.low => '하',
    TaskPriority.none => '-',
  };
}
