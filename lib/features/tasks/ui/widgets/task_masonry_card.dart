import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';

class TaskMasonryCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskMasonryCard({super.key, required this.task, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final bool hasSchedule = taskProv.isIncludedInSchedule(task.id);
    
    Project? project;
    final pid = task.projectId;
    if (pid != null) {
      for (final p in taskProv.projects) {
        if (p.id == pid) {
          project = p;
          break;
        }
      }
    }
    final projectName = project?.name ?? '일반 업무';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 프로젝트명 및 중요도
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                        child: Text('# $projectName', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _priorityCircle(task.priority),
                  ],
                ),
                const SizedBox(height: 10),
                
                // 2. 제목
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: task.isDone ? AppColors.hint : AppColors.text,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 12),

                // 3. 진행 상태 배지
                _statusPill(task.isDone),
                
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                
                // 4. 하단 메타 정보 (기한, 담당자 썸네일, 캘린더)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MM.dd').format(task.dueDate),
                        style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w900),
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
                      child: Icon(
                        hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
                        size: 18,
                        color: hasSchedule ? AppColors.primary : AppColors.hint
                      ),
                    ),
                    const SizedBox(width: 8),

                    Container(width: 1, height: 16, color: AppColors.border),
                    const SizedBox(width: 8),
                    
                    Text(task.assigneeEmoji, style: const TextStyle(fontSize: 16)),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isDone ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      border: Border.all(color: isDone ? AppColors.primary : AppColors.border),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(isDone ? "완료됨" : "진행중", style: TextStyle(color: isDone ? AppColors.primary : AppColors.text2, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _priorityCircle(TaskPriority p) { 
    final color = p == TaskPriority.high ? AppColors.danger : (p == TaskPriority.medium ? AppColors.warning : AppColors.primary);
    final text = p == TaskPriority.high ? '상' : (p == TaskPriority.medium ? '중' : '하');
    if (p == TaskPriority.none) return const SizedBox.shrink(); 
    return Container(
      width: 20, height: 20, 
      decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: color, width: 1)), 
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)))
    );
  }
}
