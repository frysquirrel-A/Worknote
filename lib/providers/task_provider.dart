import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Project> _projects = [];

  // 필터 상태 관리
  String _projectIdFilter = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter;
  DateFilter _dateFilter = DateFilter.all;
  String _memberFilter = 'all';
  String _sortBy = 'created';

  // Getter
  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;
  String get projectIdFilter => _projectIdFilter;
  String get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  DateFilter get dateFilter => _dateFilter;
  String get memberFilter => _memberFilter;
  String get sortBy => _sortBy;

  // 1. 데이터 로드 (앱 시작 시 호출)
  Future<void> loadData() async {
    var taskBox = Hive.box<Task>('tasks');
    var projectBox = Hive.box<Project>('projects');

    _tasks = taskBox.values.toList();
    _projects = projectBox.values.toList();

    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // [핵심] 시스템 초기화 및 샘플 데이터 강제 주입
  Future<void> resetSystem(String currentTeamId) async {
    var taskBox = Hive.box<Task>('tasks');
    var projectBox = Hive.box<Project>('projects');

    // 1. 싹 비우기
    await taskBox.clear();
    await projectBox.clear();
    _tasks.clear();
    _projects.clear();
    notifyListeners();

    // 2. 현재 팀 ID에 맞춘 샘플 생성
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
      Task(
        id: const Uuid().v4(), teamId: currentTeamId, title: "지난주 보고 완료",
        assigneeId: 'me', assigneeName: '나', assigneeEmoji: '👷',
        projectId: 'p2', createdAt: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        priority: TaskPriority.low, isDone: true,
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // 3. 로컬 DB 저장
    for (var p in dummyProjects) await projectBox.put(p.id, p);
    for (var t in dummyTasks) await taskBox.put(t.id, t);

    // 4. 메모리 적재 및 UI 갱신
    _projects = dummyProjects;
    _tasks = dummyTasks;
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    notifyListeners();
  }

  // 필터 및 정렬 UI 연동
  List<Task> getFilteredTasks(String currentTeamId) {
    List<Task> filtered = _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      if (_projectIdFilter != 'all') {
        if (_projectIdFilter == 'none' && t.projectId != null) return false;
        if (_projectIdFilter != 'none' && t.projectId != _projectIdFilter) return false;
      }
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      if (_memberFilter != 'all' && t.assigneeId != _memberFilter) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'due') return a.dueDate.compareTo(b.dueDate);
      if (_sortBy == 'priority') return a.priority.index.compareTo(b.priority.index);
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  void setFilter({String? projectId, String? status, TaskPriority? priority, DateFilter? date, String? member, String? sort}) {
    if (projectId != null) _projectIdFilter = projectId;
    if (status != null) _statusFilter = status;
    if (priority != null || priority == null) _priorityFilter = priority; 
    if (date != null) _dateFilter = date;
    if (member != null) _memberFilter = member;
    if (sort != null) _sortBy = sort;
    notifyListeners();
  }

  // 기존 CRUD 로직들...
  Future<void> addTask(Task t) async { await Hive.box<Task>('tasks').put(t.id, t); _tasks.add(t); _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt)); notifyListeners(); }
  Future<void> updateTaskStatus(Task t, bool done) async { t.isDone = done; t.completedAt = done ? DateTime.now() : null; await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
  Future<void> deleteTask(String id) async { await Hive.box<Task>('tasks').delete(id); _tasks.removeWhere((t) => t.id == id); notifyListeners(); }
  Future<void> cycleTaskPriority(Task t) async { t.priority = TaskPriority.values[(t.priority.index + 1) % 4]; await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
  Future<void> addProject(Project p) async { await Hive.box<Project>('projects').put(p.id, p); _projects.add(p); notifyListeners(); }
  Color getRandomProjectColor() => Colors.primaries[DateTime.now().millisecond % Colors.primaries.length];
}