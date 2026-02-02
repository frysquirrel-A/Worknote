import 'dart:math';
import 'package:flutter/material.dart';
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

  // --- Getters ---
  List<Project> get projects => _projects;
  List<Task> get tasks => _tasks;

  // 특정 팀의 업무만 필터링해서 가져오기
  List<Task> getFilteredTasks(String currentTeamId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((t) {
      // [중요] 현재 팀의 업무만 보여주기
      if (t.teamId != currentTeamId) return false;

      if (projectIdFilter != 'all' && t.projectId != projectIdFilter) return false;
      if (statusFilter == '진행 중' && t.isDone) return false;
      if (statusFilter == '완료됨' && !t.isDone) return false;
      if (priorityFilter != null && t.priority != priorityFilter) return false;
      
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      if (dateFilter == DateFilter.today && !taskDate.isAtSameMomentAs(today)) return false;
      if (dateFilter == DateFilter.week && t.dueDate.isAfter(today.add(const Duration(days: 7)))) return false;
      if (dateFilter == DateFilter.twoWeeks && t.dueDate.isAfter(today.add(const Duration(days: 14)))) return false;
      if (dateFilter == DateFilter.oneMonth && t.dueDate.isAfter(today.add(const Duration(days: 30)))) return false;
      
      return true;
    }).toList();
  }

  // --- Actions ---

  Future<void> loadData() async {
    // 1. 프로젝트 동기화
    final pData = await _driveService.syncJsonData(_projects.map((e)=>e.toJson()).toList(), 'worknote_projects.json');
    if (pData != null) _projects = pData.map((e) => Project.fromJson(e)).toList();
    if (_projects.isEmpty) {
       _projects = [
         Project(id: 'p1', teamId: 'default', name: '기본 프로젝트', colorValue: Colors.blue.value),
       ];
    }

    // 2. 업무 동기화
    final tData = await _driveService.syncJsonData(_tasks.map((e)=>e.toJson()).toList(), 'worknote_tasks.json');
    if (tData != null) _tasks = tData.map((e) => Task.fromJson(e)).toList();
    
    notifyListeners();
  }

  Future<void> addTask(Task t) async {
    _tasks.add(t);
    notifyListeners();
    await _syncTasks();
  }

  Future<void> updateTaskStatus(Task task, bool isDone) async {
    task.isDone = isDone;
    task.completedAt = isDone ? DateTime.now() : null;
    task.updatedAt = DateTime.now();
    notifyListeners();
    await _syncTasks();
  }
  
  Future<void> cycleTaskPriority(Task task) async {
    task.priority = TaskPriority.values[(task.priority.index + 1) % 4];
    task.updatedAt = DateTime.now();
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

  // 필터 설정
  void setFilter({String? projectId, String? status, TaskPriority? priority, DateFilter? date}) {
    if (projectId != null) projectIdFilter = projectId;
    if (status != null) statusFilter = status;
    if (priority != null) priorityFilter = priority;
    if (date != null) dateFilter = date;
    notifyListeners();
  }
  
  Color getRandomProjectColor() {
    final colors = [Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.teal, Colors.indigo, Colors.pink];
    return colors[Random().nextInt(colors.length)];
  }
  
  void refresh() => notifyListeners();
}
