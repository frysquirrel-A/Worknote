import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/team/ui/dev_log_page.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});
  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _searchQuery = '';
  bool _isCardMode = true; // ✨ [패치 2] 뷰 모드 상태 변수 추가
  bool _showAllTeams = false; // ✨ [패치 1] 글로벌 팀 필터 상태 추가

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final scheduleProv = context.watch<ScheduleProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final teamId = teamProv.currentTeamId;

    final q = _searchQuery.trim().toLowerCase();

    // ✨ [패치 1] 통합 팀 필터링 로직
    final scheduledTasks = taskProv.tasks.where((t) {
      if (!_showAllTeams && t.teamId != teamId) return false;
      if (!taskProv.isIncludedInSchedule(t.id)) return false;
      if (q.isNotEmpty && !t.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    final personal = scheduleProv.itemsForTeam(null).where((p) {
      final pTeamId = p['teamId']?.toString();
      if (!_showAllTeams && pTeamId != teamId) return false;
      if (q.isNotEmpty) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final note = (p['note'] ?? '').toString().toLowerCase();
        if (!title.contains(q) && !note.contains(q)) return false;
      }
      return true;
    }).toList();

    final selectedEvents = _selectedDay == null
        ? <_CalendarEvent>[]
        : _eventsForDay(day: _selectedDay!, tasks: scheduledTasks, personal: personal, taskProv: taskProv, scheduleProv: scheduleProv);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('일정', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              // ✨ [수정] 테스트를 위한 강제 크래시 발생
              FirebaseCrashlytics.instance.crash();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonalScheduleSheet(context: context, teamId: teamId, myId: myId, myName: myName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('계획 추가', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✨ [패치 1, 2] 필터 및 토글 UI 통합
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            hintText: '계획을 검색하세요...',
                            hintStyle: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w700),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_isCardMode ? Icons.calendar_view_month : Icons.view_headline, color: AppColors.primary),
                        onPressed: () => setState(() => _isCardMode = !_isCardMode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('모든 팀 일정 보기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        selected: _showAllTeams,
                        onSelected: (v) => setState(() => _showAllTeams = v),
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        checkmarkColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ✨ [패치 3] TableCalendar 삭제 및 커스텀 달력 호출
            _buildCustomCalendar(scheduledTasks, personal, taskProv, scheduleProv),
            if (selectedEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 100),
                child: Center(child: Text(_selectedDay == null ? '날짜를 선택해 주세요' : '계획이 없습니다.', style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.bold))),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedEvents.length,
                itemBuilder: (context, index) {
                  final e = selectedEvents[index];
                  return _eventTile(context: context, e: e, taskProv: taskProv, scheduleProv: scheduleProv);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ✨ [패치 3] 유동적 높이 & Spanning UI 커스텀 달력 빌더
  Widget _buildCustomCalendar(List<Task> tasks, List<Map<String, dynamic>> personal, TaskProvider taskProv, ScheduleProvider scheduleProv) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final startDay = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    final endDay = lastDayOfMonth.add(Duration(days: (6 - lastDayOfMonth.weekday) % 7));

    final List<TableRow> rows = [];

    // 요일 헤더
    rows.add(TableRow(
      children: ['일', '월', '화', '수', '목', '금', '토'].map((d) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Text(d, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: d == '일' ? AppColors.danger : (d == '토' ? Colors.blue : AppColors.muted))),
      )).toList(),
    ));

    DateTime current = startDay;
    while (current.isBefore(endDay) || current.isAtSameMomentAs(endDay)) {
      final List<Widget> cells = [];
      for (int i = 0; i < 7; i++) {
        final day = current;
        final events = _eventsForDay(day: day, tasks: tasks, personal: personal, taskProv: taskProv, scheduleProv: scheduleProv);
        
        // 슬롯 정렬 (일관된 렌더링을 위해 시작일 및 기간 순 정렬)
        events.sort((a, b) {
          if (a.range == null || b.range == null) return 0;
          final startComp = a.range!.start.compareTo(b.range!.start);
          if (startComp != 0) return startComp;
          final durA = a.range!.end.difference(a.range!.start);
          final durB = b.range!.end.difference(b.range!.start);
          return durB.compareTo(durA);
        });

        final isSelected = _selectedDay != null && isSameDay(_selectedDay!, day);
        final isToday = isSameDay(DateTime.now(), day);
        final isOutside = day.month != _focusedDay.month;

        cells.add(GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: BoxConstraints(minHeight: _isCardMode ? 110 : 74),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
              border: Border.all(color: AppColors.border.withOpacity(0.3), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 24, height: 24,
                    alignment: Alignment.center,
                    decoration: isToday ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle) : null,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w900,
                        color: isToday ? Colors.white : (isOutside ? AppColors.hint.withOpacity(0.5) : (day.weekday == 7 ? AppColors.danger : (day.weekday == 6 ? Colors.blue : AppColors.text))),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Column(
                    children: events.take(4).map((e) {
                      final isSingleDay = e.range == null || isSameDay(e.range!.start, e.range!.end);
                      final color = e.type == _EventType.task ? const Color(0xFF2563EB) : const Color(0xFFF59E0B);
                      
                      if (!_isCardMode) {
                        // 🔹 점 모드 UI
                        return Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          child: Center(
                            child: isSingleDay 
                              ? Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                              : Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: color.withOpacity(0.6), borderRadius: BorderRadius.circular(2))),
                          ),
                        );
                      } else {
                        // 🔹 카드 모드 Spanning UI (연속 카드 트릭)
                        final isStart = e.range != null && isSameDay(e.range!.start, day);
                        final isEnd = e.range != null && isSameDay(e.range!.end, day);
                        
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: 3, 
                            left: (isSingleDay || isStart) ? 4 : 0, 
                            right: (isSingleDay || isEnd) ? 4 : 0
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.85),
                            borderRadius: BorderRadius.horizontal(
                              left: (isSingleDay || isStart) ? const Radius.circular(4) : Radius.zero,
                              right: (isSingleDay || isEnd) ? const Radius.circular(4) : Radius.zero,
                            ),
                          ),
                          child: (isSingleDay || isStart || day.weekday == 7) // 시작일이거나 한 주의 시작(일요일)이면 텍스트 표시
                            ? Text(
                                e.title,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              )
                            : const SizedBox(height: 11),
                        );
                      }
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ));
        current = current.add(const Duration(days: 1));
      }
      rows.add(TableRow(children: cells));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(DateFormat('yyyy년 MM월').format(_focusedDay), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  }),
                  child: const Text('오늘', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(), 1: FlexColumnWidth(), 2: FlexColumnWidth(), 3: FlexColumnWidth(), 4: FlexColumnWidth(), 5: FlexColumnWidth(), 6: FlexColumnWidth(),
            },
            children: rows,
          ),
        ],
      ),
    );
  }

  List<_CalendarEvent> _eventsForDay({required DateTime day, required List<Task> tasks, required List<Map<String, dynamic>> personal, required TaskProvider taskProv, required ScheduleProvider scheduleProv}) {
    final d = DateTime(day.year, day.month, day.day);
    final out = <_CalendarEvent>[];
    for (final t in tasks) {
      final r = taskProv.effectiveScheduleRange(t);
      if (r == null) continue;
      if (_rangeContainsDay(r, d)) {
        out.add(_CalendarEvent.task(id: t.id, title: t.title, subtitle: _rangeText(r), emoji: t.assigneeEmoji, isDone: t.isDone, task: t, range: r));
      }
    }
    for (final m in personal) {
      final r = scheduleProv.getRange(m);
      if (r == null) continue;
      if (_rangeContainsDay(r, d)) {
        out.add(_CalendarEvent.personal(id: (m['id'] ?? '').toString(), title: (m['title'] ?? '').toString(), subtitle: _rangeText(r), note: (m['note'] ?? '').toString(), raw: m, range: r));
      }
    }
    return out;
  }

  Widget _eventTile({required BuildContext context, required _CalendarEvent e, required TaskProvider taskProv, required ScheduleProvider scheduleProv}) {
    final icon = e.type == _EventType.task ? Icons.check_circle_outline_rounded : Icons.event_note_rounded;
    final color = e.type == _EventType.task ? AppColors.primary : AppColors.warning;
    return GestureDetector(
      onTap: () {
        if (e.type == _EventType.task && e.task != null) {
          showTaskDetailSheet(context: context, task: e.task!);
        } else if (e.type == _EventType.personal) {
          final currentTeamId = context.read<TeamProvider>().currentTeamId;
          final user = context.read<AuthProvider>().currentUser;
          _showPersonalScheduleSheet(context: context, teamId: currentTeamId, myId: user?.id ?? 'me', myName: user?.name ?? '관리자', initial: e.raw);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: TextStyle(color: e.type == _EventType.task && e.isDone ? AppColors.muted : AppColors.text, fontWeight: FontWeight.w900, fontSize: 15, decoration: e.type == _EventType.task && e.isDone ? TextDecoration.lineThrough : null)), const SizedBox(height: 4), Text(e.subtitle, style: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w700, fontSize: 12))])),
          if (e.type == _EventType.task) Text(e.emoji, style: const TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Future<void> _showPersonalScheduleSheet({required BuildContext context, required String teamId, required String myId, required String myName, Map<String, dynamic>? initial}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PersonalScheduleSheetContent(teamId: teamId, myId: myId, myName: myName, initial: initial),
    );
  }
}

class _PersonalScheduleSheetContent extends StatefulWidget {
  final String teamId, myId, myName;
  final Map<String, dynamic>? initial;
  const _PersonalScheduleSheetContent({required this.teamId, required this.myId, required this.myName, this.initial});
  @override
  State<_PersonalScheduleSheetContent> createState() => _PersonalScheduleSheetContentState();
}

class _PersonalScheduleSheetContentState extends State<_PersonalScheduleSheetContent> {
  late TextEditingController _titleCtrl, _noteCtrl;
  late DateTimeRange _range;
  late bool _isAllDay;
  @override
  void initState() {
    super.initState();
    final scheduleProv = context.read<ScheduleProvider>();
    _titleCtrl = TextEditingController(text: (widget.initial?['title'] ?? '').toString());
    _noteCtrl = TextEditingController(text: (widget.initial?['note'] ?? '').toString());
    _range = widget.initial != null && scheduleProv.getRange(widget.initial!) != null ? scheduleProv.getRange(widget.initial!)! : DateTimeRange(start: DateTime.now(), end: DateTime.now());
    _isAllDay = (widget.initial?['isAllDay'] ?? true) == true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('계획 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            cursorColor: AppColors.primary,
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              hintText: '계획 제목',
              hintStyle: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w700),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: _range);
                if (picked != null) {
                  if (!mounted) return;
                  setState(() => _range = picked);
                }
              },
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Row(children: [const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8), const Text('기간', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text2)), const Spacer(), Text('${DateFormat('yy.MM.dd').format(_range.start)} ~ ${DateFormat('yy.MM.dd').format(_range.end)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary))]))),
          const SizedBox(height: 12),
          Row(children: [
            const Text('종일', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text2)),
            const Spacer(),
            Switch(value: _isAllDay, activeColor: AppColors.primary, onChanged: (v) => setState(() => _isAllDay = v)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            cursorColor: AppColors.primary,
            maxLines: 3,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: '메모(선택)',
              hintStyle: const TextStyle(color: AppColors.hint, fontWeight: FontWeight.w700),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                  onPressed: () async {
                    final scheduleProv = context.read<ScheduleProvider>();
                    final title = _titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    if (widget.initial != null) {
                      await scheduleProv.update(id: widget.initial!['id'], title: title, note: _noteCtrl.text, range: _range, isAllDay: _isAllDay);
                    } else {
                      await scheduleProv.add(teamId: widget.teamId, userId: widget.myId, userName: widget.myName, title: title, note: _noteCtrl.text, range: _range, isAllDay: _isAllDay);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))))
        ]),
      ),
    );
  }
}

enum _EventType { task, personal }

class _CalendarEvent {
  final _EventType type;
  final String id, title, subtitle, emoji, note;
  final bool isDone;
  final Task? task;
  final Map<String, dynamic>? raw;
  final DateTimeRange? range;
  const _CalendarEvent._({required this.type, required this.id, required this.title, required this.subtitle, required this.emoji, required this.isDone, required this.note, required this.task, required this.raw, this.range});
  factory _CalendarEvent.task({required String id, required String title, required String subtitle, required String emoji, required bool isDone, required Task task, DateTimeRange? range}) => _CalendarEvent._(type: _EventType.task, id: id, title: title, subtitle: subtitle, emoji: emoji, isDone: isDone, note: '', task: task, raw: null, range: range);
  factory _CalendarEvent.personal({required String id, required String title, required String subtitle, required String note, required Map<String, dynamic> raw, DateTimeRange? range}) => _CalendarEvent._(type: _EventType.personal, id: id, title: title, subtitle: subtitle, emoji: '', isDone: false, note: note, task: null, raw: raw, range: range);
}

bool _rangeContainsDay(DateTimeRange r, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  final s = DateTime(r.start.year, r.start.month, r.start.day);
  final e = DateTime(r.end.year, r.end.month, r.end.day);
  return !d.isBefore(s) && !d.isAfter(e);
}

bool isSameDay(DateTime? a, DateTime? b) => a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

String _rangeText(DateTimeRange r) {
  final s = DateFormat('yy.MM.dd').format(r.start);
  final e = DateFormat('yy.MM.dd').format(r.end);
  return s == e ? s : '$s~$e';
}
