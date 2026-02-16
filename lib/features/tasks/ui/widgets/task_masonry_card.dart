import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_schedule_sheet.dart';

class TaskMasonryCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskMasonryCard({super.key, required this.task, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final project = taskProv.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: 0xFF94A3B8),
    );

    final included = taskProv.isIncludedInSchedule(task.id);
    final scheduleRange = taskProv.effectiveScheduleRange(task);

    return InkWell(
      onTap: () => showTaskDetailSheet(context: context, task: task),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isDone ? AppPalette.primary : Colors.white,
                      border: Border.all(color: task.isDone ? AppPalette.primary : const Color(0xFFCBD5E1), width: 2),
                    ),
                    child: task.isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => taskProv.cycleTaskPriority(task),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _priorityColor(task.priority).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _priorityColor(task.priority).withValues(alpha: 0.25)),
                    ),
                    child: Text(_priorityText(task.priority), style: TextStyle(color: _priorityColor(task.priority), fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ),
                const Spacer(),
                Text(task.assigneeEmoji, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: project.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
              child: Text('#${project.name}', style: TextStyle(color: project.color, fontSize: 10, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: task.isDone ? AppTextColor.hint : AppTextColor.primary,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppPalette.border)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _metaRow('작성', DateFormat('yy.MM.dd').format(task.createdAt), AppTextColor.secondary),
                            const SizedBox(height: 4),
                            _metaRow('기한', DateFormat('yy.MM.dd').format(task.dueDate), task.isDone ? AppTextColor.hint : AppTextColor.danger),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '일정 설정',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => showTaskScheduleSheet(context: context, task: task),
                        icon: Icon(included ? Icons.calendar_month_rounded : Icons.calendar_month_outlined, size: 20, color: included ? AppPalette.primary : AppTextColor.hint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (task.isDone && task.completedAt != null)
                    _metaRow('완료', DateFormat('yy.MM.dd').format(task.completedAt!), AppTextColor.success)
                  else
                    _metaRow('수정', DateFormat('yy.MM.dd').format(task.updatedAt), AppTextColor.secondary),
                  const SizedBox(height: 4),
                  if (included && scheduleRange != null)
                    _metaRow('일정', _rangeText(scheduleRange), AppTextColor.warning),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: AppTextColor.hint),
                      const SizedBox(width: 6),
                      Expanded(child: Text('작성자: ${task.creatorName}', style: const TextStyle(color: AppTextColor.hint, fontWeight: FontWeight.w800, fontSize: 11), overflow: TextOverflow.ellipsis)),
                      if (task.isDone) const Icon(Icons.verified_rounded, size: 16, color: AppTextColor.success),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _metaRow(String label, String value, Color color) {
  return Row(
    children: [
      SizedBox(width: 34, child: Text(label, style: const TextStyle(color: AppTextColor.hint, fontWeight: FontWeight.w900, fontSize: 11))),
      Expanded(child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11), overflow: TextOverflow.ellipsis)),
    ],
  );
}

String _rangeText(DateTimeRange r) {
  final s = DateFormat('yy.MM.dd').format(r.start);
  final e = DateFormat('yy.MM.dd').format(r.end);
  return s == e ? s : '$s~$e';
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
