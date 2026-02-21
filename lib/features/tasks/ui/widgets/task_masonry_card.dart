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
                    
                    // ✨ [핵심 연동] 캘린더 아이콘 터치 시 일정 탭 등록/해제 토글
                    GestureDetector(
                      onTap: () {
                        // 현재 상태의 반대값으로 토글
                        final newStatus = !hasSchedule;
                        taskProv.setScheduleOptions(
                          taskId: task.id,
                          includeInSchedule: newStatus,
                          // 기존 설정된 기간이 없으면 마감일(dueDate)을 기본값으로 저장
                          range: taskProv.getScheduleRange(task.id) ?? DateTimeRange(start: task.dueDate, end: task.dueDate)
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: hasSchedule ? AppPalette.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Icon(
                          hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined, 
                          size: 16, 
                          color: hasSchedule ? AppPalette.primary : Colors.grey.withValues(alpha: 0.4)
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    
                    Icon(relatedJournals.isNotEmpty ? Icons.article_rounded : Icons.article_outlined, size: 16, color: relatedJournals.isNotEmpty ? AppPalette.primary : Colors.grey.withValues(alpha: 0.4)),
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
      color: task.isDone ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(task.isDone ? "완료" : "진행중", style: TextStyle(color: task.isDone ? AppColors.success : AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
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
