import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Uuid 필요
import '../models.dart';
import '../services/drive_service.dart';

class TaskProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  
  List<Task> _tasks = [];
  List<Project> _projects = [];

  // UI Filters
  String projectIdFilter = 'all';
  String statusFilter = '전체';
  TaskPriority? priorityFilter;
  DateFilter dateFilter = DateFilter.all;

  List<Project> get projects => _projects;
  List<Task> get tasks => _tasks;

  List<Task> getFilteredTasks(String currentTeamId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((t) {
      if (t.teamId != currentTeamId) return false;
      if (projectIdFilter != 'all' && t.projectId != projectIdFilter) return false;
      if (statusFilter == '진행 중' && t.isDone) return false;
      if (statusFilter == '완료됨' && !t.isDone) return false;
      
      return true;
    }).toList();
  }

  // --- Actions ---

  Future<void> loadData() async {
    // 1. 프로젝트 동기화
    final pData = await _driveService.syncJsonData(_projects.map((e)=>e.toJson()).toList(), 'worknote_projects.json');
    if (pData != null && pData.isNotEmpty) {
      _projects = pData.map((e) => Project.fromJson(e)).toList();
    } else {
       // [복구] 기본 프로젝트 생성
       _projects = [Project(id: 'p1', teamId: 'default', name: '용인 반도체 현장', colorValue: Colors.blue.value)];
    }

    // 2. 업무 동기화
    final tData = await _driveService.syncJsonData(_tasks.map((e)=>e.toJson()).toList(), 'worknote_tasks.json');
    if (tData != null && tData.isNotEmpty) {
      _tasks = tData.map((e) => Task.fromJson(e)).toList();
    } else {
      // [복구] 데이터가 없으면 '샘플 데이터' 자동 생성
      _generateDummyTasks();
    }
    
    notifyListeners();
  }

  // [샘플 데이터 생성 함수]
  void _generateDummyTasks() {
    _tasks = [
      Task(
        id: const Uuid().v4(), teamId: 'default', projectId: 'p1',
        title: '302동 콘크리트 타설 확인',
        assigneeId: 'me', assigneeName: '김반장', assigneeEmoji: '👷',
        createdAt: DateTime.now(), dueDate: DateTime.now(),
        priority: TaskPriority.high, isDone: false,
      ),
      Task(
        id: const Uuid().v4(), teamId: 'default', projectId: 'p1',
        title: '안전교육 일지 작성',
        assigneeId: 'me', assigneeName: '김반장', assigneeEmoji: '📝',
        createdAt: DateTime.now(), dueDate: DateTime.now().add(const Duration(days: 1)),
        priority: TaskPriority.medium, isDone: false,
      ),
      Task(
        id: const Uuid().v4(), teamId: 'default', projectId: 'p1',
        title: '자재 납품 내역서 검토',
        assigneeId: 'me', assigneeName: '김반장', assigneeEmoji: '🚛',
        createdAt: DateTime.now().subtract(const Duration(days: 1)), dueDate: DateTime.now(),
        priority: TaskPriority.low, isDone: true,
      ),
    ];
  }

  Future<void> addTask(Task t) async {
    _tasks.add(t);
    notifyListeners();
    await _syncTasks();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _syncTasks();
  }

  Future<void> updateTaskStatus(Task task, bool isDone) async {
    task.isDone = isDone;
    notifyListeners();
    await _syncTasks();
  }
  
  Future<void> cycleTaskPriority(Task task) async {
    task.priority = TaskPriority.values[(task.priority.index + 1) % 4];
    notifyListeners();
    await _syncTasks();
  }

  Future<void> addProject(Project p) async {
    _projects.add(p);
    notifyListeners();
    await _driveService.syncJsonData(_projects.map((e)=>e.toJson()).toList(), 'worknote_projects.json');
  }

  Future<void> _syncTasks() async {
    await _driveService.syncJsonData(_tasks.map((e)=>e.toJson()).toList(), 'worknote_tasks.json');
  }

  void setFilter({String? projectId, String? status, TaskPriority? priority, DateFilter? date}) {
    if (status != null) statusFilter = status;
    notifyListeners();
  }
}
