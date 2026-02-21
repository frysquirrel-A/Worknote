import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';

class TaskMasonryCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskMasonryCard({super.key, required this.task, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final journalProv = context.watch<JournalProvider>();
    final bool hasSchedule = taskProv.isIncludedInSchedule(task.id);
    final relatedJournals = journalProv.journals.where((j) => j.content.contains(task.title) || j.title.contains(task.title)).toList();

    final project = taskProv.projects.where((p) => p.id == task.projectId).firstOrNull;
    final projectName = project?.name ?? '프로젝트 미지정';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 프로젝트명 및 중요도
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('# $projectName', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                    ),
                    _priorityPill(task.priority),
                  ],
                ),
                const SizedBox(height: 6),
                
                // 2. 제목
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: task.isDone ? AppColors.hint : AppColors.text,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 8),

                // 3. 진행 상태 배지
                _statusPill(task.isDone),
                
                const SizedBox(height: 8),
                const Divider(height: 16),
                
                // 4. 하단 메타 정보 (기한, 일정 연동, 관련 일지, 담당자)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '기한: ${DateFormat('MM.dd').format(task.dueDate)}',
                        style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: () {
                        taskProv.setScheduleOptions(
                          taskId: task.id,
                          includeInSchedule: !hasSchedule,
                          range: taskProv.getScheduleRange(task.id) ?? DateTimeRange(start: task.dueDate, end: task.dueDate)
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: hasSchedule ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Icon(
                          hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
                          size: 16,
                          color: hasSchedule ? AppColors.primary : AppColors.hint
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    Icon(relatedJournals.isNotEmpty ? Icons.article_rounded : Icons.article_outlined, size: 16, color: relatedJournals.isNotEmpty ? AppColors.primary : AppColors.hint),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.bg,
                      child: Text(task.assigneeEmoji, style: const TextStyle(fontSize: 10)),
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

  Widget _statusPill(bool isDone) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: isDone ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(isDone ? "완료" : "진행중", style: TextStyle(color: isDone ? AppColors.success : AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
  );

  Widget _priorityPill(TaskPriority priority) {
    final color = priority == TaskPriority.high ? AppColors.danger : (priority == TaskPriority.medium ? AppColors.warning : AppColors.primary);
    final text = priority == TaskPriority.high ? '상' : (priority == TaskPriority.medium ? '중' : '하');
    if (priority == TaskPriority.none) return const SizedBox.shrink();
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))),
    );
  }
}
