import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/tasks/ui/sheets/task_schedule_sheet.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskCard({super.key, required this.task, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final journalProv = context.watch<JournalProvider>();
    final bool hasSchedule = taskProv.isIncludedInSchedule(task.id);
    final scheduleRange = taskProv.effectiveScheduleRange(task);
    final relatedJournals = journalProv.journals.where((j) => j.content.contains(task.title) || j.title.contains(task.title)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // 1. 상단 Row: 상태, 제목, 중요도 + [신규] 캘린더 토글
                Row(
                  children: [
                    _statusPill(task),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title, 
                        style: TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.w900, 
                          color: task.isDone ? AppTextColor.hint : AppTextColor.primary,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      )
                    ),
                    const SizedBox(width: 10),
                    _priorityPill(task.priority),
                    const SizedBox(width: 8),
                    // [요구사항 1, 3] 캘린더 아이콘 상단 이동 및 토글
                    _buildScheduleToggle(context, hasSchedule, scheduleRange),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                // 2. 하단 Row: 기한, 계획(FittedBox), 기능 아이콘, 담당자
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, color: AppColors.danger, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "기한: ${DateFormat('MM.dd').format(task.dueDate)}", 
                      style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w800)
                    ),
                    if (hasSchedule && scheduleRange != null) ...[
                      const SizedBox(width: 12),
                      // [요구사항 2] '계획' FittedBox 적용하여 전체 표시
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "계획: ${DateFormat('MM.dd').format(scheduleRange.start)}~${DateFormat('MM.dd').format(scheduleRange.end)}",
                            style: const TextStyle(color: AppPalette.primary, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // 기능 아이콘 (일지)
                    _cardIconButton(
                      icon: relatedJournals.isNotEmpty ? Icons.article_rounded : Icons.article_outlined, 
                      isActive: relatedJournals.isNotEmpty, 
                      onPressed: () => showTaskDetailSheet(context: context, task: task)
                    ),
                    const SizedBox(width: 8),
                    // [요구사항 3] 담당자 영역 레이아웃 정상화 (고정 폭 및 여백 확보)
                    _buildAuthorZone(task),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleToggle(BuildContext context, bool hasSchedule, DateTimeRange? range) {
    return GestureDetector(
      onTap: () => taskProv.setScheduleOptions(
        taskId: task.id, 
        includeInSchedule: !hasSchedule, 
        range: range
      ),
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        child: Icon(
          hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_month_outlined, 
          size: 20, 
          color: hasSchedule ? AppPalette.primary : Colors.grey[400]
        ),
      ),
    );
  }

  Widget _buildAuthorZone(Task task) {
    return Container(
      width: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              task.assigneeName, 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.text2), 
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 12, 
            backgroundColor: AppColors.bg,
            child: Text(task.assigneeEmoji, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(Task task) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: task.isDone ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(task.isDone ? "완료" : "진행중", style: TextStyle(color: task.isDone ? AppColors.success : AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _priorityPill(TaskPriority p) {
    final color = p == TaskPriority.high ? AppColors.danger : (p == TaskPriority.medium ? AppColors.warning : AppColors.primary);
    final text = p == TaskPriority.high ? '상' : (p == TaskPriority.medium ? '중' : '하');
    if (p == TaskPriority.none) return const SizedBox.shrink();
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2))),
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
    );
  }

  Widget _cardIconButton({required IconData icon, required bool isActive, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 32, height: 32,
        child: Icon(icon, size: 18, color: isActive ? AppPalette.primary : Colors.grey.withOpacity(0.4)),
      ),
    );
  }
}
