import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/data/sync/sync_outbox.dart';
import 'package:worknote/domain/models.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider();

  // ---- In-memory data ----
  List<Task> _tasks = [];
  List<Project> _projects = [];

  /// Meta storage for tasks (untyped Hive box).
  /// We store data that we want to evolve without breaking Hive TypeAdapters.
  ///
  /// Schema (value: Map):
  /// - scheduleInclude: bool
  /// - scheduleStart: String(ISO8601) or null
  /// - scheduleEnd: String(ISO8601) or null
  /// - (legacy) scheduleDate: String(ISO8601)
  /// - completionReportAt: String(ISO8601) or null
  static const String _metaBoxName = 'task_meta';

  // ---- Filters ----
  String _projectIdFilter = 'all';
  String _statusFilter = '전체';
  TaskPriority? _priorityFilter;
  DateFilter _dateFilter = DateFilter.all;
  String _assigneeFilter = 'all';

  // ---- Perf caches ----
  // build() 반복 호출 시 동일 필터/팀 조합에 대해 매번 where/sort를 반복하지 않도록 방어
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

  // ---- Hive helpers (box not open 크래시 방지) ----
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

  // ---- Simple queries used by Home tab ----
  List<Task> tasksForTeam(String teamId) {
    final cached = _tasksForTeamCache[teamId];
    if (cached != null) return cached;
    final list = _tasks.where((t) => t.teamId == teamId).toList();
    _tasksForTeamCache[teamId] = list;
    return list;
  }

  /// 프로젝트별 진행률(0.0~1.0)
  /// - teamId를 넘기면 팀 간 데이터 오염을 원천 차단
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

  // ---- Filter setters (중복 notify / 쓸데없는 rebuild 방지) ----
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

  /// 팀 전환 시 이전 팀의 필터가 남아 데이터가 "없는 것처럼" 보이는 현상 방지
  void resetTeamScopedFilters() {
    _projectIdFilter = 'all';
    _statusFilter = '전체';
    _priorityFilter = null;
    _dateFilter = DateFilter.all;
    _assigneeFilter = 'all';
    _invalidateFilteredCache();
    notifyListeners();
  }

    Map<String, dynamic> _metaMapOf(dynamic raw) {
    if (raw is Map) {
      final out = <String, dynamic>{};
      for (final entry in raw.entries) {
        final k = entry.key;
        if (k is String) {
          out[k] = entry.value;
        }
      }
      return out;
    }
    return <String, dynamic>{};
  }

// ---- Loading ----
  Future<void> loadData() async {
    final tbox = await _ensureTaskBox();
    final pbox = await _ensureProjectBox();

    _tasks = tbox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _projects = pbox.values.toList();

    _invalidateAllCaches();

    // meta 박스 warm-up (Box not found 크래시 방지)
    unawaited(_ensureMetaBox().catchError((_) => Hive.box(_metaBoxName)));

    notifyListeners();
  }

  // --- Task meta helpers ---
  bool isIncludedInSchedule(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      // 박스가 아직 열리지 않은 경우(핫리스타트/초기화 타이밍 등) 크래시 방지.
      // meta 데이터가 없던 시절(legacy)처럼 "일단 포함"으로 동작.
      unawaited(_ensureMetaBox().catchError((_) => Hive.box(_metaBoxName)));
      return true;
    }

    final raw = box.get(taskId);
    if (raw is Map) return raw['scheduleInclude'] != false;
    return true; // legacy behavior: tasks were always visible on schedule
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
      if (start != null && end != null) {
        return DateTimeRange(start: start, end: end);
      }

      // Legacy support: single-date scheduleDate
      final legacy = DateTime.tryParse((raw['scheduleDate'] ?? '').toString());
      if (legacy != null) {
        return DateTimeRange(start: legacy, end: legacy);
      }
    }
    return null;
  }

  /// 타임라인 기준일
  /// - 일정 포함 + 일정 시작이 있으면 start
  /// - 아니면 기한(dueDate)
  DateTime effectiveTimelineDate(Task task) {
    if (!isIncludedInSchedule(task.id)) return task.dueDate;
    final range = getScheduleRange(task.id);
    return range?.start ?? task.dueDate;
  }

  DateTimeRange? effectiveScheduleRange(Task task) {
    if (!isIncludedInSchedule(task.id)) return null;
    final range = getScheduleRange(task.id);
    return range ?? DateTimeRange(start: task.dueDate, end: task.dueDate);
  }

  bool isScheduledOnDay(String taskId, DateTime day) {
    if (!isIncludedInSchedule(taskId)) return false;
    final range = getScheduleRange(taskId);
    if (range == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(range.start.year, range.start.month, range.start.day);
    final e = DateTime(range.end.year, range.end.month, range.end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Future<void> setScheduleOptions({
    required String taskId,
    required bool includeInSchedule,
    DateTimeRange? range,
  }) async {
    final box = await _ensureMetaBox();
    final current = box.get(taskId);
    final next = _metaMapOf(current);

    next['scheduleInclude'] = includeInSchedule;
    next.remove('includeInSchedule'); // backward cleanup
    next['scheduleStart'] = range?.start.toIso8601String();
    next['scheduleEnd'] = range?.end.toIso8601String();
    // Remove legacy field to avoid confusion
    next.remove('scheduleDate');

    await box.put(taskId, next);

    // Outbox: schedule meta change ("계획" 반영)
    try {
      final t = (await _ensureTaskBox()).get(taskId);
      unawaited(
        SyncOutbox.instance.enqueue(
          teamId: t?.teamId ?? 'unknown',
          entity: 'task',
          action: 'meta_schedule',
          entityId: taskId,
          payload: {
            'include': includeInSchedule.toString(),
            'start': range?.start.toIso8601String() ?? '',
            'end': range?.end.toIso8601String() ?? '',
          },
        ),
      );
    } catch (_) {
      // no-op
    }

    notifyListeners();
  }

  DateTime? getCompletionReportAt(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      unawaited(_ensureMetaBox().catchError((_) => Hive.box(_metaBoxName)));
      return null;
    }

    final raw = box.get(taskId);
    if (raw is Map) {
      final v = raw['completionReportAt'];
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }
    return null;
  }

  Future<void> setCompletionReportAt(String taskId, DateTime at) async {
    final box = await _ensureMetaBox();
    final current = box.get(taskId);
    final next = _metaMapOf(current);
    next['completionReportAt'] = at.toIso8601String();
    await box.put(taskId, next);

    // Outbox: completion report meta change
    try {
      final t = (await _ensureTaskBox()).get(taskId);
      unawaited(
        SyncOutbox.instance.enqueue(
          teamId: t?.teamId ?? 'unknown',
          entity: 'task',
          action: 'meta_completion_report',
          entityId: taskId,
          payload: {
            'completionReportAt': at.toIso8601String(),
          },
        ),
      );
    } catch (_) {
      // no-op
    }

    notifyListeners();
  }

  // ---- Filtered tasks (with cache) ----
  List<Task> getFilteredTasks(String currentTeamId, {String? myId}) {
    final cacheKey = [
      currentTeamId,
      _projectIdFilter,
      _statusFilter,
      _priorityFilter?.name ?? 'all',
      _dateFilter.name,
      _assigneeFilter,
      myId ?? '',
      // tasks 길이/updatedAt 기반의 간단한 invalidation
      _tasks.length.toString(),
      _tasks.isEmpty ? '' : _tasks.first.updatedAt.millisecondsSinceEpoch.toString(),
    ].join('|');

    if (_filteredCacheKey == cacheKey && _filteredCache != null) {
      return _filteredCache!;
    }

    final now = DateTime.now();

    // 작성일 기간 필터 from
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

    final list = _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;

      // 프로젝트
      if (_projectIdFilter != 'all') {
        if (_projectIdFilter == 'none') {
          if (t.projectId != null) return false;
        } else {
          if (t.projectId != _projectIdFilter) return false;
        }
      }

      // 상태
      if (_statusFilter == '진행 중' && t.isDone) return false;
      if (_statusFilter == '완료됨' && !t.isDone) return false;

      // 우선순위
      if (_priorityFilter != null && t.priority != _priorityFilter) return false;

      // 담당자
      if (_assigneeFilter != 'all') {
        final filterId = (_assigneeFilter == 'me') ? (myId ?? 'me') : _assigneeFilter;
        final hitSingle = t.assigneeId == filterId;
        final hitMulti = t.assigneeIds.contains(filterId);
        if (!hitSingle && !hitMulti) return false;
      }

      if (from != null && t.createdAt.isBefore(from)) return false;

      return true;
    }).toList();

    // 기본 정렬: 최신 작성일
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _filteredCacheKey = cacheKey;
    _filteredCache = list;
    return list;
  }

  // ---- Project helpers ----
  String getProjectName(String? id) {
    if (id == null || id == 'none') return '없음';
    if (id == 'all') return '전체';
    return _projects
        .firstWhere(
          (p) => p.id == id,
          orElse: () => Project(id: '', teamId: '', name: '알 수 없음', colorValue: 0),
        )
        .name;
  }

  // ---- CRUD: Task ----
  Future<void> addTask(Task t) async {
    final box = await _ensureTaskBox();
    await box.put(t.id, t);

    // Outbox: for future remote sync / audit.
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: t.teamId,
        entity: 'task',
        action: 'put',
        entityId: t.id,
        payload: t.toJson(),
      ),
    );

    _tasks.add(t);
    _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> updateTask(Task t) async {
    final box = await _ensureTaskBox();
    t.updatedAt = DateTime.now();
    await box.put(t.id, t);

    // Outbox: generic update
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: t.teamId,
        entity: 'task',
        action: 'put',
        entityId: t.id,
        payload: t.toJson(),
      ),
    );

    final idx = _tasks.indexWhere((item) => item.id == t.id);
    if (idx >= 0) {
      _tasks[idx] = t;
    }
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> updateTaskStatus(Task t, bool done) async {
    // NOTE: Hive object 직접 mutate. 실패/동시성 리스크를 줄이기 위해 put까지 원자적으로 수행.
    t.isDone = done;
    t.completedAt = done ? DateTime.now() : null;
    t.updatedAt = DateTime.now();

    final box = await _ensureTaskBox();
    await box.put(t.id, t);

    // Outbox: status change
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: t.teamId,
        entity: 'task',
        action: 'status',
        entityId: t.id,
        payload: {
          'isDone': done.toString(),
          'completedAt': t.completedAt?.toIso8601String() ?? '',
        },
      ),
    );

    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final box = await _ensureTaskBox();

    // Capture before delete (for outbox logging)
    final Task? before = box.get(id);

    await box.delete(id);

    // meta cascade delete (고아 데이터 방지)
    try {
      final mbox = await _ensureMetaBox();
      await mbox.delete(id);
    } catch (_) {}

    // Outbox: deletion
    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: before?.teamId ?? 'unknown',
        entity: 'task',
        action: 'delete',
        entityId: id,
        payload: {
          'title': before?.title ?? '',
        },
      ),
    );

    _tasks.removeWhere((t) => t.id == id);
    _invalidateAllCaches();
    notifyListeners();
  }

  // ---- CRUD: Project ----
  Future<void> addProject(Project p) async {
    final box = await _ensureProjectBox();
    await box.put(p.id, p);

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: p.teamId,
        entity: 'project',
        action: 'put',
        entityId: p.id,
        payload: p.toJson(),
      ),
    );

    _projects.add(p);
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    final box = await _ensureProjectBox();
    final Project? before = box.get(id);
    await box.delete(id);

    unawaited(
      SyncOutbox.instance.enqueue(
        teamId: before?.teamId ?? 'unknown',
        entity: 'project',
        action: 'delete',
        entityId: id,
        payload: {
          'name': before?.name ?? '',
        },
      ),
    );

    _projects.removeWhere((p) => p.id == id);
    _invalidateAllCaches();
    notifyListeners();
  }

  Future<void> cycleTaskPriority(Task task) async {
    final nextIdx = (task.priority.index + 1) % TaskPriority.values.length;
    task.priority = TaskPriority.values[nextIdx];
    await updateTask(task);
  }

  Future<void> saveCompletionReport(Task task, String report) async {
    task.completionReport = report;
    await updateTask(task);
  }
}
