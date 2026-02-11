import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Project> _projects = [];

  String _projectIdFilter = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter;
  DateFilter _dateFilter = DateFilter.all;
  String _assigneeFilter = 'all';

  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;
  String get projectIdFilter => _projectIdFilter;
  String get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  DateFilter get dateFilter => _dateFilter;
  String get assigneeFilter => _assigneeFilter;

  // [수정] 중요도 필터 해제 로직 보강
  void setProjectIdFilter(String? id) { if (id != null) _projectIdFilter = id; notifyListeners(); }
  void setStatusFilter(String? status) { if (status != null) _statusFilter = status; notifyListeners(); }
  void setPriorityFilter(TaskPriority? priority) { _priorityFilter = priority; notifyListeners(); } // null이면 전체보기
  void setDateFilter(DateFilter? date) { if (date != null) _dateFilter = date; notifyListeners(); }
  void setAssigneeFilter(String? id) { if (id != null) _assigneeFilter = id; notifyListeners(); }

  Future<void> loadData() async {
    _tasks = Hive.box<Task>('tasks').values.toList();
    _projects = Hive.box<Project>('projects').values.toList();
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  List<Task> getFilteredTasks(String currentTeamId) {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      if (_projectIdFilter != 'all' && t.projectId != _projectIdFilter) return false;
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      if (_assigneeFilter != 'all' && t.assigneeId != _assigneeFilter) return false;

      if (_dateFilter != DateFilter.all) {
        final taskDate = t.createdAt;
        if (_dateFilter == DateFilter.today) {
          if (taskDate.year != now.year || taskDate.month != now.month || taskDate.day != now.day) return false;
        } else if (_dateFilter == DateFilter.week) {
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          if (taskDate.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day))) return false;
        } else if (_dateFilter == DateFilter.oneMonth) {
          if (taskDate.year != now.year || taskDate.month != now.month) return false;
        } else if (_dateFilter == DateFilter.twoWeeks) {
          if (taskDate.year != now.year) return false;
        }
      }
      return true;
    }).toList();
  }

  // [수정] 프로젝트 ID를 이름으로 변환 (필터 라벨 표시용)
  String getProjectName(String id) {
    if (id == 'all') return "전체 프로젝트";
    if (id == 'none') return "프로젝트 없음";
    try {
      return _projects.firstWhere((p) => p.id == id).name;
    } catch (e) {
      return "알 수 없음";
    }
  }

  Future<void> addTask(Task t) async { await Hive.box<Task>('tasks').put(t.id, t); _tasks.add(t); notifyListeners(); }
  Future<void> updateTaskStatus(Task t, bool done) async { 
    t.isDone = done; 
    t.completedAt = done ? DateTime.now() : null;
    t.updatedAt = DateTime.now();
    await Hive.box<Task>('tasks').put(t.id, t); 
    notifyListeners(); 
  }
  Future<void> deleteTask(String id) async { await Hive.box<Task>('tasks').delete(id); _tasks.removeWhere((t) => t.id == id); notifyListeners(); }
  Future<void> cycleTaskPriority(Task t) async { int next = (t.priority.index + 1) % 4; t.priority = TaskPriority.values[next]; await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
}
