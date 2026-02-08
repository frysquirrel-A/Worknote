import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; 
import '../models.dart';
import '../services/drive_service.dart';
import '../services/local_db_service.dart'; 

class TaskProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService(); 
  
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
      if (priorityFilter != null && t.priority != priorityFilter) return false;
      
       if (dateFilter != DateFilter.all) {
        final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        if (dateFilter == DateFilter.today && !taskDate.isAtSameMomentAs(today)) return false;
        if (dateFilter == DateFilter.week && t.dueDate.isAfter(today.add(const Duration(days: 7)))) return false;
        if (dateFilter == DateFilter.twoWeeks && t.dueDate.isAfter(today.add(const Duration(days: 14)))) return false;
        if (dateFilter == DateFilter.oneMonth && t.dueDate.isAfter(today.add(const Duration(days: 30)))) return false;
      }
      return true;
    }).toList();
  }

  void setFilter({String? projectId, String? status, TaskPriority? priority, DateFilter? date}) {
    if (projectId != null) projectIdFilter = projectId;
    if (status != null) statusFilter = status;
    if (priority != null) priorityFilter = priority;
    if (date != null) dateFilter = date;
    notifyListeners();
  }

  Future<void> loadData() async {
    // 1. [Offline First] 로컬 DB 로드
    _tasks = _localDb.getAll<Task>('tasks');
    _projects = _localDb.getAll<Project>('projects');
    
    if (_projects.isEmpty) {
       _projects = [Project(id: 'p1', teamId: 'default', name: '메인 프로젝트', colorValue: Colors.blue.value)];
    }
    notifyListeners(); 

    // 2. [Background] 구글 드라이브 동기화
    try {
      final pData = await _driveService.syncJsonData(_projects.map((e)=>e.toJson()).toList(), 'worknote_projects.json');
      if (pData != null && pData.isNotEmpty) {
        _projects = pData.map((e) => Project.fromJson(e)).toList();
        await _localDb.syncAll<Project>('projects', _projects, (p) => p.id);
      }

      final tData = await _driveService.syncJsonData(_tasks.map((e)=>e.toJson()).toList(), 'worknote_tasks.json');
      if (tData != null && tData.isNotEmpty) {
        _tasks = tData.map((e) => Task.fromJson(e)).toList();
        await _localDb.syncAll<Task>('tasks', _tasks, (t) => t.id);
      } 
      
      notifyListeners(); 
    } catch (e) {
      print("⚠️ 오프라인 모드: 드라이브 동기화 실패 ($e)");
    }
  }

  Future<void> addTask(Task t) async {
    _tasks.add(t);
    notifyListeners();
    
    await _localDb.put<Task>('tasks', t.id, t);
    await _syncTasks();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    
    await _localDb.delete<Task>('tasks', taskId);
    await _syncTasks();
  }

  Future<void> updateTaskStatus(Task task, bool isDone) async {
    task.isDone = isDone;
    task.completedAt = isDone ? DateTime.now() : null;
    task.updatedAt = DateTime.now();
    notifyListeners();
    
    await _localDb.put<Task>('tasks', task.id, task);
    await _syncTasks();
  }
  
  Future<void> cycleTaskPriority(Task task) async {
    task.priority = TaskPriority.values[(task.priority.index + 1) % 4];
    task.updatedAt = DateTime.now();
    notifyListeners();
    
    await _localDb.put<Task>('tasks', task.id, task);
    await _syncTasks();
  }

  Future<void> addProject(Project p) async {
    _projects.add(p);
    notifyListeners();
    
    await _localDb.put<Project>('projects', p.id, p);
    await _driveService.syncJsonData(_projects.map((e)=>e.toJson()).toList(), 'worknote_projects.json');
  }

  Future<void> _syncTasks() async {
    await _driveService.syncJsonData(_tasks.map((e)=>e.toJson()).toList(), 'worknote_tasks.json');
  }

  Color getRandomProjectColor() {
    final colors = [Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.teal, Colors.indigo, Colors.pink];
    return colors[Random().nextInt(colors.length)];
  }
}