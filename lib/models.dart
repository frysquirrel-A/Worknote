import 'package:flutter/material.dart';

// --- Enums ---
enum TaskPriority { high, medium, low, none }
enum AppTone { white, blue, black }
enum DateFilter { all, today, week, twoWeeks, oneMonth }
enum JournalGroupPeriod { day, week, month, quarter, year }

// --- 1. 팀 모델 ---
class Team {
  final String id;
  String name;
  String inviteCode;
  List<String> memberIds;
  Map<String, String> memberRoles; // {userId: role}

  Team({
    required this.id, 
    required this.name, 
    required this.inviteCode, 
    required this.memberIds,
    Map<String, String>? memberRoles,
  }) : memberRoles = memberRoles ?? {}; // [5-3 수리] 가변 맵으로 초기화

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    inviteCode: json['inviteCode'] ?? '',
    memberIds: List<String>.from(json['memberIds'] ?? []),
    memberRoles: Map<String, String>.from(json['memberRoles'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'inviteCode': inviteCode, 'memberIds': memberIds, 'memberRoles': memberRoles,
  };
}

// --- 2. 프로젝트 모델 ---
class Project {
  final String id;
  final String teamId;
  final String name;
  final int colorValue; 

  Project({required this.id, required this.teamId, required this.name, required this.colorValue});
  
  Color get color => Color(colorValue);

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] ?? '',
    teamId: json['teamId'] ?? 'default',
    name: json['name'] ?? '',
    colorValue: json['colorValue'] ?? 0xFF2196F3,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'teamId': teamId, 'name': name, 'colorValue': colorValue,
  };
}

// --- 3. 사용자 모델 ---
class AppUser {
  final String id, password;
  String name;
  String? profileImage;

  AppUser({required this.id, required this.password, required this.name, this.profileImage});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] ?? '',
    password: json['password'] ?? '',
    name: json['name'] ?? '',
    profileImage: json['profileImage'],
  );

  Map<String, dynamic> toJson() => { 'id': id, 'password': password, 'name': name, 'profileImage': profileImage };
}

// --- 4. 업무(Task) 모델 ---
class Task {
  final String id, teamId;
  String title;
  final String creatorId, creatorName;
  final String assigneeId, assigneeName, assigneeEmoji;
  final List<String> assigneeIds, assigneeNames, assigneeEmojis;
  String? projectId; 
  final DateTime createdAt, dueDate;
  DateTime updatedAt;
  DateTime? completedAt;
  bool isDone;
  TaskPriority priority;
  List<String> taskNotes;
  String? completionReport;

  Task({
    required this.id, required this.teamId, required this.title, 
    required this.creatorId, required this.creatorName,
    required this.assigneeId, required this.assigneeName, required this.assigneeEmoji,
    this.assigneeIds = const [], this.assigneeNames = const [], this.assigneeEmojis = const [],
    this.projectId,
    required this.createdAt, required this.dueDate, DateTime? updatedAt,
    this.completedAt, this.isDone = false, this.priority = TaskPriority.none,
    List<String>? taskNotes, this.completionReport,
  }) : taskNotes = taskNotes ?? [], updatedAt = updatedAt ?? createdAt;

  factory Task.fromJson(Map<String, dynamic> json) {
    // [5-2 수리] 방어적 파싱
    return Task(
      id: json['id'] ?? '', 
      teamId: json['teamId'] ?? 'default', 
      title: json['title'] ?? '',
      creatorId: json['creatorId'] ?? 'unknown', 
      creatorName: json['creatorName'] ?? '작성자',
      assigneeId: json['assigneeId'] ?? 'unknown', 
      assigneeName: json['assigneeName'] ?? '담당자', 
      assigneeEmoji: json['assigneeEmoji'] ?? '👷',
      assigneeIds: List<String>.from(json['assigneeIds'] ?? []),
      assigneeNames: List<String>.from(json['assigneeNames'] ?? []),
      assigneeEmojis: List<String>.from(json['assigneeEmojis'] ?? []),
      projectId: json['projectId'], 
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(), 
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(), 
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      isDone: json['isDone'] ?? false, 
      priority: TaskPriority.values[(json['priority'] ?? 3).clamp(0, 3)], 
      taskNotes: List<String>.from(json['taskNotes'] ?? []),
      completionReport: json['completionReport'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'teamId': teamId, 'title': title, 
    'creatorId': creatorId, 'creatorName': creatorName,
    'assigneeId': assigneeId, 'assigneeName': assigneeName, 'assigneeEmoji': assigneeEmoji,
    'assigneeIds': assigneeIds, 'assigneeNames': assigneeNames, 'assigneeEmojis': assigneeEmojis,
    'projectId': projectId, 'createdAt': createdAt.toIso8601String(), 'dueDate': dueDate.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(), 'completedAt': completedAt?.toIso8601String(), 'isDone': isDone,
    'priority': priority.index, 'taskNotes': taskNotes, 'completionReport': completionReport,
  };
}

// --- 5. 일지(JournalEntry) 모델 ---
class JournalEntry {
  final String id, teamId, userId, userName, title, content;
  String? projectId;
  final DateTime date;
  DateTime updatedAt;
  final List<String> photos;
  bool isPrivate;

  JournalEntry({
    required this.id, required this.teamId, required this.userId, required this.userName, 
    required this.title, required this.content, this.projectId,
    required this.date, DateTime? updatedAt, required this.photos,
    this.isPrivate = false,
  }) : updatedAt = updatedAt ?? date;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] ?? '', 
    teamId: json['teamId'] ?? 'default', 
    userId: json['userId'] ?? '', 
    userName: json['userName'] ?? '',
    title: json['title'] ?? '', 
    content: json['content'] ?? '', 
    projectId: json['projectId'],
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(), 
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    photos: List<String>.from(json['photos'] ?? []), 
    isPrivate: json['isPrivate'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'teamId': teamId, 'userId': userId, 'userName': userName, 'title': title,
    'content': content, 'projectId': projectId, 'date': date.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(), 'photos': photos, 'isPrivate': isPrivate,
  };
}

// --- 6. 채팅 메시지 모델 ---
class ChatMessage {
  final String id, teamId, senderId, senderName, content;
  final DateTime sentAt;

  ChatMessage({required this.id, required this.teamId, required this.senderId, required this.senderName, required this.content, required this.sentAt});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '', 
    teamId: json['teamId'] ?? '', 
    senderId: json['senderId'] ?? '', 
    senderName: json['senderName'] ?? '', 
    content: json['content'] ?? '', 
    sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now()
  );

  Map<String, dynamic> toJson() => { 'id': id, 'teamId': teamId, 'senderId': senderId, 'senderName': senderName, 'content': content, 'sentAt': sentAt.toIso8601String() };
}
