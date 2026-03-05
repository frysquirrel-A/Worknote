import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/theme/premium_theme.dart';
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182235), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4F8CFF).withValues(alpha: 0.10)),
        boxShadow: premiumShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => showTaskDetailSheet(context: context, task: task),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. [좌측] 체크 버튼 및 중요도 배지
                Column(
                  children: [
                    _statusCircle(task.isDone),
                    const SizedBox(height: 14),
                    _priorityCircle(task.priority),
                  ],
                ),
                const SizedBox(width: 16),

                // 2. [중앙] 프로젝트명, 제목, 2줄 날짜 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: WorkNotePremium.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '# $projectName',
                          style: const TextStyle(
                            color: WorkNotePremium.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        task.title,
                        style: WorkNoteType.subHeading.copyWith(
                          color: task.isDone ? WorkNotePremium.textMuted : WorkNotePremium.textMain,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    _metaText("작성", task.createdAt, WorkNotePremium.textMuted),
                                    _metaText("기한", task.dueDate, Colors.redAccent),
                                    _metaText("수정", task.updatedAt, WorkNotePremium.primary),
                                  ],
                                ),
                                if (task.isDone && task.completedAt != null) 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "완료: ${_fmtDate(task.completedAt)}",
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                  )
                                else if (hasSchedule && scheduleRange != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "일정: ${_fmtDate(scheduleRange.start)}~${_fmtDate(scheduleRange.end)}",
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _buildScheduleToggle(context, hasSchedule, scheduleRange),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                Container(width: 1, height: 100, color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(width: 16),

                // 3. [우측] 작성자 및 담당자 수직 배치
                SizedBox(
                  width: 54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('작성자', style: TextStyle(fontSize: 10, color: WorkNotePremium.textMuted, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        task.creatorName.split(' ').last,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: WorkNotePremium.textMain),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text('담당', style: TextStyle(fontSize: 10, color: WorkNotePremium.textMuted, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(task.assigneeEmoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        task.assigneeName.split(' ').last,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: WorkNotePremium.textMuted),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
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

  Widget _metaText(String label, DateTime date, Color color) {
    return Text(
      "$label: ${_fmtDate(date)}",
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
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
        width: 36, height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasSchedule ? WorkNotePremium.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasSchedule ? Colors.transparent : Colors.white.withValues(alpha: 0.1))
        ),
        child: Icon(hasSchedule ? Icons.calendar_month_rounded : Icons.calendar_today_outlined, size: 18, color: hasSchedule ? Colors.white : WorkNotePremium.primary),
      ),
    );
  }

  Widget _statusCircle(bool isDone) {
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: isDone ? WorkNotePremium.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: isDone ? WorkNotePremium.primary : Colors.white.withValues(alpha: 0.2), width: 2)
      ),
      child: isDone ? const Icon(Icons.check_rounded, size: 20, color: Colors.white) : null,
    );
  }

  Widget _priorityCircle(TaskPriority p) { 
    final color = p == TaskPriority.high ? Colors.redAccent : (p == TaskPriority.medium ? Colors.amberAccent : WorkNotePremium.primary);
    final text = p == TaskPriority.high ? '상' : (p == TaskPriority.medium ? '중' : '하');
    if (p == TaskPriority.none) return const SizedBox.shrink(); 
    return Container(
      width: 30, height: 30, 
      decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5)),
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)))
    );
  }
}
