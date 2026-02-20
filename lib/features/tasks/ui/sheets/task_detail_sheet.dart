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

Future<void> showTaskDetailSheet({
  required BuildContext context,
  required Task task,
}) {
  final prov = context.read<TaskProvider>();
  final authProv = context.read<AuthProvider>();
  final journalProv = context.read<JournalProvider>();

  final myId = authProv.currentUser?.id ?? 'me';
  final myName = authProv.currentUser?.name ?? '관리자';

  bool includeInSchedule = prov.isIncludedInSchedule(task.id);
  DateTimeRange scheduleRange = prov.effectiveScheduleRange(task) ?? DateTimeRange(start: task.dueDate, end: task.dueDate);

  final reportCtrl = TextEditingController(text: task.completionReport ?? '');
  bool saveReportToJournal = true;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> persistScheduleMeta() async {
            await prov.setScheduleOptions(
              taskId: task.id,
              includeInSchedule: includeInSchedule,
              range: includeInSchedule ? scheduleRange : null,
            );
          }

          Future<void> saveCompletionReport() async {
            final raw = reportCtrl.text.trim();
            await prov.saveCompletionReport(task, raw);

            // Optionally write it to journal as a completion report.
            if (saveReportToJournal && raw.isNotEmpty) {
              final entryId = const Uuid().v4();
              await journalProv.addJournal(
                JournalEntry(
                  id: entryId,
                  teamId: task.teamId,
                  userId: myId,
                  userName: myName,
                  title: '완료 보고서: ${task.title}',
                  content: raw,
                  date: DateTime.now(),
                  updatedAt: DateTime.now(),
                  photos: const [],
                  projectId: task.projectId,
                  isPrivate: false,
                ),
              );
              await journalProv.setMeta(
                entryId,
                kind: JournalKind.completionReport,
                relatedTaskId: task.id,
              );
            }
          }

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await prov.deleteTask(task.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _pill('작성', DateFormat('yyyy.MM.dd').format(task.createdAt), Colors.black54),
                      _pill('수정', DateFormat('yyyy.MM.dd').format(task.updatedAt), AppPalette.primary),
                      _pill('기한', DateFormat('yyyy.MM.dd').format(task.dueDate), task.isDone ? Colors.grey : Colors.redAccent),
                      if (task.completedAt != null)
                        _pill('완료', DateFormat('yyyy.MM.dd').format(task.completedAt!), const Color(0xFF10B981)),
                      if (includeInSchedule)
                        _pill(
                          '일정',
                          '${DateFormat('yyyy.MM.dd').format(scheduleRange.start)}~${DateFormat('yyyy.MM.dd').format(scheduleRange.end)}',
                          AppPalette.primary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => prov.updateTaskStatus(task, !task.isDone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: task.isDone ? Colors.grey[300] : AppPalette.primary,
                            foregroundColor: task.isDone ? Colors.black87 : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(task.isDone ? Icons.undo_rounded : Icons.check_rounded),
                          label: Text(task.isDone ? '완료 취소' : '완료 처리', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => prov.cycleTaskPriority(task),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _priorityColor(task.priority).withValues(alpha: 0.08),
                          foregroundColor: _priorityColor(task.priority),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('중요도', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Schedule inclusion
                  Container(
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          value: includeInSchedule,
                          onChanged: (v) async {
                            setModalState(() => includeInSchedule = v);
                            await persistScheduleMeta();
                          },
                          title: const Text('일정에 포함', style: TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: const Text('일정 탭에 기간 일정으로 표시'),
                        ),
                        if (includeInSchedule)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDateRangePicker(
                                  context: ctx,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  initialDateRange: scheduleRange,
                                );
                                if (picked != null) {
                                  setModalState(() => scheduleRange = picked);
                                  await persistScheduleMeta();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, size: 18, color: AppPalette.primary),
                                    const SizedBox(width: 8),
                                    const Text('일정 기간', style: TextStyle(fontWeight: FontWeight.w900)),
                                    const Spacer(),
                                    Text(
                                      '${DateFormat('yy.MM.dd').format(scheduleRange.start)} ~ ${DateFormat('yy.MM.dd').format(scheduleRange.end)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Work log buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Quick progress log → journal
                            showJournalWriteSheet(
                              context: context,
                              myId: myId,
                              myName: myName,
                              prefillKind: JournalKind.progress,
                              prefillRelatedTaskId: task.id,
                              prefillTitle: '진행사항: ${task.title}',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.note_add_rounded),
                          label: const Text('진행사항 기록', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: task.isDone
                              ? () {
                                  showJournalWriteSheet(
                                    context: context,
                                    myId: myId,
                                    myName: myName,
                                    prefillKind: JournalKind.completionReport,
                                    prefillRelatedTaskId: task.id,
                                    prefillTitle: '완료 보고서: ${task.title}',
                                  );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.assignment_turned_in_rounded),
                          label: const Text('완료 보고서', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Completion report editor (for completed tasks)
                  if (task.isDone) ...[
                    const SizedBox(height: 4),
                    const Text('완료 보고서(업무)', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reportCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '완료된 업무에 대한 결과/특이사항/사진 링크 등을 작성하세요',
                        filled: true,
                        fillColor: AppPalette.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: saveReportToJournal,
                      onChanged: (v) => setModalState(() => saveReportToJournal = v ?? true),
                      title: const Text('일지에도 저장', style: TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: const Text('완료 보고서를 일지 탭에서 검색/관리할 수 있습니다.'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await saveCompletionReport();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('완료 보고서 저장 완료')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('보고서 저장', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],

                  // Related journals (linked by journal_meta.relatedTaskId)
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final related = journalProv.journals
                          .where((j) => journalProv.getRelatedTaskId(j.id) == task.id)
                          .toList()
                        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppPalette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('관련 일지', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                                Text(
                                  '${related.length}건',
                                  style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (related.isEmpty)
                              const Text('연결된 일지가 없습니다. (일지 작성 시 “관련 업무”로 연결하세요)', style: TextStyle(color: Colors.grey))
                            else
                              ...related.take(3).map(
                                    (j) => _relatedJournalTile(
                                      context: context,
                                      entry: j,
                                      kind: journalProv.getKind(j.id),
                                    ),
                                  ),
                            if (related.length > 3) ...[
                              const SizedBox(height: 6),
                              Text(
                                '외 ${related.length - 3}건 더 있음 (일지 탭에서 확인)',
                                style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    reportCtrl.dispose();
  });
}

Widget _pill(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
    ),
  );
}

Widget _relatedJournalTile({
  required BuildContext context,
  required JournalEntry entry,
  required JournalKind kind,
}) {
  final icon = switch (kind) {
    JournalKind.note => Icons.edit_note_rounded,
    JournalKind.progress => Icons.timeline_rounded,
    JournalKind.completionReport => Icons.assignment_turned_in_rounded,
  };
  final color = switch (kind) {
    JournalKind.note => AppPalette.primary,
    JournalKind.progress => const Color(0xFFF59E0B),
    JournalKind.completionReport => const Color(0xFF10B981),
  };

  final preview = entry.content.trim().replaceAll('\n', ' ');
  final previewShort = preview.length > 48 ? '${preview.substring(0, 48)}…' : preview;

  return InkWell(
    onTap: () => showJournalDetailSheet(context: context, entry: entry),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(previewShort, style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppPalette.textMuted),
        ],
      ),
    ),
  );
}

Color _priorityColor(TaskPriority p) {
  return switch (p) {
    TaskPriority.high => const Color(0xFFEF4444),
    TaskPriority.medium => const Color(0xFFF59E0B),
    TaskPriority.low => const Color(0xFF3B82F6),
    TaskPriority.none => const Color(0xFF94A3B8),
  };
}
