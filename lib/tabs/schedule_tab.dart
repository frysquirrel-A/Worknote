import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/team_provider.dart';
import '../models.dart';

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
    final tasks = taskProv.getFilteredTasks(teamProv.currentTeamId);

    // [Logic] 선택된 날짜의 업무들 필터링
    final selectedTasks = tasks.where((t) {
      if (_selectedDay == null) return false;
      return isSameDay(t.dueDate, _selectedDay);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. 캘린더 카드
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              // [Event Dot] 업무가 있는 날 점 표시
              eventLoader: (day) {
                return tasks.where((t) => isSameDay(t.dueDate, day)).toList();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.3), shape: BoxShape.circle),
                selectedDecoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
          ),

          // 2. 선택된 날짜 업무 리스트
          Expanded(
            child: selectedTasks.isEmpty
                ? Center(child: Text(_selectedDay == null ? "날짜를 선택해 주세요" : "선택한 날짜에 업무가 없습니다.", style: const TextStyle(color: Colors.white24)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(task.isDone ? Icons.check_circle : Icons.circle_outlined, color: task.isDone ? Colors.green : Colors.grey),
                            const SizedBox(width: 16),
                            Expanded(child: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Text(task.assigneeEmoji),
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