import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/journal/state/journal_provider.dart';
import 'package:worknote/features/journal/ui/sheets/journal_detail_sheet.dart';
import 'package:worknote/features/journal/ui/sheets/journal_write_sheet.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';

/// 업무 상세 바텀시트 표시 함수
Future<void> showTaskDetailSheet({
  required BuildContext context,
  required Task task,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TaskDetailSheetContent(task: task),
  );
}

class _TaskDetailSheetContent extends StatefulWidget {
  final Task task;
  const _TaskDetailSheetContent({required this.task});

  @override
  State<_TaskDetailSheetContent> createState() => _TaskDetailSheetContentState();
}

class _TaskDetailSheetContentState extends State<_TaskDetailSheetContent> {
  // [Fix] 컨트롤러를 State 내부에서 직접 관리하여 생명주기 안전성 확보
  late TextEditingController _reportCtrl;
  bool _includeInSchedule = false;
  late DateTimeRange _scheduleRange;
  bool _saveReportToJournal = true;

  @override
  void initState() {
    super.initState();
    _reportCtrl = TextEditingController(text: widget.task.completionReport ?? '');
    
    // 초기 상태 로드
    final prov = context.read<TaskProvider>();
    _includeInSchedule = prov.isIncludedInSchedule(widget.task.id);
    _scheduleRange = prov.effectiveScheduleRange(widget.task) ?? 
                     DateTimeRange(start: widget.task.dueDate, end: widget.task.dueDate);
  }

  @override
  void dispose() {
    // [Fix] 시트가 닫힐 때 컨트롤러를 안전하게 해제
    _reportCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final authProv = context.read<AuthProvider>();
    final journalProv = context.watch<JournalProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';

    return Container(
      // [요구사항 2] 키보드 가림 방지
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // [요구사항 1] 전체 스크롤 가능하도록 감싸서 무한 오버플로우 방지
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, taskProv),
              const SizedBox(height: 8),
              _buildMetaPills(),
              const SizedBox(height: 14),
              _buildActionButtons(taskProv),
              const SizedBox(height: 10),
              _buildScheduleToggle(taskProv),
              const SizedBox(height: 12),
              _buildJournalButtons(context, myId, myName),
              const SizedBox(height: 10),
              if (widget.task.isDone) _buildCompletionReportForm(taskProv, journalProv, myId, myName),
              const SizedBox(height: 14),
              _buildRelatedJournals(journalProv),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TaskProvider prov) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.task.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text),
          ),
        ),
        IconButton(
          onPressed: () async {
            await prov.deleteTask(widget.task.id);
            if (mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        ),
      ],
    );
  }

  Widget _buildMetaPills() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _pill('작성', DateFormat('yyyy.MM.dd').format(widget.task.createdAt), AppColors.muted),
        _pill('수정', DateFormat('yyyy.MM.dd').format(widget.task.updatedAt), AppColors.primary),
        _pill('기한', DateFormat('yyyy.MM.dd').format(widget.task.dueDate), widget.task.isDone ? AppColors.muted : AppColors.danger),
        if (widget.task.completedAt != null)
          _pill('완료', DateFormat('yyyy.MM.dd').format(widget.task.completedAt!), AppColors.success),
        if (_includeInSchedule)
          _pill(
            '계획',
            '${DateFormat('MM.dd').format(_scheduleRange.start)}~${DateFormat('MM.dd').format(_scheduleRange.end)}',
            AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildActionButtons(TaskProvider prov) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => prov.updateTaskStatus(widget.task, !widget.task.isDone),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.task.isDone ? AppColors.bg : AppColors.primary,
              foregroundColor: widget.task.isDone ? AppColors.text : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Icon(widget.task.isDone ? Icons.undo_rounded : Icons.check_rounded),
            label: Text(widget.task.isDone ? '완료 취소' : '완료 처리', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => prov.cycleTaskPriority(widget.task),
          style: ElevatedButton.styleFrom(
            backgroundColor: _priorityColor(widget.task.priority).withValues(alpha: 0.08),
            foregroundColor: _priorityColor(widget.task.priority),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('중요도', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildScheduleToggle(TaskProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            value: _includeInSchedule,
            onChanged: (v) async {
              setState(() => _includeInSchedule = v);
              await prov.setScheduleOptions(
                taskId: widget.task.id,
                includeInSchedule: _includeInSchedule,
                range: _includeInSchedule ? _scheduleRange : null,
              );
            },
            title: const Text('계획에 포함', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
            subtitle: const Text('계획 탭에 기간 계획으로 표시', style: TextStyle(fontSize: 12)),
          ),
          if (_includeInSchedule)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDateRange: _scheduleRange,
                  );
                  if (picked != null) {
                    if (!mounted) return;
                    setState(() => _scheduleRange = picked);
                    await prov.setScheduleOptions(
                      taskId: widget.task.id,
                      includeInSchedule: true,
                      range: _scheduleRange,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('계획 기간', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
                      const Spacer(),
                      Text(
                        '${DateFormat('yy.MM.dd').format(_scheduleRange.start)} ~ ${DateFormat('yy.MM.dd').format(_scheduleRange.end)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJournalButtons(BuildContext context, String myId, String myName) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showJournalWriteSheet(
                context: context,
                myId: myId,
                myName: myName,
                prefillKind: JournalKind.progress,
                prefillRelatedTaskId: widget.task.id,
                prefillTitle: '진행사항: ${widget.task.title}',
              );
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.note_add_rounded),
            label: const Text('진행사항 기록', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.task.isDone
                ? () {
                    showJournalWriteSheet(
                      context: context,
                      myId: myId,
                      myName: myName,
                      prefillKind: JournalKind.completionReport,
                      prefillRelatedTaskId: widget.task.id,
                      prefillTitle: '완료 보고서: ${widget.task.title}',
                    );
                  }
                : null,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.assignment_turned_in_rounded),
            label: const Text('완료 보고서', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionReportForm(TaskProvider taskProv, JournalProvider journalProv, String myId, String myName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('완료 보고서(업무)', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
        const SizedBox(height: 8),
        TextField(
          controller: _reportCtrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: '완료된 업무에 대한 결과/특이사항/사진 링크 등을 작성하세요',
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _saveReportToJournal,
          onChanged: (v) => setState(() => _saveReportToJournal = v ?? true),
          title: const Text('일지에도 저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          subtitle: const Text('완료 보고서를 일지 탭에서 관리할 수 있습니다.', style: TextStyle(fontSize: 11)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              final raw = _reportCtrl.text.trim();
              await taskProv.saveCompletionReport(widget.task, raw);

              if (_saveReportToJournal && raw.isNotEmpty) {
                final entryId = const Uuid().v4();
                await journalProv.addJournal(
                  JournalEntry(
                    id: entryId,
                    teamId: widget.task.teamId,
                    userId: myId,
                    userName: myName,
                    title: '완료 보고서: ${widget.task.title}',
                    content: raw,
                    date: DateTime.now(),
                    updatedAt: DateTime.now(),
                    photos: const [],
                    projectId: widget.task.projectId,
                    isPrivate: false,
                  ),
                );
                await journalProv.setMeta(entryId, kind: JournalKind.completionReport, relatedTaskId: widget.task.id);
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('완료 보고서 저장 완료')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.save_rounded),
            label: const Text('보고서 저장', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedJournals(JournalProvider journalProv) {
    final related = journalProv.journals
        .where((j) => journalProv.getRelatedTaskId(j.id) == widget.task.id)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('관련 일지', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text))),
              Text('${related.length}건', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          if (related.isEmpty)
            const Text('연결된 일지가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ...related.take(3).map((j) => _relatedJournalTile(context: context, entry: j, kind: journalProv.getKind(j.id))),
          if (related.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('외 ${related.length - 3}건 더 있음', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold, fontSize: 11)),
            )
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Text('$label: $value', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Widget _relatedJournalTile({required BuildContext context, required JournalEntry entry, required JournalKind kind}) {
    final icon = kind == JournalKind.completionReport ? Icons.assignment_turned_in_rounded : Icons.edit_note_rounded;
    final color = kind == JournalKind.completionReport ? AppColors.success : AppPalette.primary;
    return InkWell(
      onTap: () => showJournalDetailSheet(context: context, entry: entry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18),
          ],
        ),
      ),
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
}
