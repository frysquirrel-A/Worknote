import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:worknote/core/ui/app_palette.dart';
import 'package:worknote/core/ui/widgets/empty_state_placeholder.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';
import 'package:worknote/features/schedule/state/schedule_provider.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/tasks/ui/sheets/task_detail_sheet.dart';
import 'package:worknote/features/team/state/team_provider.dart';

const _weekdayLabels = <String>['일', '월', '화', '수', '목', '금', '토'];

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _searchQuery = '';
  bool _isCompactCalendar = false;
  bool _showAllTeams = false;

  @override
  Widget build(BuildContext context) {
    final taskProv = context.watch<TaskProvider>();
    final teamProv = context.watch<TeamProvider>();
    final authProv = context.watch<AuthProvider>();
    final scheduleProv = context.watch<ScheduleProvider>();

    final myId = authProv.currentUser?.id ?? 'me';
    final myName = authProv.currentUser?.name ?? '관리자';
    final currentTeamId = teamProv.currentTeamId;
    final query = _searchQuery.trim().toLowerCase();

    final taskEvents = taskProv.tasks.where((task) {
      if (!_showAllTeams && task.teamId != currentTeamId) return false;
      if (!taskProv.isIncludedInSchedule(task.id)) return false;
      return query.isEmpty || task.title.toLowerCase().contains(query);
    }).toList();

    final personalEvents = scheduleProv.itemsForTeam(null).where((item) {
      final itemTeamId = (item['teamId'] ?? '').toString();
      if (!_showAllTeams && itemTeamId != currentTeamId) return false;
      if (query.isEmpty) return true;
      final title = (item['title'] ?? '').toString().toLowerCase();
      final note = (item['note'] ?? '').toString().toLowerCase();
      return title.contains(query) || note.contains(query);
    }).toList();

    final selectedEvents = _selectedDay == null
        ? const <_CalendarEvent>[]
        : _eventsForDay(
            day: _selectedDay!,
            tasks: taskEvents,
            personal: personalEvents,
            taskProv: taskProv,
            scheduleProv: scheduleProv,
          );

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '일정',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonalScheduleSheet(
          context: context,
          teamId: currentTeamId,
          myId: myId,
          myName: myName,
        ),
        backgroundColor: AppColors.premiumBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('계획 추가', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          cursorColor: AppColors.premiumBlue,
                          style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: '계획을 검색하세요...',
                            hintStyle: const TextStyle(color: AppColors.darkHint, fontWeight: FontWeight.w700),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.premiumBlue),
                            filled: true,
                            fillColor: AppColors.darkSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.darkBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: AppColors.premiumBlue, width: 1.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _modeToggleButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: const Text('모든 팀 일정 보기', style: TextStyle(fontWeight: FontWeight.w700)),
                      selected: _showAllTeams,
                      onSelected: (value) => setState(() => _showAllTeams = value),
                      selectedColor: AppColors.premiumBlue.withValues(alpha: 0.16),
                      checkmarkColor: AppColors.premiumBlue,
                      backgroundColor: AppColors.darkSurface,
                      side: const BorderSide(color: AppColors.darkBorder),
                      labelStyle: TextStyle(
                        color: _showAllTeams ? AppColors.darkText : AppColors.darkHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildCalendar(
              tasks: taskEvents,
              personal: personalEvents,
              taskProv: taskProv,
              scheduleProv: scheduleProv,
            ),
            if (selectedEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: EmptyStatePlaceholder(
                  icon: _selectedDay == null ? Icons.calendar_month_outlined : Icons.event_busy_outlined,
                  title: _selectedDay == null ? '날짜를 선택해 주세요' : '계획이 없어요',
                  description: _selectedDay == null
                      ? '캘린더에서 날짜를 탭하면 팀 계획과 개인 일정을 함께 확인할 수 있어요.'
                      : '선택한 날짜에는 등록된 계획이 아직 없습니다.',
                  compact: true,
                  dark: true,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                itemCount: selectedEvents.length,
                itemBuilder: (context, index) => _eventTile(context: context, event: selectedEvents[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeToggleButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _isCompactCalendar = !_isCompactCalendar),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(
          _isCompactCalendar ? Icons.view_headline_rounded : Icons.calendar_view_month_rounded,
          color: AppColors.premiumBlue,
        ),
      ),
    );
  }

  Widget _buildCalendar({
    required List<Task> tasks,
    required List<Map<String, dynamic>> personal,
    required TaskProvider taskProv,
    required ScheduleProvider scheduleProv,
  }) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final startDay = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    final endDay = lastDayOfMonth.add(Duration(days: (6 - lastDayOfMonth.weekday) % 7));

    final rows = <TableRow>[
      TableRow(
        children: _weekdayLabels.map((label) {
          final color = label == '일'
              ? AppColors.destructive
              : label == '토'
                  ? AppColors.premiumBlue
                  : AppColors.darkHint;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
            ),
          );
        }).toList(),
      ),
    ];

    var cursor = startDay;
    while (cursor.isBefore(endDay) || isSameDay(cursor, endDay)) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        final day = cursor;
        final events = _eventsForDay(
          day: day,
          tasks: tasks,
          personal: personal,
          taskProv: taskProv,
          scheduleProv: scheduleProv,
        )..sort((a, b) {
            final startCompare = a.range.start.compareTo(b.range.start);
            if (startCompare != 0) return startCompare;
            return b.range.duration.inDays.compareTo(a.range.duration.inDays);
          });
        cells.add(_calendarDayCell(day: day, events: events));
        cursor = cursor.add(const Duration(days: 1));
      }
      rows.add(TableRow(children: cells));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        gradient: AppGradients.messengerPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  DateFormat('yyyy년 MM월').format(_focusedDay),
                  style: const TextStyle(color: AppColors.darkText, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                _calendarArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                ),
                _calendarArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  }),
                  child: const Text('오늘', style: TextStyle(color: AppColors.premiumBlue, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
              6: FlexColumnWidth(),
            },
            children: rows,
          ),
        ],
      ),
    );
  }

  Widget _calendarArrowButton({required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.premiumBlue),
      ),
    );
  }

  Widget _calendarDayCell({required DateTime day, required List<_CalendarEvent> events}) {
    final isSelected = _selectedDay != null && isSameDay(_selectedDay, day);
    final isToday = isSameDay(DateTime.now(), day);
    final isOutsideMonth = day.month != _focusedDay.month;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        constraints: BoxConstraints(minHeight: _isCompactCalendar ? 76 : 108),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.premiumBlue.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.55), width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: isToday
                    ? const BoxDecoration(color: AppColors.premiumBlue, shape: BoxShape.circle)
                    : null,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday
                        ? Colors.white
                        : isOutsideMonth
                            ? AppColors.darkHint.withValues(alpha: 0.45)
                            : day.weekday == DateTime.sunday
                                ? AppColors.destructive
                                : day.weekday == DateTime.saturday
                                    ? AppColors.premiumBlue
                                    : AppColors.darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: events.take(4).map((event) {
                  final color = event.type == _EventType.task ? AppColors.premiumBlue : AppColors.warning;
                  final isSingleDay = isSameDay(event.range.start, event.range.end);
                  final isStart = isSameDay(event.range.start, day);
                  final isEnd = isSameDay(event.range.end, day);

                  if (_isCompactCalendar) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      child: Center(
                        child: isSingleDay
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              )
                            : Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                      ),
                    );
                  }

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: 3,
                      left: (isSingleDay || isStart) ? 4 : 0,
                      right: (isSingleDay || isEnd) ? 4 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.horizontal(
                        left: (isSingleDay || isStart) ? const Radius.circular(4) : Radius.zero,
                        right: (isSingleDay || isEnd) ? const Radius.circular(4) : Radius.zero,
                      ),
                    ),
                    child: (isSingleDay || isStart || day.weekday == DateTime.sunday)
                        ? Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          )
                        : const SizedBox(height: 11),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
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
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final events = <_CalendarEvent>[];

    for (final task in tasks) {
      final range = taskProv.effectiveScheduleRange(task);
      if (range == null || !_rangeContainsDay(range, normalizedDay)) continue;
      events.add(
        _CalendarEvent.task(
          id: task.id,
          title: task.title,
          subtitle: _rangeText(range),
          emoji: task.assigneeEmoji,
          isDone: task.isDone,
          task: task,
          range: range,
        ),
      );
    }

    for (final item in personal) {
      final range = scheduleProv.getRange(item);
      if (range == null || !_rangeContainsDay(range, normalizedDay)) continue;
      events.add(
        _CalendarEvent.personal(
          id: (item['id'] ?? '').toString(),
          title: (item['title'] ?? '').toString(),
          subtitle: _rangeText(range),
          note: (item['note'] ?? '').toString(),
          raw: item,
          range: range,
        ),
      );
    }

    return events;
  }

  Widget _eventTile({required BuildContext context, required _CalendarEvent event}) {
    final icon = event.type == _EventType.task
        ? Icons.check_circle_outline_rounded
        : Icons.event_note_rounded;
    final accentColor = event.type == _EventType.task
        ? AppColors.premiumBlue
        : AppColors.warning;

    return GestureDetector(
      onTap: () {
        if (event.type == _EventType.task && event.task != null) {
          showTaskDetailSheet(context: context, task: event.task!);
          return;
        }

        final user = context.read<AuthProvider>().currentUser;
        final currentTeamId = context.read<TeamProvider>().currentTeamId;
        _showPersonalScheduleSheet(
          context: context,
          teamId: currentTeamId,
          myId: user?.id ?? 'me',
          myName: user?.name ?? '사용자',
          initial: event.raw,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: event.type == _EventType.task && event.isDone
                          ? AppColors.darkHint
                          : AppColors.darkText,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      decoration: event.type == _EventType.task && event.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: const TextStyle(
                      color: AppColors.darkHint,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (event.type == _EventType.task)
              Text(event.emoji.isEmpty ? '🙂' : event.emoji, style: const TextStyle(fontSize: 20)),
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersonalScheduleSheetContent(
        teamId: teamId,
        myId: myId,
        myName: myName,
        initial: initial,
      ),
    );
  }
}

class _PersonalScheduleSheetContent extends StatefulWidget {
  const _PersonalScheduleSheetContent({
    required this.teamId,
    required this.myId,
    required this.myName,
    this.initial,
  });

  final String teamId;
  final String myId;
  final String myName;
  final Map<String, dynamic>? initial;

  @override
  State<_PersonalScheduleSheetContent> createState() => _PersonalScheduleSheetContentState();
}

class _PersonalScheduleSheetContentState extends State<_PersonalScheduleSheetContent> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late DateTimeRange _range;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();
    final scheduleProv = context.read<ScheduleProvider>();
    _titleCtrl = TextEditingController(text: (widget.initial?['title'] ?? '').toString());
    _noteCtrl = TextEditingController(text: (widget.initial?['note'] ?? '').toString());
    _range = widget.initial != null && scheduleProv.getRange(widget.initial!) != null
        ? scheduleProv.getRange(widget.initial!)!
        : DateTimeRange(start: DateTime.now(), end: DateTime.now());
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
    final isEditing = widget.initial != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.messengerPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? '계획 수정' : '계획 추가',
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              cursorColor: AppColors.premiumBlue,
              style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900),
              decoration: _darkInputDecoration('계획 제목'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: _range,
                );
                if (picked != null && mounted) {
                  setState(() => _range = picked);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18, color: AppColors.premiumBlue),
                    const SizedBox(width: 8),
                    const Text(
                      '기간',
                      style: TextStyle(color: AppColors.darkHint, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Text(
                      '${DateFormat('yy.MM.dd').format(_range.start)} ~ ${DateFormat('yy.MM.dd').format(_range.end)}',
                      style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '종일',
                  style: TextStyle(color: AppColors.darkHint, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Switch(
                  value: _isAllDay,
                  activeThumbColor: AppColors.premiumBlue,
                  onChanged: (value) => setState(() => _isAllDay = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              cursorColor: AppColors.premiumBlue,
              maxLines: 3,
              style: const TextStyle(color: AppColors.darkText),
              decoration: _darkInputDecoration('메모(선택)'),
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
                    await scheduleProv.update(
                      id: widget.initial!['id'],
                      title: title,
                      note: _noteCtrl.text,
                      range: _range,
                      isAllDay: _isAllDay,
                    );
                  } else {
                    await scheduleProv.add(
                      teamId: widget.teamId,
                      userId: widget.myId,
                      userName: widget.myName,
                      title: title,
                      note: _noteCtrl.text,
                      range: _range,
                      isAllDay: _isAllDay,
                    );
                  }

                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.premiumBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _darkInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.darkHint, fontWeight: FontWeight.w700),
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.premiumBlue, width: 1.8),
      ),
    );
  }
}

enum _EventType { task, personal }

class _CalendarEvent {
  const _CalendarEvent._({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.isDone,
    required this.note,
    required this.task,
    required this.raw,
    required this.range,
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
      task: task,
      raw: null,
      range: range,
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
      task: null,
      raw: raw,
      range: range,
    );
  }

  final _EventType type;
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final bool isDone;
  final String note;
  final Task? task;
  final Map<String, dynamic>? raw;
  final DateTimeRange range;
}

bool _rangeContainsDay(DateTimeRange range, DateTime day) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day);
  return !normalizedDay.isBefore(start) && !normalizedDay.isAfter(end);
}

bool isSameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

String _rangeText(DateTimeRange range) {
  final start = DateFormat('yy.MM.dd').format(range.start);
  final end = DateFormat('yy.MM.dd').format(range.end);
  return start == end ? start : '$start ~ $end';
}
