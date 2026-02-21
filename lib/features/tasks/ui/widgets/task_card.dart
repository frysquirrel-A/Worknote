import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
    
    // 프로젝트 이름 가져오기
    final project = taskProv.projects.where((p) => p.id == task.projectId).firstOrNull;
    final projectName = project?.name ?? '프로젝트 미지정';

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // [좌측 Zone]: 체크 라디오 버튼과 중요도 배지
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statusCircle(task.isDone),
                    const SizedBox(height: 8),
                    _priorityPill(task.priority),
                  ],
                ),
                const SizedBox(width: 14),

                // [중앙 Zone]: 프로젝트명, 제목, 2줄 압축 날짜 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로젝트명 태그 및 상태 배지
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text('# $projectName', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 6),
                          _statusPill(task.isDone),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 제목
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: task.isDone ? AppColors.hint : AppColors.text,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 8),

                      // 날짜 정보 Line 1 (작성, 기한)
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: [
                          Text("작성: ${_fmtDate(task.createdAt)}", style: const TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w600)),
                          Text("기한: ${_fmtDate(task.dueDate)}", style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 날짜 정보 Line 2 (수정, 계획/완료)
                      Wrap(
                        spacing: 8, runSpacing: 4,
                        children: [
                          Text("수정: ${_fmtDate(task.updatedAt)}", style: const TextStyle(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.w600)),
                          if (hasSchedule && scheduleRange != null && !task.isDone)
                            Text("일정: ${_fmtDate(scheduleRange.start)}~${_fmtDate(scheduleRange.end)}", style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w800)),
                          if (task.isDone && task.completedAt != null) 
                            Text("완료: ${_fmtDate(task.completedAt)}", style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                
                // 중앙 캘린더 아이콘 버튼 (분리 배치)
                _buildScheduleToggle(context, hasSchedule, scheduleRange),
                
                const SizedBox(width: 12),
                Container(width: 1, height: 60, color: AppColors.border),
                const SizedBox(width: 12),

                // [우측 Zone]: 작성자 및 담당자 수직 배치
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('작성자', style: TextStyle(fontSize: 10, color: AppColors.hint, fontWeight: FontWeight.w800)),
                    Text(task.creatorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.text)),
                    const SizedBox(height: 8),
                    const Text('담당', style: TextStyle(fontSize: 10, color: AppColors.hint, fontWeight: FontWeight.w800)),
                    Row(
                      children: [
                        CircleAvatar(radius: 8, backgroundColor: AppColors.bg, child: Text(task.assigneeEmoji, style: const TextStyle(fontSize: 10))),
                        const SizedBox(width: 4),
                        Text(task.assigneeName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.text)),
                      ],
                    )
                  ],
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
        width: 34, height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasSchedule ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasSchedule ? Colors.transparent : AppColors.border)
        ),
        child: Icon(hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined, size: 18, color: hasSchedule ? Colors.white : AppColors.primary),
      ),
    );
  }

  Widget _statusCircle(bool isDone) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: isDone ? AppColors.success.withValues(alpha: 0.1) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: isDone ? AppColors.success : AppColors.border, width: 2)
      ),
      child: isDone ? const Icon(Icons.check_rounded, size: 14, color: AppColors.success) : null,
    );
  }

  Widget _statusPill(bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDone ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6)
      ),
      child: Text(isDone ? "완료" : "진행중", style: TextStyle(color: isDone ? AppColors.success : AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _priorityPill(TaskPriority p) { 
    final color = p == TaskPriority.high ? AppColors.danger : (p == TaskPriority.medium ? AppColors.warning : AppColors.primary);
    final text = p == TaskPriority.high ? '상' : (p == TaskPriority.medium ? '중' : '하');
    if (p == TaskPriority.none) return const SizedBox.shrink(); 
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.2))), 
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)))
    );
  }
}
