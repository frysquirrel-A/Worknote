import 'package:hive/hive.dart';

part 'models.g.dart';

// -----------------------------------------------------------------------------
// [Enums] - 시스템 전반에서 공통으로 사용할 열거형
// -----------------------------------------------------------------------------

@HiveType(typeId: 3)
enum TaskStatus {
  @HiveField(0) todo,
  @HiveField(1) inProgress,
  @HiveField(2) done,
}

@HiveType(typeId: 4)
enum TaskPriority {
  @HiveField(0) low,
  @HiveField(1) medium,
  @HiveField(2) high,
  @HiveField(3) none,
}

@HiveType(typeId: 8)
enum DateFilter {
  @HiveField(0) all,
  @HiveField(1) today,
  @HiveField(2) week,
  @HiveField(3) month,
}

enum AppTone { white, blue, black }
enum JournalGroupPeriod { day, week, month, quarter, year }
enum JournalKind { note, progress, completionReport }

// -----------------------------------------------------------------------------
// [Task Model]
// -----------------------------------------------------------------------------

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String teamId;
  @HiveField(2) String title;
  @HiveField(3) final String creatorId;
  @HiveField(4) final String creatorName;
  @HiveField(5) final String assigneeId;
  @HiveField(6) final String assigneeName;
  @HiveField(7) final String assigneeEmoji;
  @HiveField(8) final List<String> assigneeIds;
  @HiveField(9) final List<String> assigneeNames;
  @HiveField(10) final List<String> assigneeEmojis;
  @HiveField(11) String? projectId;
  @HiveField(12) final DateTime createdAt;
  @HiveField(13) final DateTime dueDate;
  @HiveField(14) DateTime updatedAt;
  @HiveField(15) DateTime? completedAt;
  @HiveField(16) bool isDone;
  @HiveField(17) TaskPriority priority;
  @HiveField(18) TaskStatus status; // ✨ UI 요구사항 반영
  @HiveField(19) List<String> taskNotes;
  @HiveField(20) String? completionReport; // ✨ UI 요구사항 반영

  // 기존 코드 호환성을 위한 Getter
  DateTime get date => dueDate;
  List<String> get assignees => assigneeNames;

  Task({
    required this.id,
    required this.teamId,
    required this.title,
    required this.creatorId,
    required this.creatorName,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeEmoji,
    this.assigneeIds = const [],
    this.assigneeNames = const [],
    this.assigneeEmojis = const [],
    this.projectId,
    required this.createdAt,
    required this.dueDate,
    DateTime? updatedAt,
    this.completedAt,
    this.isDone = false,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    List<String>? taskNotes,
    this.completionReport,
  }) : taskNotes = taskNotes ?? [],
       updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'title': title,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'assigneeId': assigneeId,
    'assigneeName': assigneeName,
    'assigneeEmoji': assigneeEmoji,
    'assigneeIds': assigneeIds,
    'assigneeNames': assigneeNames,
    'assigneeEmojis': assigneeEmojis,
    'projectId': projectId,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'isDone': isDone,
    'priority': priority.index,
    'status': status.index,
    'taskNotes': taskNotes,
    'completionReport': completionReport,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] ?? '',
    teamId: json['teamId'] ?? 'default',
    title: json['title'] ?? '',
    creatorId: json['creatorId'] ?? 'unknown',
    creatorName: json['creatorName'] ?? '작성자',
    assigneeId: json['assigneeId'] ?? '',
    assigneeName: json['assigneeName'] ?? '',
    assigneeEmoji: json['assigneeEmoji'] ?? '👤',
    assigneeIds: List<String>.from(json['assigneeIds'] ?? []),
    assigneeNames: List<String>.from(json['assigneeNames'] ?? []),
    assigneeEmojis: List<String>.from(json['assigneeEmojis'] ?? []),
    projectId: json['projectId'],
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
    isDone: json['isDone'] ?? false,
    priority: TaskPriority.values[json['priority'] ?? 1],
    status: TaskStatus.values[json['status'] ?? 0],
    taskNotes: List<String>.from(json['taskNotes'] ?? []),
    completionReport: json['completionReport'],
  );
}

// -----------------------------------------------------------------------------
// [Team Model]
// -----------------------------------------------------------------------------

@HiveType(typeId: 0)
class Team extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) String inviteCode;
  @HiveField(3) List<String> memberIds;
  @HiveField(4) Map<String, String> memberRoles;

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
    'id': id,
    'name': name,
    'inviteCode': inviteCode,
    'memberIds': memberIds,
    'memberRoles': memberRoles,
  };
}

// -----------------------------------------------------------------------------
// [ChatMessage Model]
// -----------------------------------------------------------------------------

@HiveType(typeId: 7)
class ChatMessage extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String teamId;
  @HiveField(2) final String senderId;
  @HiveField(3) final String senderName;
  @HiveField(4) final String content;
  @HiveField(5) final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    teamId: json['teamId'] ?? '',
    senderId: json['senderId'] ?? '',
    senderName: json['senderName'] ?? '',
    content: json['content'] ?? '',
    sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
  };
}

// -----------------------------------------------------------------------------
// [Other Models] - Project, AppUser, JournalEntry
// -----------------------------------------------------------------------------

@HiveType(typeId: 2)
class Project extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String teamId;
  @HiveField(2) final String name;
  @HiveField(3) final int colorValue;
  Project({required this.id, required this.teamId, required this.name, required this.colorValue});
}

@HiveType(typeId: 5)
class AppUser extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String password;
  @HiveField(2) String name;
  @HiveField(3) String? profileImage;
  AppUser({required this.id, required this.password, required this.name, this.profileImage});
}

@HiveType(typeId: 6)
class JournalEntry extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String teamId;
  @HiveField(2) final String userId;
  @HiveField(3) final String userName;
  @HiveField(4) final String title;
  @HiveField(5) final String content;
  @HiveField(6) String? projectId;
  @HiveField(7) final DateTime date;
  @HiveField(8) DateTime updatedAt;
  @HiveField(9) final List<String> photos;
  @HiveField(10) bool isPrivate;
  JournalEntry({
    required this.id, required this.teamId, required this.userId, required this.userName,
    required this.title, required this.content, this.projectId, required this.date,
    DateTime? updatedAt, required this.photos, this.isPrivate = false,
  }) : updatedAt = updatedAt ?? date;
}
