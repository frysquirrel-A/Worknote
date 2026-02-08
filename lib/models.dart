import 'package:flutter/material.dart';

// 1. 업무 우선순위 (Enum)
enum TaskPriority { high, medium, low, none }

// 2. 업무 (Task) 모델
class Task {
  String id;
  String teamId;
  String title;
  String assigneeId;
  String assigneeName;
  String assigneeEmoji;
  String projectId;
  DateTime createdAt;
  DateTime dueDate;
  DateTime updatedAt;
  DateTime? completedAt;
  bool isDone;
  TaskPriority priority;
  List<String> taskNotes;
  String? completionReport;

  Task({
    required this.id,
    required this.teamId,
    required this.title,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeEmoji,
    required this.projectId,
    required this.createdAt,
    required this.dueDate,
    DateTime? updatedAt,
    this.completedAt,
    this.isDone = false,
    this.priority = TaskPriority.none,
    this.taskNotes = const [],
    this.completionReport,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'title': title,
    'assigneeId': assigneeId,
    'assigneeName': assigneeName,
    'assigneeEmoji': assigneeEmoji,
    'projectId': projectId,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'isDone': isDone,
    'priority': priority.index,
    'taskNotes': taskNotes,
    'completionReport': completionReport,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    teamId: json['teamId'] ?? 'default',
    title: json['title'],
    assigneeId: json['assigneeId'],
    assigneeName: json['assigneeName'],
    assigneeEmoji: json['assigneeEmoji'],
    projectId: json['projectId'],
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: DateTime.parse(json['dueDate']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    isDone: json['isDone'] ?? false,
    priority: TaskPriority.values[json['priority'] ?? 3],
    taskNotes: List<String>.from(json['taskNotes'] ?? []),
    completionReport: json['completionReport'],
  );
}

// 3. 프로젝트 (Project) 모델
class Project {
  String id;
  String teamId;
  String name;
  int colorValue;

  Project({
    required this.id,
    required this.teamId,
    required this.name,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'name': name,
    'colorValue': colorValue,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    teamId: json['teamId'] ?? 'default',
    name: json['name'],
    colorValue: json['colorValue'],
  );
}

// 4. 일지 (JournalEntry) 모델
class JournalEntry {
  String id;
  String teamId;
  String userId;
  String userName;
  String title;
  String content;
  String? projectId;
  DateTime date;
  DateTime updatedAt;
  List<String> photos;
  bool isPrivate;

  JournalEntry({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    this.projectId,
    required this.date,
    DateTime? updatedAt,
    this.photos = const [],
    this.isPrivate = false,
  }) : updatedAt = updatedAt ?? date;

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'userId': userId,
    'userName': userName,
    'title': title,
    'content': content,
    'projectId': projectId,
    'date': date.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'photos': photos,
    'isPrivate': isPrivate,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'],
    teamId: json['teamId'] ?? 'default',
    userId: json['userId'],
    userName: json['userName'],
    title: json['title'],
    content: json['content'],
    projectId: json['projectId'],
    date: DateTime.parse(json['date']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.parse(json['date']),
    photos: List<String>.from(json['photos'] ?? []),
    isPrivate: json['isPrivate'] ?? false,
  );
}

// 5. 팀 (Team) 모델
class Team {
  String id;
  String name;
  String inviteCode;
  List<String> memberIds;

  Team({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'inviteCode': inviteCode,
    'memberIds': memberIds,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    inviteCode: json['inviteCode'],
    memberIds: List<String>.from(json['memberIds'] ?? []),
  );
}

// 6. 사용자 (AppUser) 모델
class AppUser {
  String id;
  String password;
  String name;
  String role;
  String? profileImage;

  AppUser({
    required this.id,
    required this.password,
    required this.name,
    required this.role,
    this.profileImage,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'password': password, 'name': name, 'role': role, 'profileImage': profileImage,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'], password: json['password'], name: json['name'], role: json['role'] ?? '팀원', profileImage: json['profileImage'],
  );
}

// 7. 채팅 메시지 (ChatMessage) 모델
class ChatMessage {
  String id;
  String teamId;
  String senderId;
  String senderName;
  String content;
  DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'teamId': teamId, 'senderId': senderId, 'senderName': senderName, 'content': content, 'sentAt': sentAt.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'], teamId: json['teamId'], senderId: json['senderId'], senderName: json['senderName'], content: json['content'], sentAt: DateTime.parse(json['sentAt']),
  );
}

// 필터 Enum
enum DateFilter { all, today, week, twoWeeks, oneMonth }
