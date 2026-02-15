import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:worknote/features/tasks/state/task_provider.dart';
import 'package:worknote/features/team/state/team_provider.dart';
import 'package:worknote/features/auth/state/auth_provider.dart';

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
    final myId = authProv.currentUser?.id;
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId, myId: myId);

    final selectedTasks = tasks.where((t) {
      if (_selectedDay == null) return false;
      return isSameDay(t.dueDate, _selectedDay);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // 마스터피스 화이트 배경
      body: Column(
        children: [
          // 1. 캘린더 카드 (단단한 화이트 & 딥 섀도우)
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: TableCalendar(
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
              eventLoader: (day) {
                return tasks.where((t) => isSameDay(t.dueDate, day)).toList();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900),
                selectedDecoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                defaultTextStyle: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
                weekendTextStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),

          // 2. 해당 날짜 업무 리스트 (컴팩트 카드)
          Expanded(
            child: selectedTasks.isEmpty
                ? Center(child: Text(_selectedDay == null ? "날짜를 선택해 주세요" : "일정이 없습니다.", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: task.isDone ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(task.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, 
                              color: task.isDone ? Colors.green : Colors.grey, size: 24),
                            const SizedBox(width: 12),
                            Expanded(child: Text(task.title, style: TextStyle(
                              color: task.isDone ? Colors.grey : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900, fontSize: 15,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                            ))),
                            Text(task.assigneeEmoji, style: const TextStyle(fontSize: 20)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
