import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/domain/models.dart';

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

  // [수정] 각 필터 독립 함수 (간섭 방지)
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

  // [수정] 필터링 로직 강화
  List<Task> getFilteredTasks(String currentTeamId, {String? myId}) {
    return _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;

      // 프로젝트
      if (_projectIdFilter != 'all') {
        if (_projectIdFilter == 'none') {
          if (t.projectId != null) return false;
        } else {
          if (t.projectId != _projectIdFilter) return false;
        }
      }

      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;

      // 담당자
      if (_assigneeFilter != 'all') {
        final filterId = (_assigneeFilter == 'me') ? (myId ?? 'me') : _assigneeFilter;
        final hitSingle = t.assigneeId == filterId;
        final hitMulti = t.assigneeIds.contains(filterId);
        if (!hitSingle && !hitMulti) return false;
      }

      // 작성일 기간 필터
      final now = DateTime.now();
      DateTime? from;
      switch (_dateFilter) {
        case DateFilter.all:
          from = null;
          break;
        case DateFilter.today:
          from = DateTime(now.year, now.month, now.day);
          break;
        case DateFilter.week:
          from = now.subtract(const Duration(days: 7));
          break;
        case DateFilter.twoWeeks:
          from = now.subtract(const Duration(days: 14));
          break;
        case DateFilter.oneMonth:
          from = now.subtract(const Duration(days: 30));
          break;
      }
      if (from != null && t.createdAt.isBefore(from)) return false;

      return true;
    }).toList();
  }

  // [수정] 프로젝트 ID -> 이름 변환 헬퍼
  String getProjectName(String? id) {
    if (id == null || id == 'none') return "없음";
    if (id == 'all') return "전체";
    return _projects.firstWhere((p) => p.id == id, orElse: () => Project(id: '', teamId: '', name: '알 수 없음', colorValue: 0)).name;
  }

  // CRUD...
  Future<void> addTask(Task t) async { await Hive.box<Task>('tasks').put(t.id, t); _tasks.add(t); notifyListeners(); }
  Future<void> updateTaskStatus(Task t, bool done) async { t.isDone = done; t.completedAt = done ? DateTime.now() : null; t.updatedAt = DateTime.now(); await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
  Future<void> deleteTask(String id) async { await Hive.box<Task>('tasks').delete(id); _tasks.removeWhere((t) => t.id == id); notifyListeners(); }
  Future<void> cycleTaskPriority(Task t) async { int next = (t.priority.index + 1) % 4; t.priority = TaskPriority.values[next]; await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
  Future<void> addProject(Project p) async { await Hive.box<Project>('projects').put(p.id, p); _projects.add(p); notifyListeners(); }
}
