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

    final scheduledTasks = taskProv.tasks.where((t) => t.teamId == teamId && taskProv.isIncludedInSchedule(t.id)).toList();
    final personal = scheduleProv.itemsForTeam(teamId);

    final selectedEvents = _selectedDay == null ? <_CalendarEvent>[] : _eventsForDay(day: _selectedDay!, tasks: scheduledTasks, personal: personal, taskProv: taskProv, scheduleProv: scheduleProv);

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonalScheduleSheet(context: context, teamId: teamId, myId: myId, myName: myName),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded), label: const Text('계획 추가', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, 10))]),
          child: TableCalendar<_CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1), lastDay: DateTime.utc(2030, 12, 31), focusedDay: _focusedDay,
            calendarFormat: _calendarFormat, rowHeight: 62, daysOfWeekHeight: 25,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) { setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            eventLoader: (day) => _eventsForDay(day: day, tasks: scheduledTasks, personal: personal, taskProv: taskProv, scheduleProv: scheduleProv),
            calendarBuilders: CalendarBuilders(markerBuilder: (context, day, events) { if (events.isEmpty) return null; return _buildPeriodMarkers(day, events); }),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Color(0x1A2563EB), shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              defaultTextStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
              weekendTextStyle: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
              markersMaxCount: 0,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ),
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(child: Text(_selectedDay == null ? '날짜를 선택해 주세요' : '계획이 없습니다.', style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.bold)))
              : ListView.builder(padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), itemCount: selectedEvents.length, itemBuilder: (context, index) { final e = selectedEvents[index]; return _eventTile(context: context, e: e, taskProv: taskProv, scheduleProv: scheduleProv); }),
        ),
      ]),
    );
  }

  Widget _buildPeriodMarkers(DateTime day, List<_CalendarEvent> events) {
    final d = DateTime(day.year, day.month, day.day);
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: events.take(2).map((e) {
      if (e.range == null) return const SizedBox();
      final r = e.range!;
      final s = DateTime(r.start.year, r.start.month, r.start.day);
      final eDate = DateTime(r.end.year, r.end.month, r.end.day);
      final isStart = d.isAtSameMomentAs(s); final isEnd = d.isAtSameMomentAs(eDate);
      final color = e.type == _EventType.task ? AppColors.primary : AppColors.warning;
      return Container(height: 5, margin: EdgeInsets.only(bottom: 2, left: isStart ? 4 : 0, right: isEnd ? 4 : 0), decoration: BoxDecoration(color: color.withValues(alpha: 0.8), borderRadius: BorderRadius.horizontal(left: isStart ? const Radius.circular(4) : Radius.zero, right: isEnd ? const Radius.circular(4) : Radius.zero)));
    }).toList());
  }

  List<_CalendarEvent> _eventsForDay({required DateTime day, required List<Task> tasks, required List<Map<String, dynamic>> personal, required TaskProvider taskProv, required ScheduleProvider scheduleProv}) {
    final d = DateTime(day.year, day.month, day.day); final out = <_CalendarEvent>[];
    for (final t in tasks) { final r = taskProv.effectiveScheduleRange(t); if (r == null) continue; if (_rangeContainsDay(r, d)) { out.add(_CalendarEvent.task(id: t.id, title: t.title, subtitle: _rangeText(r), emoji: t.assigneeEmoji, isDone: t.isDone, task: t, range: r)); } }
    for (final m in personal) { final r = scheduleProv.getRange(m); if (r == null) continue; if (_rangeContainsDay(r, d)) { out.add(_CalendarEvent.personal(id: (m['id'] ?? '').toString(), title: (m['title'] ?? '').toString(), subtitle: _rangeText(r), note: (m['note'] ?? '').toString(), raw: m, range: r)); } }
    return out;
  }

  Widget _eventTile({required BuildContext context, required _CalendarEvent e, required TaskProvider taskProv, required ScheduleProvider scheduleProv}) {
    final icon = e.type == _EventType.task ? Icons.check_circle_outline_rounded : Icons.event_note_rounded;
    final color = e.type == _EventType.task ? AppColors.primary : AppColors.warning;
    return GestureDetector(
      onTap: () { if (e.type == _EventType.task && e.task != null) { showTaskDetailSheet(context: context, task: e.task!); } else if (e.type == _EventType.personal) { _showPersonalScheduleSheet(context: context, teamId: context.read<TeamProvider>().currentTeamId, myId: context.read<AuthProvider>().currentUser?.id ?? 'me', myName: context.read<AuthProvider>().currentUser?.name ?? '관리자', initial: e.raw); } },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(icon, color: color, size: 24), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: TextStyle(color: e.type == _EventType.task && e.isDone ? AppColors.muted : AppColors.text, fontWeight: FontWeight.w900, fontSize: 15, decoration: e.type == _EventType.task && e.isDone ? TextDecoration.lineThrough : null)), const SizedBox(height: 4), Text(e.subtitle, style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w700, fontSize: 12))])),
          if (e.type == _EventType.task) Text(e.emoji, style: const TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Future<void> _showPersonalScheduleSheet({required BuildContext context, required String teamId, required String myId, required String myName, Map<String, dynamic>? initial}) async {
    final scheduleProv = context.read<ScheduleProvider>();
    final titleCtrl = TextEditingController(text: (initial?['title'] ?? '').toString());
    final noteCtrl = TextEditingController(text: (initial?['note'] ?? '').toString());
    DateTimeRange range = initial != null && scheduleProv.getRange(initial) != null ? scheduleProv.getRange(initial)! : DateTimeRange(start: DateTime.now(), end: DateTime.now());
    bool isAllDay = (initial?['isAllDay'] ?? true) == true;
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('계획 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)), const SizedBox(height: 16),
          TextField(controller: titleCtrl, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: '계획 제목')), const SizedBox(height: 12),
          InkWell(onTap: () async { final picked = await showDateRangePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: range); if (picked != null) setModalState(() => range = picked); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Row(children: [const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8), const Text('기간', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text2)), const Spacer(), Text('${DateFormat('yy.MM.dd').format(range.start)} ~ ${DateFormat('yy.MM.dd').format(range.end)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary))]))),
          const SizedBox(height: 16),
          TextField(controller: noteCtrl, maxLines: 3, style: const TextStyle(color: AppColors.text), decoration: const InputDecoration(hintText: '메모(선택)')), const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () async { final title = titleCtrl.text.trim(); if (title.isEmpty) return; if (initial != null) { await scheduleProv.update(id: initial['id'], title: title, note: noteCtrl.text, range: range, isAllDay: isAllDay); } else { await scheduleProv.add(teamId: teamId, userId: myId, userName: myName, title: title, note: noteCtrl.text, range: range, isAllDay: isAllDay); } Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))))
        ])),
      )),
    );
    titleCtrl.dispose(); noteCtrl.dispose();
  }
}

enum _EventType { task, personal }
class _CalendarEvent {
  final _EventType type; final String id, title, subtitle, emoji, note; final bool isDone; final Task? task; final Map<String, dynamic>? raw; final DateTimeRange? range;
  const _CalendarEvent._({required this.type, required this.id, required this.title, required this.subtitle, required this.emoji, required this.isDone, required this.note, required this.task, required this.raw, this.range});
  factory _CalendarEvent.task({required String id, required String title, required String subtitle, required String emoji, required bool isDone, required Task task, DateTimeRange? range}) => _CalendarEvent._(type: _EventType.task, id: id, title: title, subtitle: subtitle, emoji: emoji, isDone: isDone, note: '', task: task, raw: null, range: range);
  factory _CalendarEvent.personal({required String id, required String title, required String subtitle, required String note, required Map<String, dynamic> raw, DateTimeRange? range}) => _CalendarEvent._(type: _EventType.personal, id: id, title: title, subtitle: subtitle, emoji: '', isDone: false, note: note, task: null, raw: raw, range: range);
}
bool _rangeContainsDay(DateTimeRange r, DateTime day) { final d = DateTime(day.year, day.month, day.day); final s = DateTime(r.start.year, r.start.month, r.start.day); final e = DateTime(r.end.year, r.end.month, r.end.day); return !d.isBefore(s) && !d.isAfter(e); }
String _rangeText(DateTimeRange r) { final s = DateFormat('yy.MM.dd').format(r.start); final e = DateFormat('yy.MM.dd').format(r.end); return s == e ? s : '$s~$e'; }
