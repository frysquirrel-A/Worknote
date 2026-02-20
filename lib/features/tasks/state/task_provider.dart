import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/domain/models.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Project> _projects = [];

  /// Meta storage for tasks (untyped Hive box).
  /// We store data that we want to evolve without breaking Hive TypeAdapters.
  ///
  /// Schema (value: Map):
  /// - includeInSchedule: bool
  /// - scheduleStart: String(ISO8601) or null
  /// - scheduleEnd: String(ISO8601) or null
  /// - (legacy) scheduleDate: String(ISO8601)
  /// - completionReportAt: String(ISO8601) or null
  static const String _metaBoxName = 'task_meta';

  /// meta 박스는 bootstrap 단계에서 open되도록 되어 있지만,
  /// 핫리스타트/초기화 타이밍 등으로 간헐적으로 open 이전에 접근하는 케이스가
  /// 발생할 수 있습니다. ("Box not found" 크래시)
  ///
  /// - 동기 접근이 필요한 곳에서는 box가 준비되지 않았을 경우 "기본값"으로
  ///   동작하도록 처리하고,
  /// - 비동기 작업(put 등)에서는 필요 시 openBox를 보장합니다.
  Box? _metaBoxOrNull() {
    if (Hive.isBoxOpen(_metaBoxName)) return Hive.box(_metaBoxName);
    return null;
  }

  Future<Box> _ensureMetaBox() async {
    if (Hive.isBoxOpen(_metaBoxName)) return Hive.box(_metaBoxName);
    return Hive.openBox(_metaBoxName);
  }

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

  /// 홈 탭 등에서 간단 통계/리스트를 만들 때 사용합니다.
  /// (현재 필터 UI 상태와 무관하게 팀 기준으로 전체 업무를 반환)
  List<Task> tasksForTeam(String teamId) {
    return _tasks.where((t) => t.teamId == teamId).toList();
  }

  /// 프로젝트별 진행률(0.0~1.0)
  double projectProgress(String projectId) {
    final list = _tasks.where((t) => t.projectId == projectId).toList();
    if (list.isEmpty) return 0;
    final done = list.where((t) => t.isDone).length;
    return done / list.length;
  }

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

  // --- Task meta helpers ---
  bool isIncludedInSchedule(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      // 박스가 아직 열리지 않은 경우(핫리스타트/초기화 타이밍 등) 크래시 방지.
      // meta 데이터가 없던 시절(legacy)처럼 "일단 포함"으로 동작.
      _ensureMetaBox().then((_) {}, onError: (_) {});
      return true;
    }

    final raw = box.get(taskId);
    if (raw is Map) return raw['includeInSchedule'] == true;
    return true; // legacy behavior: tasks were always visible on schedule
  }

  DateTimeRange? getScheduleRange(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      _ensureMetaBox().then((_) {}, onError: (_) {});
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
    final Map<String, dynamic> next = (current is Map)
        ? Map<String, dynamic>.from(current.cast())
        : <String, dynamic>{};

    next['includeInSchedule'] = includeInSchedule;
    next['scheduleStart'] = range?.start.toIso8601String();
    next['scheduleEnd'] = range?.end.toIso8601String();
    // Remove legacy field to avoid confusion
    next.remove('scheduleDate');

    await box.put(taskId, next);
    notifyListeners();
  }

  DateTime? getCompletionReportAt(String taskId) {
    final box = _metaBoxOrNull();
    if (box == null) {
      _ensureMetaBox().then((_) {}, onError: (_) {});
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
    final Map<String, dynamic> next = (current is Map)
        ? Map<String, dynamic>.from(current.cast())
        : <String, dynamic>{};
    next['completionReportAt'] = at.toIso8601String();
    await box.put(taskId, next);
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
  Future<void> deleteTask(String id) async {
    await Hive.box<Task>('tasks').delete(id);
    try {
      final box = await _ensureMetaBox();
      await box.delete(id);
    } catch (_) {}
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }
  Future<void> cycleTaskPriority(Task t) async { int next = (t.priority.index + 1) % 4; t.priority = TaskPriority.values[next]; await Hive.box<Task>('tasks').put(t.id, t); notifyListeners(); }
  Future<void> addProject(Project p) async { await Hive.box<Project>('projects').put(p.id, p); _projects.add(p); notifyListeners(); }

  Future<void> saveCompletionReport(Task task, String? report) async {
    task.completionReport = (report ?? '').trim().isEmpty ? null : report!.trim();
    task.updatedAt = DateTime.now();
    await Hive.box<Task>('tasks').put(task.id, task);
    if (task.completionReport != null) {
      await setCompletionReportAt(task.id, DateTime.now());
    }
    notifyListeners();
  }
}
