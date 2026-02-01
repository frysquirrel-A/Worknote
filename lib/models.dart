import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low, none }
enum AppTone { white, blue, black }
enum DateFilter { all, today, week, twoWeeks, oneMonth }
enum JournalGroupPeriod { day, week, month, quarter, year }

class Project {
  final String id;
  final String name;
  final Color color;
  Project({required this.id, required this.name, required this.color});
}

class TeamMember {
  final String id, name, emoji, role;
  TeamMember({required this.id, required this.name, required this.emoji, required this.role});
}

class Task {
  final String id;
  String title;
  final String assigneeId, assigneeName, assigneeEmoji;
  String projectId;
  final DateTime createdAt, dueDate;
  DateTime updatedAt;
  DateTime? completedAt;
  bool isDone;
  TaskPriority priority;
  List<String> taskNotes;
  String? completionReport;

  Task({
    required this.id, required this.title, required this.assigneeId,
    required this.assigneeName, required this.assigneeEmoji, required this.projectId,
    required this.createdAt, required this.dueDate, DateTime? updatedAt,
    this.completedAt, this.isDone = false, this.priority = TaskPriority.none,
    List<String>? taskNotes, this.completionReport,
  }) : taskNotes = taskNotes ?? [], updatedAt = updatedAt ?? createdAt;
}

class JournalEntry {
  final String id, userId, userName, title, content;
  String? projectId;
  final DateTime date;
  final List<String> photos;
  bool isPrivate;

  JournalEntry({
    required this.id, required this.userId, required this.userName,
    required this.title, required this.content, this.projectId,
    required this.date, required this.photos, this.isPrivate = false,
  });
}
