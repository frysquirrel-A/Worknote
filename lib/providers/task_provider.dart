import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Project> _projects = [];

  // 5대 필터 상태
  String _projectIdFilter = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter;
  DateFilter _dateFilter = DateFilter.all;
  String _memberFilter = 'all';
  String _sortBy = 'created';

  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;
  String get projectIdFilter => _projectIdFilter;
  String get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  DateFilter get dateFilter => _dateFilter;
  String get memberFilter => _memberFilter;
  String get sortBy => _sortBy;

  Future<void> loadData() async {
    var taskBox = Hive.box<Task>('tasks');
    var projectBox = Hive.box<Project>('projects');
    _tasks = taskBox.values.toList();
    _projects = projectBox.values.toList();
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> resetSystem(String currentTeamId) async {
    var taskBox = Hive.box<Task>('tasks');
    var projectBox = Hive.box<Project>('projects');
    await taskBox.clear();
    await projectBox.clear();
    _tasks.clear();
    _projects.clear();

    final dummyProjects = [
      Project(id: 'p1', teamId: currentTeamId, name: '골조 공사', colorValue: 0xFFEF5350),
      Project(id: 'p2', teamId: currentTeamId, name: '전기 배선', colorValue: 0xFF42A5F5),
    ];
    final dummyTasks = [
      Task(
        id: const Uuid().v4(), teamId: currentTeamId, title: "현장 안전 점검 (샘플)",
        assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
        projectId: 'p1', createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        priority: TaskPriority.high, isDone: false,
      ),
      Task(
        id: const Uuid().v4(), teamId: currentTeamId, title: "자재 발주 확인 (샘플)",
        assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
        projectId: null, createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        priority: TaskPriority.medium, isDone: false,
      ),
    ];

    for (var p in dummyProjects) await projectBox.put(p.id, p);
    for (var t in dummyTasks) await taskBox.put(t.id, t);
    _projects = dummyProjects;
    _tasks = dummyTasks;
    notifyListeners();
  }

  // [수정] 5가지 복합 필터 로직 완성
  List<Task> getFilteredTasks(String currentTeamId) {
    return _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      
      // 1. 프로젝트 필터
      if (_projectIdFilter != 'all') {
        if (_projectIdFilter == 'none' && t.projectId != null) return false;
        if (_projectIdFilter != 'none' && t.projectId != _projectIdFilter) return false;
      }
      // 2. 상태 필터
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      // 3. 중요도 필터
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      // 4. 작성자 필터
      if (_memberFilter != 'all' && t.assigneeId != _memberFilter) return false;
      // 5. 기간 필터
      if (_dateFilter != DateFilter.all) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        if (_dateFilter == DateFilter.today && due != today) return false;
        if (_dateFilter == DateFilter.week && t.dueDate.isAfter(today.add(const Duration(days: 7)))) return false;
      }
      return true;
    }).toList();
  }

  void setFilter({String? projectId, String? status, TaskPriority? priority, DateFilter? date, String? member}) {
    if (projectId != null) _projectIdFilter = projectId;
    if (status != null) _statusFilter = status;
    if (priority != null || priority == null) _priorityFilter = priority; 
    if (date != null) _dateFilter = date;
    if (member != null) _memberFilter = member;
    notifyListeners();
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
  Future<void> cycleTaskPriority(Task t) async { t.priority = TaskPriority.values[(t.priority.index + 1) % 4]; await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
  Future<void> addProject(Project p) async { await Hive.box<Project>('projects').put(p.id, p); _projects.add(p); notifyListeners(); }
}
