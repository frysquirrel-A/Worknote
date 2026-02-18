import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_schedule_sheet.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskCard({super.key, required this.task, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final project = taskProv.projects.firstWhere(
      (p) => p.id == task.projectId,
      orElse: () => Project(id: '', teamId: '', name: '일반 업무', colorValue: AppColors.muted.value),
    );

    final includedInSchedule = taskProv.isIncludedInSchedule(task.id);
    final scheduleRange = taskProv.effectiveScheduleRange(task);

    // 정렬을 위한 기준 높이값
    const double metaTopOffset = 54; 

    return GestureDetector(
      onTap: () => showTaskDetailSheet(context: context, task: task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone 1: Left (Checkbox + Absolute Priority Badge)
              SizedBox(
                width: 48,
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 4,
                      child: GestureDetector(
                        onTap: () => taskProv.updateTaskStatus(task, !task.isDone),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isDone ? AppColors.primary : AppColors.surface,
                            border: Border.all(color: task.isDone ? AppColors.primary : AppColors.border, width: 2),
                          ),
                          child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      ),
                    ),
                    Positioned(
                      top: metaTopOffset - 4, // 중앙 메타 블록의 첫 줄 시작 위치에 배지 중심 고정
                      left: 1,
                      child: GestureDetector(
                        onTap: () => taskProv.cycleTaskPriority(task),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _priorityColor(task.priority), width: 1.5),
                            color: _priorityColor(task.priority).withValues(alpha: 0.08),
                          ),
                          child: Center(
                            child: Text(
                              _priorityText(task.priority),
                              style: TextStyle(color: _priorityColor(task.priority), fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Zone 2: Middle (Title + Meta Block)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: project.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text('#${project.name}', style: TextStyle(color: project.color, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.title,
                      maxLines: 1, // 레이아웃 고정을 위해 1줄 제한
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: task.isDone ? AppColors.muted : AppColors.text,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 10), // 메타 블록 시작 지점 고정
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _compactDate('작성', task.createdAt, AppColors.hint),
                              _compactDate('기한', task.dueDate, task.isDone ? AppColors.muted : AppColors.danger),
                              if (task.isDone && task.completedAt != null)
                                _compactDate('완료', task.completedAt!, AppColors.success)
                              else
                                _compactDate('수정', task.updatedAt, AppColors.hint),
                              if (includedInSchedule && scheduleRange != null)
                                _compactRange('일정', scheduleRange, AppColors.warning),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '일정 설정',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => showTaskScheduleSheet(context: context, task: task),
                          icon: Icon(
                            includedInSchedule ? Icons.calendar_month_rounded : Icons.calendar_month_outlined,
                            color: includedInSchedule ? AppColors.primary : AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Zone 3: Right (Author + Assignee)
              const VerticalDivider(width: 1, thickness: 1, color: AppColors.bg),
              SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('작성자', style: TextStyle(fontSize: 8, color: AppColors.muted, fontWeight: FontWeight.bold)),
                    Text(task.creatorName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.text2), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    const Text('담당', style: TextStyle(fontSize: 8, color: AppColors.muted, fontWeight: FontWeight.bold)),
                    Text(task.assigneeEmoji, style: const TextStyle(fontSize: 22)),
                    Text(task.assigneeName, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.text2), overflow: TextOverflow.ellipsis),
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

Widget _compactDate(String label, DateTime date, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label: ', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
      Text(DateFormat('yy.MM.dd').format(date), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
    ],
  );
}

Widget _compactRange(String label, DateTimeRange? range, Color color) {
  if (range == null) return const SizedBox();
  final s = DateFormat('yy.MM.dd').format(range.start);
  final e = DateFormat('yy.MM.dd').format(range.end);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label: ', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
      Text(s == e ? s : '$s~$e', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
    ],
  );
}

Color _priorityColor(TaskPriority p) {
  return switch (p) {
    TaskPriority.high => AppColors.danger,
    TaskPriority.medium => AppColors.warning,
    TaskPriority.low => AppColors.primary,
    TaskPriority.none => AppColors.muted,
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
