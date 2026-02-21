import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProv;

  const TaskCard({super.key, required this.task, required this.taskProv});

  @override
  Widget build(BuildContext context) {
    final bool hasSchedule = taskProv.isIncludedInSchedule(task.id);
    final scheduleRange = taskProv.effectiveScheduleRange(task);
    
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. [좌측] 체크 버튼 및 중요도 배지
                Column(
                  children: [
                    _statusCircle(task.isDone),
                    const SizedBox(height: 12),
                    _priorityCircle(task.priority),
                  ],
                ),
                const SizedBox(width: 14),

                // 2. [중앙] 프로젝트명, 제목, 2줄 날짜 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                        child: Text('# $projectName', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: task.isDone ? AppColors.hint : AppColors.text,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 10),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8, runSpacing: 4,
                                  children: [
                                    Text("작성: ${_fmtDate(task.createdAt)}", style: const TextStyle(color: AppColors.text2, fontSize: 12, fontWeight: FontWeight.w600)),
                                    Text("기한: ${_fmtDate(task.dueDate)}", style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w900)),
                                    Text("수정: ${_fmtDate(task.updatedAt)}", style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (task.isDone && task.completedAt != null) 
                                  Text("완료: ${_fmtDate(task.completedAt)}", style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w900))
                                else if (hasSchedule && scheduleRange != null)
                                  Text("일정: ${_fmtDate(scheduleRange.start)}~${_fmtDate(scheduleRange.end)}", style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          _buildScheduleToggle(context, hasSchedule, scheduleRange),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                Container(width: 1, height: 90, color: AppColors.border),
                const SizedBox(width: 12),

                // 3. [우측] 작성자 및 담당자 수직 배치
                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('작성자', style: TextStyle(fontSize: 10, color: AppColors.hint, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(task.creatorName.split(' ').last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.text), overflow: TextOverflow.ellipsis),
                      
                      const SizedBox(height: 12),
                      
                      const Text('담당', style: TextStyle(fontSize: 10, color: AppColors.hint, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(task.assigneeEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(task.assigneeName.split(' ').last, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.text2), overflow: TextOverflow.ellipsis),
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

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('yy.MM.dd').format(d);
  }

  Widget _buildScheduleToggle(BuildContext context, bool hasSchedule, DateTimeRange? range) {
    return GestureDetector(
      onTap: () => taskProv.setScheduleOptions(taskId: task.id, includeInSchedule: !hasSchedule, range: range ?? DateTimeRange(start: task.dueDate, end: task.dueDate)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasSchedule ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasSchedule ? Colors.transparent : AppColors.border)
        ),
        child: Icon(hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined, size: 16, color: hasSchedule ? Colors.white : AppColors.primary),
      ),
    );
  }

  Widget _statusCircle(bool isDone) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: isDone ? AppColors.primary : AppColors.border, width: 2)
      ),
      child: isDone ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
    );
  }

  Widget _priorityCircle(TaskPriority p) { 
    final color = p == TaskPriority.high ? AppColors.danger : (p == TaskPriority.medium ? AppColors.warning : AppColors.primary);
    final text = p == TaskPriority.high ? '상' : (p == TaskPriority.medium ? '중' : '하');
    if (p == TaskPriority.none) return const SizedBox.shrink(); 
    return Container(
      width: 28, height: 28, 
      decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)), 
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)))
    );
  }
}
