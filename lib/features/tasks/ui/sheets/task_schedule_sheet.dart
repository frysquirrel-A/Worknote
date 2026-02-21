import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';

/// 업무 카드/상세에서 빠르게 "계획(기간)"만 수정하는 미니 시트
Future<void> showTaskScheduleSheet({
  required BuildContext context,
  required Task task,
}) {
  final prov = context.read<TaskProvider>();

  bool includeInSchedule = prov.isIncludedInSchedule(task.id);
  DateTimeRange range = prov.effectiveScheduleRange(task) ?? DateTimeRange(start: task.dueDate, end: task.dueDate);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> persist() async {
            await prov.setScheduleOptions(
              taskId: task.id,
              includeInSchedule: includeInSchedule,
              range: includeInSchedule ? range : null,
            );
          }

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppPalette.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('계획 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(task.title, style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),

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
                          await persist();
                        },
                        title: const Text('계획에 포함', style: TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: const Text('계획 탭에서 기간 계획으로 표시'),
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
                                initialDateRange: range,
                              );
                              if (picked != null) {
                                if (!ctx.mounted) return;
                                setModalState(() => range = picked);
                                await persist();
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
                                  const Icon(Icons.date_range_rounded, size: 18, color: AppPalette.primary),
                                  const SizedBox(width: 8),
                                  const Text('계획 기간', style: TextStyle(fontWeight: FontWeight.w900)),
                                  const Spacer(),
                                  Text(
                                    '${DateFormat('yy.MM.dd').format(range.start)} ~ ${DateFormat('yy.MM.dd').format(range.end)}',
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

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await persist();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
