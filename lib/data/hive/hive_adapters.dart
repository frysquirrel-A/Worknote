import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/domain/models.dart';

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override final int typeId = 0;
  @override TaskPriority read(BinaryReader reader) => TaskPriority.values[reader.readByte()];
  @override void write(BinaryWriter writer, TaskPriority obj) => writer.writeByte(obj.index);
}

class TaskAdapter extends TypeAdapter<Task> {
  @override final int typeId = 1;
  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      teamId: reader.readString(),
      title: reader.readString(),
      creatorId: reader.readString(),
      creatorName: reader.readString(),
      assigneeId: reader.readString(),
      assigneeName: reader.readString(),
      assigneeEmoji: reader.readString(),
      assigneeIds: reader.readStringList(),
      assigneeNames: reader.readStringList(),
      assigneeEmojis: reader.readStringList(),
      projectId: reader.readBool() ? reader.readString() : null,
      createdAt: DateTime.parse(reader.readString()),
      dueDate: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
      completedAt: reader.readBool() ? DateTime.parse(reader.readString()) : null,
      isDone: reader.readBool(),
      priority: TaskPriority.values[reader.readByte()],
      taskNotes: reader.readStringList(),
      completionReport: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.teamId);
    writer.writeString(obj.title);
    writer.writeString(obj.creatorId);
    writer.writeString(obj.creatorName);
    writer.writeString(obj.assigneeId);
    writer.writeString(obj.assigneeName);
    writer.writeString(obj.assigneeEmoji);
    writer.writeStringList(obj.assigneeIds);
    writer.writeStringList(obj.assigneeNames);
    writer.writeStringList(obj.assigneeEmojis);
    writer.writeBool(obj.projectId != null);
    if(obj.projectId != null) writer.writeString(obj.projectId!);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.dueDate.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeBool(obj.completedAt != null);
    if(obj.completedAt != null) writer.writeString(obj.completedAt!.toIso8601String());
    writer.writeBool(obj.isDone);
    writer.writeByte(obj.priority.index);
    writer.writeStringList(obj.taskNotes);
    writer.writeBool(obj.completionReport != null);
    if(obj.completionReport != null) writer.writeString(obj.completionReport!);
  }
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override final int typeId = 2;
  @override Project read(BinaryReader reader) => Project(id: reader.readString(), teamId: reader.readString(), name: reader.readString(), colorValue: reader.readInt());
  @override void write(BinaryWriter writer, Project obj) { writer.writeString(obj.id); writer.writeString(obj.teamId); writer.writeString(obj.name); writer.writeInt(obj.colorValue); }
}

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override final int typeId = 3;
  @override JournalEntry read(BinaryReader reader) => JournalEntry(
    id: reader.readString(), teamId: reader.readString(), userId: reader.readString(), userName: reader.readString(), title: reader.readString(), content: reader.readString(),
    projectId: reader.readBool() ? reader.readString() : null, date: DateTime.parse(reader.readString()), updatedAt: DateTime.parse(reader.readString()), photos: reader.readStringList(), isPrivate: reader.readBool());
  @override void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeString(obj.id); writer.writeString(obj.teamId); writer.writeString(obj.userId); writer.writeString(obj.userName); writer.writeString(obj.title); writer.writeString(obj.content);
    writer.writeBool(obj.projectId != null); if(obj.projectId != null) writer.writeString(obj.projectId!); writer.writeString(obj.date.toIso8601String()); writer.writeString(obj.updatedAt.toIso8601String()); writer.writeStringList(obj.photos); writer.writeBool(obj.isPrivate);
  }
}

class TeamAdapter extends TypeAdapter<Team> {
  @override final int typeId = 4;
  @override
  Team read(BinaryReader reader) {
    return Team(
      id: reader.readString(),
      name: reader.readString(),
      inviteCode: reader.readString(),
      memberIds: reader.readStringList(),
      memberRoles: reader.readMap().cast<String, String>(),
    );
  }
  @override
  void write(BinaryWriter writer, Team obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.inviteCode);
    writer.writeStringList(obj.memberIds);
    writer.writeMap(obj.memberRoles);
  }
}

class AppUserAdapter extends TypeAdapter<AppUser> {
  @override final int typeId = 5;
  @override
  AppUser read(BinaryReader reader) {
    return AppUser(
      id: reader.readString(),
      password: reader.readString(),
      name: reader.readString(),
      profileImage: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.password);
    writer.writeString(obj.name);
    writer.writeBool(obj.profileImage != null);
    if(obj.profileImage != null) writer.writeString(obj.profileImage!);
  }
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override final int typeId = 6;
  @override ChatMessage read(BinaryReader reader) => ChatMessage(id: reader.readString(), teamId: reader.readString(), senderId: reader.readString(), senderName: reader.readString(), content: reader.readString(), sentAt: DateTime.parse(reader.readString()));
  @override void write(BinaryWriter writer, ChatMessage obj) { writer.writeString(obj.id); writer.writeString(obj.teamId); writer.writeString(obj.senderId); writer.writeString(obj.senderName); writer.writeString(obj.content); writer.writeString(obj.sentAt.toIso8601String()); }
}
