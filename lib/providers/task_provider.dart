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

  void setProjectIdFilter(String? id) { if (id != null) _projectIdFilter = id; notifyListeners(); }
  void setStatusFilter(String? status) { if (status != null) _statusFilter = status; notifyListeners(); }
  void setPriorityFilter(TaskPriority? priority) { _priorityFilter = priority; notifyListeners(); }
  void setDateFilter(DateFilter? date) { if (date != null) _dateFilter = date; notifyListeners(); }
  void setAssigneeFilter(String? id) { if (id != null) _assigneeFilter = id; notifyListeners(); }

  Future<void> loadData() async {
    _tasks = Hive.box<Task>('tasks').values.toList();
    _projects = Hive.box<Project>('projects').values.toList();
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // [3-1 수리] 프로젝트 없음 버그 및 작성일 기간 필터 강화
  List<Task> getFilteredTasks(String currentTeamId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      
      // 2) 프로젝트 필터 수리
      if (_projectIdFilter != 'all') {
        if (_projectIdFilter == 'none') {
          if (t.projectId != null && t.projectId != 'none') return false;
        } else {
          if (t.projectId != _projectIdFilter) return false;
        }
      }

      // 3) 상태/우선순위 유지
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;

      // 4) 담당자 필터 수리 (다중 담당자 포함)
      if (_assigneeFilter != 'all') {
        final bool isSingleMatch = t.assigneeId == _assigneeFilter;
        final bool isMultiMatch = t.assigneeIds.contains(_assigneeFilter);
        if (!isSingleMatch && !isMultiMatch) return false;
      }

      // 5) 작성일(createdAt) 기준 기간 필터 적용
      if (_dateFilter != DateFilter.all) {
        if (_dateFilter == DateFilter.today) {
          if (t.createdAt.isBefore(todayStart)) return false;
        } else if (_dateFilter == DateFilter.week) {
          if (t.createdAt.isBefore(now.subtract(const Duration(days: 7)))) return false;
        } else if (_dateFilter == DateFilter.twoWeeks) {
          if (t.createdAt.isBefore(now.subtract(const Duration(days: 14)))) return false;
        } else if (_dateFilter == DateFilter.oneMonth) {
          if (t.createdAt.isBefore(now.subtract(const Duration(days: 30)))) return false;
        }
      }
      
      return true;
    }).toList();
  }

  String getProjectName(String id) {
    if (id == 'all') return "전체";
    if (id == 'none') return "없음";
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
