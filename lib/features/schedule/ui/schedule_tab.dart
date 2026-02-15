import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/team/state/team_provider.dart';

/// 일정 탭(v5)
/// - 업무(Task)에서 "일정에 포함"된 항목을 기간(DateTimeRange)로 표시
/// - 개인 일정(기간)도 작성/수정/삭제 가능
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final scheduleProv = context.watch<ScheduleProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final teamId = teamProv.currentTeamId;

    // 1) 업무 일정(기간)
    final scheduledTasks = taskProv.tasks
        .where((t) => t.teamId == teamId && taskProv.isIncludedInSchedule(t.id))
        .toList();

    // 2) 개인 일정
    final personal = scheduleProv.itemsForTeam(teamId);

    final selectedEvents = _selectedDay == null
        ? <_CalendarEvent>[]
        : _eventsForDay(
            day: _selectedDay!,
            tasks: scheduledTasks,
            personal: personal,
            taskProv: taskProv,
            scheduleProv: scheduleProv,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonalScheduleSheet(
          context: context,
          teamId: teamId,
          myId: myId,
          myName: myName,
        ),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('일정 추가', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          // Calendar card
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: TableCalendar<_CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              eventLoader: (day) => _eventsForDay(
                day: day,
                tasks: scheduledTasks,
                personal: personal,
                taskProv: taskProv,
                scheduleProv: scheduleProv,
              ),
              calendarBuilders: CalendarBuilders<_CalendarEvent>(
                markerBuilder: (context, day, events) => _markerBars(day, events),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: AppPalette.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w900),
                selectedDecoration: const BoxDecoration(color: AppPalette.primary, shape: BoxShape.circle),
                defaultTextStyle: const TextStyle(color: AppPalette.textDark, fontWeight: FontWeight.w700),
                weekendTextStyle: const TextStyle(color: AppPalette.danger, fontWeight: FontWeight.w700),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),

          // Selected day list
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      _selectedDay == null ? '날짜를 선택해 주세요' : '일정이 없습니다.',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final e = selectedEvents[index];
                      return _eventTile(
                        context: context,
                        e: e,
                        taskProv: taskProv,
                        scheduleProv: scheduleProv,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_CalendarEvent> _eventsForDay({
    required DateTime day,
    required List<Task> tasks,
    required List<Map<String, dynamic>> personal,
    required TaskProvider taskProv,
    required ScheduleProvider scheduleProv,
  }) {
    final d = DateTime(day.year, day.month, day.day);
    final out = <_CalendarEvent>[];

    for (final t in tasks) {
      final r = taskProv.effectiveScheduleRange(t);
      if (r == null) continue;
      if (_rangeContainsDay(r, d)) {
        out.add(
          _CalendarEvent.task(
            id: t.id,
            title: t.title,
            subtitle: _rangeText(r),
            range: r,
            emoji: t.assigneeEmoji,
            isDone: t.isDone,
            task: t,
          ),
        );
      }
    }

    for (final m in personal) {
      final r = scheduleProv.getRange(m);
      if (r == null) continue;
      if (_rangeContainsDay(r, d)) {
        out.add(
          _CalendarEvent.personal(
            id: (m['id'] ?? '').toString(),
            title: (m['title'] ?? '').toString(),
            subtitle: _rangeText(r),
            note: (m['note'] ?? '').toString(),
            range: r,
            raw: m,
          ),
        );
      }
    }

    // Sort: tasks first, then personal; within type by title
    out.sort((a, b) {
      if (a.type != b.type) return a.type.index.compareTo(b.type.index);
      return a.title.compareTo(b.title);
    });
    return out;
  }

  Widget? _markerBars(DateTime day, List<_CalendarEvent> events) {
    if (events.isEmpty) return null;

    final multi = events.where((e) {
      final r = e.range;
      if (r == null) return false;
      return !(r.start.year == r.end.year && r.start.month == r.end.month && r.start.day == r.end.day);
    }).toList();

    if (multi.isNotEmpty) {
      final bars = multi.take(2).toList();
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in bars)
                FractionallySizedBox(
                  widthFactor: 0.78,
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: (e.type == _EventType.task ? AppPalette.primary : const Color(0xFFF59E0B)).withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Single-day events: compact dots.
    final dots = events.take(3).toList();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in dots)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (e.type == _EventType.task ? AppPalette.primary : const Color(0xFFF59E0B)).withValues(alpha: 0.80),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eventTile({
    required BuildContext context,
    required _CalendarEvent e,
    required TaskProvider taskProv,
    required ScheduleProvider scheduleProv,
  }) {
    final icon = e.type == _EventType.task ? Icons.check_circle_outline_rounded : Icons.event_note_rounded;
    final color = e.type == _EventType.task ? AppPalette.primary : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () {
        if (e.type == _EventType.task) {
          if (e.task != null) {
            showTaskDetailSheet(context: context, task: e.task!);
          }
        } else {
          _showPersonalScheduleSheet(
            context: context,
            teamId: context.read<TeamProvider>().currentTeamId,
            myId: context.read<AuthProvider>().currentUser?.id ?? 'me',
            myName: context.read<AuthProvider>().currentUser?.name ?? '관리자',
            initial: e.raw,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      color: e.type == _EventType.task && e.isDone ? Colors.grey : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      decoration: e.type == _EventType.task && e.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.subtitle,
                    style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  if (e.type == _EventType.personal && e.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      e.note,
                      style: const TextStyle(color: AppPalette.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
            if (e.type == _EventType.task) Text(e.emoji, style: const TextStyle(fontSize: 20)),
            if (e.type == _EventType.personal) const Icon(Icons.chevron_right_rounded, color: AppPalette.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _showPersonalScheduleSheet({
    required BuildContext context,
    required String teamId,
    required String myId,
    required String myName,
    Map<String, dynamic>? initial,
  }) async {
    final scheduleProv = context.read<ScheduleProvider>();

    final titleCtrl = TextEditingController(text: (initial?['title'] ?? '').toString());
    final noteCtrl = TextEditingController(text: (initial?['note'] ?? '').toString());

    DateTimeRange range = initial != null && scheduleProv.getRange(initial) != null
        ? scheduleProv.getRange(initial)!
        : DateTimeRange(start: DateTime.now(), end: DateTime.now());

    bool isAllDay = (initial?['isAllDay'] ?? true) == true;
    final isEdit = initial != null;
    final id = (initial?['id'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                      Expanded(
                        child: Text(
                          isEdit ? '일정 수정' : '일정 추가',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (isEdit)
                        IconButton(
                          tooltip: '삭제',
                          onPressed: () async {
                            await scheduleProv.remove(id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: '일정 제목',
                      filled: true,
                      fillColor: AppPalette.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: range,
                      );
                      if (picked != null) setModalState(() => range = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_rounded, size: 18, color: AppPalette.primary),
                          const SizedBox(width: 8),
                          const Text('기간', style: TextStyle(fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Text(
                            '${DateFormat('yy.MM.dd').format(range.start)} ~ ${DateFormat('yy.MM.dd').format(range.end)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: isAllDay,
                    onChanged: (v) => setModalState(() => isAllDay = v),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('종일', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('시간 단위는 추후 확장 (지금은 기간 기반)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '메모(선택)',
                      filled: true,
                      fillColor: AppPalette.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;

                        if (isEdit) {
                          await scheduleProv.update(
                            id: id,
                            title: title,
                            note: noteCtrl.text,
                            range: range,
                            isAllDay: isAllDay,
                          );
                        } else {
                          await scheduleProv.add(
                            teamId: teamId,
                            userId: myId,
                            userName: myName,
                            title: title,
                            note: noteCtrl.text,
                            range: range,
                            isAllDay: isAllDay,
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    noteCtrl.dispose();
  }
}

enum _EventType { task, personal }

class _CalendarEvent {
  final _EventType type;
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final bool isDone;
  final String note;
  final DateTimeRange? range;
  final Task? task;
  final Map<String, dynamic>? raw;

  const _CalendarEvent._({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.isDone,
    required this.note,
    required this.range,
    required this.task,
    required this.raw,
  });

  factory _CalendarEvent.task({
    required String id,
    required String title,
    required String subtitle,
    required String emoji,
    required bool isDone,
    required Task task,
    required DateTimeRange range,
  }) {
    return _CalendarEvent._(
      type: _EventType.task,
      id: id,
      title: title,
      subtitle: subtitle,
      emoji: emoji,
      isDone: isDone,
      note: '',
      range: range,
      task: task,
      raw: null,
    );
  }

  factory _CalendarEvent.personal({
    required String id,
    required String title,
    required String subtitle,
    required String note,
    required Map<String, dynamic> raw,
    required DateTimeRange range,
  }) {
    return _CalendarEvent._(
      type: _EventType.personal,
      id: id,
      title: title,
      subtitle: subtitle,
      emoji: '',
      isDone: false,
      note: note,
      range: range,
      task: null,
      raw: raw,
    );
  }
}

bool _rangeContainsDay(DateTimeRange r, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  final s = DateTime(r.start.year, r.start.month, r.start.day);
  final e = DateTime(r.end.year, r.end.month, r.end.day);
  return !d.isBefore(s) && !d.isAfter(e);
}

String _rangeText(DateTimeRange r) {
  final s = DateFormat('yy.MM.dd').format(r.start);
  final e = DateFormat('yy.MM.dd').format(r.end);
  return s == e ? s : '$s~$e';
}
