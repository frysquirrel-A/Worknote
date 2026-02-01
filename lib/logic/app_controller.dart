import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../data/app_database.dart';

class AppController extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();
  File? _profileImage;

  AppController() {
    _db.initSamples();
  }

  // 외부에서 강제로 리스너를 호출할 수 있게 public 메소드 추가
  void refresh() => notifyListeners();

  // --- Getters ---
  List<Project> get projects => _db.projects;
  List<TeamMember> get members => _db.members;
  List<Task> get tasks => _db.tasks;
  List<JournalEntry> get journals => _db.journals;
  File? get profileImage => _profileImage;

  // --- UI States ---
  String taskProjectId = 'all';
  String taskStatusFilter = '전체';
  TaskPriority? taskPriorityFilter;
  DateFilter taskDateFilter = DateFilter.all;
  
  String journalSearchQuery = '';
  JournalGroupPeriod journalGroupPeriod = JournalGroupPeriod.day;
  String journalMemberFilterId = 'all';

  // --- Logic: Filtered Tasks ---
  List<Task> get filteredTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _db.tasks.where((t) {
      if (taskProjectId != 'all' && t.projectId != taskProjectId) return false;
      if (taskStatusFilter == '진행 중' && t.isDone) return false;
      if (taskStatusFilter == '완료됨' && !t.isDone) return false;
      if (taskPriorityFilter != null && t.priority != taskPriorityFilter) return false;
      
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      if (taskDateFilter == DateFilter.today && !taskDate.isAtSameMomentAs(today)) return false;
      if (taskDateFilter == DateFilter.week && t.dueDate.isAfter(today.add(const Duration(days: 7)))) return false;
      if (taskDateFilter == DateFilter.twoWeeks && t.dueDate.isAfter(today.add(const Duration(days: 14)))) return false;
      if (taskDateFilter == DateFilter.oneMonth && t.dueDate.isAfter(today.add(const Duration(days: 30)))) return false;
      
      return true;
    }).toList();
  }

  // --- Logic: Grouped Journals ---
  Map<String, List<JournalEntry>> get groupedJournals {
    final filtered = _db.journals.where((j) {
      bool canSee = !j.isPrivate || j.userId == 'me';
      bool matchesSearch = j.title.contains(journalSearchQuery) || j.content.contains(journalSearchQuery);
      bool matchesMember = journalMemberFilterId == 'all' || j.userId == journalMemberFilterId;
      return canSee && matchesSearch && matchesMember;
    }).toList();

    final groups = <String, List<JournalEntry>>{};
    for (var j in filtered) {
      String key = _getJournalGroupKey(j.date, journalGroupPeriod);
      groups.putIfAbsent(key, () => []).add(j);
    }
    return groups;
  }

  String _getJournalGroupKey(DateTime d, JournalGroupPeriod p) {
    if (p == JournalGroupPeriod.day) return DateFormat('yyyy-MM-dd').format(d);
    if (p == JournalGroupPeriod.month) return DateFormat('yyyy-MM').format(d);
    return DateFormat('yyyy년').format(d);
  }

  // --- Actions ---
  void updateProfileImage(File file) {
    _profileImage = file;
    notifyListeners();
  }

  void setTaskFilter({String? projectId, String? status, TaskPriority? priority, DateFilter? date}) {
    if (projectId != null) taskProjectId = projectId;
    if (status != null) taskStatusFilter = status;
    if (priority != null) taskPriorityFilter = priority;
    if (date != null) taskDateFilter = date;
    notifyListeners();
  }

  void updateTaskStatus(Task task, bool isDone) {
    task.isDone = isDone;
    task.completedAt = isDone ? DateTime.now() : null;
    task.updatedAt = DateTime.now();
    notifyListeners();
  }

  void cycleTaskPriority(Task task) {
    task.priority = TaskPriority.values[(task.priority.index + 1) % 4];
    task.updatedAt = DateTime.now();
    notifyListeners();
  }

  Color getRandomProjectColor() {
    final colors = [Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.teal, Colors.indigo, Colors.pink];
    return colors[Random().nextInt(colors.length)];
  }

  void addTask(Task t) { _db.tasks.add(t); notifyListeners(); }
  void addProject(Project p) { _db.projects.add(p); notifyListeners(); }
  void addJournal(JournalEntry e) { _db.journals.insert(0, e); notifyListeners(); }
  
  void updateJournal(String id, String title, String content, String? projectId, bool isPrivate, List<String> photos) {
    final index = _db.journals.indexWhere((j) => j.id == id);
    if (index != -1) {
      final old = _db.journals[index];
      _db.journals[index] = JournalEntry(
        id: old.id, userId: old.userId, userName: old.userName,
        title: title, content: content, projectId: projectId,
        date: old.date, updatedAt: DateTime.now(), photos: photos, isPrivate: isPrivate,
      );
      notifyListeners();
    }
  }
}
