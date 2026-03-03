import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/domain/models.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider();

  // ---- In-memory data ----
  List<Task> _tasks = [];
  List<Project> _projects = [];

  /// Meta storage for tasks (untyped Hive box).
  static const String _metaBoxName = 'task_meta';

  // ---- Filters ----
  String _projectIdFilter = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter;
  DateFilter _dateFilter = DateFilter.all;
  String _assigneeFilter = 'all';

  // ---- Perf caches ----
  final Map<String, List<Task>> _tasksForTeamCache = {};
  String? _filteredCacheKey;
  List<Task>? _filteredCache;
  final Map<String, double> _projectProgressCache = {};

  // ---- Exposed state ----
  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;

  String get projectIdFilter => _projectIdFilter;
  String get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  DateFilter get dateFilter => _dateFilter;
  String get assigneeFilter => _assigneeFilter;

  // ---- Hive helpers ----
  Box? _metaBoxOrNull() {
    if (Hive.isBoxOpen(_metaBoxName)) return Hive.box(_metaBoxName);
    return null;
  }

  Future<Box> _ensureMetaBox() async {
    if (Hive.isBoxOpen(_metaBoxName)) return Hive.box(_metaBoxName);
    return Hive.openBox(_metaBoxName);
  }

  Future<Box<Task>> _ensureTaskBox() async {
    if (Hive.isBoxOpen('tasks')) return Hive.box<Task>('tasks');
    return Hive.openBox<Task>('tasks');
  }

  Future<Box<Project>> _ensureProjectBox() async {
    if (Hive.isBoxOpen('projects')) return Hive.box<Project>('projects');
    return Hive.openBox<Project>('projects');
  }

  void _invalidateAllCaches() {
    _tasksForTeamCache.clear();
    _filteredCacheKey = null;
    _filteredCache = null;
    _projectProgressCache.clear();
  }

  void _invalidateFilteredCache() {
    _filteredCacheKey = null;
    _filteredCache = null;
  }

  List<Task> tasksForTeam(String teamId) {
    final cached = _tasksForTeamCache[teamId];
    if (cached != null) return cached;
    final list = _tasks.where((t) => t.teamId == teamId).toList();
    _tasksForTeamCache[teamId] = list;
    return list;
  }

  double projectProgress(String projectId, {String? teamId}) {
    final cacheKey = '${teamId ?? '*'}|$projectId';
    final cached = _projectProgressCache[cacheKey];
    if (cached != null) return cached;

    Iterable<Task> list = _tasks;
    if (teamId != null) {
      list = list.where((t) => t.teamId == teamId);
    }
    list = list.where((t) => t.projectId == projectId);

    final items = list.toList();
    if (items.isEmpty) {
      _projectProgressCache[cacheKey] = 0;
      return 0;
    }
    final done = items.where((t) => t.isDone).length;
    final progress = done / items.length;
    _projectProgressCache[cacheKey] = progress;
    return progress;
  }

  void setProjectIdFilter(String? id) {
    final next = id ?? _projectIdFilter;
    if (_projectIdFilter == next) return;
    _projectIdFilter = next;
    _invalidateFilteredCache();
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    final next = status ?? _statusFilter;
    if (_statusFilter == next) return;
    _statusFilter = next;
    _invalidateFilteredCache();
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    if (_priorityFilter == priority) return;
    _priorityFilter = priority;
    _invalidateFilteredCache();
    notifyListeners();
  }

  void setDateFilter(DateFilter? date) {
    final next = date ?? _dateFilter;
    if (_dateFilter == next) return;
    _dateFilter = next;
    _invalidateFilteredCache();
    notifyListeners();
  }

  void setAssigneeFilter(String? id) {
    final next = id ?? _assigneeFilter;
    if (_assigneeFilter == next) return;
    _assigneeFilter = next;
    _invalidateFilteredCache();
    notifyListeners();
  }

  void resetTeamScopedFilters() {
    _projectIdFilter = 'all';
    _statusFilter = '전체';
    _priorityFilter = null;
    _dateFilter = DateFilter.all;
    _assigneeFilter = 'all';
    _invalidateFilteredCache();
    notifyListeners();
  }

  Future<void> loadData() async {
    final tbox = await _ensureTaskBox();
    final pbox = await _ensureProjectBox();

    _tasks = tbox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _projects = pbox.values.toList();

    _invalidateAllCaches();
    unawaited(_ensureMetaBox().catchError((_) => Hive.box(_metaBoxName)));
    notifyListeners();
  }

  // --- Task meta helpers ---
  bool isIncludedInSchedule(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      unawaited(_ensureMetaBox().catchError((_) => Hive.box(_metaBoxName)));
      return true;
    }
    final raw = box.get(taskId);
    if (raw is Map) return raw['scheduleInclude'] != false;
    return true;
  }

  DateTimeRange? getScheduleRange(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      unawaited(_ensureMetaBox().catchError((_) => Hive.box(_metaBoxName)));
      return null;
    }
    final raw = box.get(taskId);
    if (raw is Map) {
      final start = DateTime.tryParse((raw['scheduleStart'] ?? '').toString());
      final end = DateTime.tryParse((raw['scheduleEnd'] ?? '').toString());
      if (start != null && end != null) return DateTimeRange(start: start, end: end);
    }
    return null;
  }

  DateTime effectiveTimelineDate(Task task) => isIncludedInSchedule(task.id) ? (getScheduleRange(task.id)?.start ?? task.dueDate) : task.dueDate;
  DateTimeRange? effectiveScheduleRange(Task task) => isIncludedInSchedule(task.id) ? (getScheduleRange(task.id) ?? DateTimeRange(start: task.dueDate, end: task.dueDate)) : null;

  Future<void> setScheduleOptions({required String taskId, required bool includeInSchedule, DateTimeRange? range}) async {
    final box = await _ensureMetaBox();
    final current = box.get(taskId) ?? {};
    final next = Map<String, dynamic>.from(current);
    next['scheduleInclude'] = includeInSchedule;
    next['scheduleStart'] = range?.start.toIso8601String();
    next['scheduleEnd'] = range?.end.toIso8601String();
    await box.put(taskId, next);
    notifyListeners();
  }

  List<Task> getFilteredTasks(String currentTeamId, {String? myId}) {
    final cacheKey = [currentTeamId, _projectIdFilter, _statusFilter, _priorityFilter?.name ?? 'all', _dateFilter.name, _assigneeFilter, myId ?? '', _tasks.length.toString()].join('|');
    if (_filteredCacheKey == cacheKey && _filteredCache != null) return _filteredCache!;

    final now = DateTime.now();
    DateTime? from;
    switch (_dateFilter) {
      case DateFilter.all: from = null; break;
      case DateFilter.today: from = DateTime(now.year, now.month, now.day); break;
      case DateFilter.week: from = now.subtract(const Duration(days: 7)); break;
      case DateFilter.month: from = now.subtract(const Duration(days: 30)); break;
    }

    final list = _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      if (_projectIdFilter != 'all' && (t.projectId != _projectIdFilter)) return false;
      if (_statusFilter == '진행중' && t.isDone) return false;
      if (_statusFilter == '완료' && !t.isDone) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;
      if (from != null && t.createdAt.isBefore(from)) return false;
      return true;
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _filteredCacheKey = cacheKey;
    _filteredCache = list;
    return list;
  }

  Future<void> addTask(Task t) async {
    final box = await _ensureTaskBox();
    await box.put(t.id, t);
    _tasks.add(t);
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> updateTask(Task t) async {
    final box = await _ensureTaskBox();
    await box.put(t.id, t);
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final box = await _ensureTaskBox();
    await box.delete(id);
    _tasks.removeWhere((t) => t.id == id);
    _invalidateAllCaches();
    notifyListeners();
  }

  // ✨ [추가] 우선순위 순환 로직
  Future<void> cycleTaskPriority(Task task) async {
    final nextIdx = (task.priority.index + 1) % TaskPriority.values.length;
    task.priority = TaskPriority.values[nextIdx];
    await updateTask(task); 
    notifyListeners();
  }

  // ✨ [추가] 완료 보고서 저장 및 상태 업데이트
  Future<void> saveCompletionReport(Task task, String report) async {
    task.completionReport = report;
    task.status = TaskStatus.done;
    task.isDone = true; 
    task.completedAt = DateTime.now();
    await updateTask(task);
    notifyListeners();
  }

  // ✨ [추가] 상태 업데이트 로직 (상세 시트 등에서 사용)
  Future<void> updateTaskStatus(Task task, bool isDone) async {
    task.isDone = isDone;
    task.status = isDone ? TaskStatus.done : TaskStatus.todo;
    task.completedAt = isDone ? DateTime.now() : null;
    await updateTask(task);
    notifyListeners();
  }
}
