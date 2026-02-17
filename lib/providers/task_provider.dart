import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
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
  List<Task> getFilteredTasks(String currentTeamId) {
    return _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      if (_projectIdFilter != 'all' && t.projectId != _projectIdFilter) return false;
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      if (_assigneeFilter != 'all' && t.assigneeId != _assigneeFilter) return false;
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

  // --- 일정(Schedule) 관련 메타 데이터 처리 ---

  /// 업무 메타 데이터 저장을 위한 untyped 박스
  Box get _metaBox => Hive.box('task_meta');

  bool isIncludedInSchedule(String taskId) {
    if (!Hive.isBoxOpen('task_meta')) return false;
    final raw = _metaBox.get(taskId);
    if (raw is Map) return raw['includeInSchedule'] == true;
    return false; 
  }

  DateTimeRange? effectiveScheduleRange(Task task) {
    if (!Hive.isBoxOpen('task_meta')) return null;
    final raw = _metaBox.get(task.id);
    if (raw is Map) {
      final start = DateTime.tryParse((raw['scheduleStart'] ?? '').toString());
      final end = DateTime.tryParse((raw['scheduleEnd'] ?? '').toString());
      if (start != null && end != null) return DateTimeRange(start: start, end: end);
    }
    return null;
  }

  Future<void> setScheduleOptions({
    required String taskId,
    required bool includeInSchedule,
    DateTimeRange? range,
  }) async {
    // 저장 시에도 박스 오픈 확인 (안전장치)
    if (!Hive.isBoxOpen('task_meta')) await Hive.openBox('task_meta');

    await _metaBox.put(taskId, {
      'includeInSchedule': includeInSchedule,
      'scheduleStart': range?.start.toIso8601String(),
      'scheduleEnd': range?.end.toIso8601String(),
    });
    notifyListeners();
  }
}
