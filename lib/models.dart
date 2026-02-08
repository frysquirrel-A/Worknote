import 'package:flutter/material.dart';

// 1. 업무 우선순위
enum TaskPriority { high, medium, low }

// 2. 업무 (Task)
class Task {
  String id;
  String teamId;
  String title;
  String assigneeId;
  String assigneeName;
  String assigneeEmoji;
  String? projectId; // null이면 '프로젝트 없음'
  DateTime createdAt;
  DateTime dueDate;
  DateTime? updatedAt;
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
    this.projectId, // Nullable
    required this.createdAt,
    required this.dueDate,
    this.updatedAt,
    this.completedAt,
    this.isDone = false,
    this.priority = TaskPriority.medium,
    this.taskNotes = const [],
    this.completionReport,
  });

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
    'updatedAt': updatedAt?.toIso8601String(),
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
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    isDone: json['isDone'] ?? false,
    priority: TaskPriority.values[json['priority'] ?? 1],
    taskNotes: List<String>.from(json['taskNotes'] ?? []),
    completionReport: json['completionReport'],
  );
}

// 3. 프로젝트
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

// 4. 일지
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
  }) : updatedAt = updatedAt ?? DateTime.now();

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
    updatedAt: DateTime.parse(json['updatedAt']),
    photos: List<String>.from(json['photos'] ?? []),
    isPrivate: json['isPrivate'] ?? false,
  );
}

// 5. 팀 (Team) - [수정됨: 직책 맵 추가]
class Team {
  String id;
  String name;
  String inviteCode;
  List<String> memberIds;
  Map<String, String> memberRoles; // {userId: role}

  Team({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberIds,
    this.memberRoles = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'inviteCode': inviteCode,
    'memberIds': memberIds,
    'memberRoles': memberRoles,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    inviteCode: json['inviteCode'],
    memberIds: List<String>.from(json['memberIds'] ?? []),
    memberRoles: Map<String, String>.from(json['memberRoles'] ?? {}),
  );
}

// 6. 사용자
class AppUser {
  String id;
  String password;
  String name; // 기본 이름
  String? profileImage;

  AppUser({
    required this.id,
    required this.password,
    required this.name,
    this.profileImage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'password': password,
    'name': name,
    'profileImage': profileImage,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    password: json['password'],
    name: json['name'],
    profileImage: json['profileImage'],
  );
}

// 7. 채팅
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
    'id': id,
    'teamId': teamId,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    teamId: json['teamId'],
    senderId: json['senderId'],
    senderName: json['senderName'],
    content: json['content'],
    sentAt: DateTime.parse(json['sentAt']),
  );
}

enum DateFilter { all, today, week, twoWeeks, oneMonth }
