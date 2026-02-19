import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_schedule_sheet.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
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
                // 1. 상단: 상태 및 중요도 배지
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusPill(task),
                    _priorityPill(task.priority),
                  ],
                ),
                const SizedBox(height: 10),
                // 2. 제목 (최대 2줄)
                Text(
                  task.title, 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w900, 
                    color: task.isDone ? AppTextColor.hint : AppTextColor.primary,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const Spacer(),
                // 3. 하단 메타 정보 (아이콘 기반)
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MM.dd').format(task.dueDate), 
                        style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800)
                      ),
                    ),
                    _smallIcon(hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined, hasSchedule),
                    const SizedBox(width: 4),
                    _smallIcon(relatedJournals.isNotEmpty ? Icons.article_rounded : Icons.article_outlined, relatedJournals.isNotEmpty),
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

  Widget _statusPill(Task task) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: task.isDone ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(task.isDone ? "완료" : "진행중", style: TextStyle(color: task.isDone ? AppColors.success : AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
  );

  Widget _priorityPill(TaskPriority p) {
    final color = p == TaskPriority.high ? AppColors.danger : (p == TaskPriority.medium ? AppColors.warning : AppColors.primary);
    final text = p == TaskPriority.high ? '상' : (p == TaskPriority.medium ? '중' : '하');
    if (p == TaskPriority.none) return const SizedBox.shrink();
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))),
    );
  }

  Widget _smallIcon(IconData icon, bool isActive) {
    return Icon(icon, size: 16, color: isActive ? AppPalette.primary : Colors.grey.withOpacity(0.4));
  }
}
