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
  }) : memberRoles = memberRoles ?? {};

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        inviteCode: (json['inviteCode'] ?? '').toString(),
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
    id: json['id'],
    teamId: json['teamId'] ?? 'default',
    name: json['name'],
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
    id: json['id'], password: json['password'], name: json['name'], profileImage: json['profileImage'],
  );

  Map<String, dynamic> toJson() => { 'id': id, 'password': password, 'name': name, 'profileImage': profileImage };
}

// --- 4. 업무(Task) 모델 (다중 담당자 및 작성자 필드 추가) ---
class Task {
  final String id, teamId;
  String title;
  final String creatorId, creatorName; // 작성자 정보
  final String assigneeId, assigneeName, assigneeEmoji; // 단일 담당자 (호환용)
  final List<String> assigneeIds, assigneeNames, assigneeEmojis; // 다중 담당자
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

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: (json['id'] ?? '').toString(),
        teamId: (json['teamId'] ?? 'default').toString(),
        title: (json['title'] ?? '').toString(),
        creatorId: (json['creatorId'] ?? 'unknown').toString(),
        creatorName: (json['creatorName'] ?? '작성자').toString(),
        assigneeId: (json['assigneeId'] ?? '').toString(),
        assigneeName: (json['assigneeName'] ?? '').toString(),
        assigneeEmoji: (json['assigneeEmoji'] ?? '👤').toString(),
        assigneeIds: List<String>.from(json['assigneeIds'] ?? const []),
        assigneeNames: List<String>.from(json['assigneeNames'] ?? const []),
        assigneeEmojis: List<String>.from(json['assigneeEmojis'] ?? const []),
        projectId: json['projectId']?.toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
        dueDate: DateTime.tryParse((json['dueDate'] ?? '').toString()) ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
        isDone: (json['isDone'] ?? false) == true,
        priority: _safePriority(json['priority']),
        taskNotes: List<String>.from(json['taskNotes'] ?? const []),
        completionReport: json['completionReport']?.toString(),
      );

  static TaskPriority _safePriority(dynamic raw) {
    final idx = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (idx == null) return TaskPriority.none;
    if (idx < 0 || idx >= TaskPriority.values.length) return TaskPriority.none;
    return TaskPriority.values[idx];
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
        id: (json['id'] ?? '').toString(),
        teamId: (json['teamId'] ?? 'default').toString(),
        userId: (json['userId'] ?? '').toString(),
        userName: (json['userName'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        projectId: json['projectId']?.toString(),
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
            (DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now()),
        photos: List<String>.from(json['photos'] ?? const []),
        isPrivate: (json['isPrivate'] ?? false) == true,
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
    id: json['id'], teamId: json['teamId'], senderId: json['senderId'], senderName: json['senderName'], content: json['content'], sentAt: DateTime.parse(json['sentAt']),
  );

  Map<String, dynamic> toJson() => { 'id': id, 'teamId': teamId, 'senderId': senderId, 'senderName': senderName, 'content': content, 'sentAt': sentAt.toIso8601String() };
}
