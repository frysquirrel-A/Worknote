import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:worknote/domain/models.dart';

/// 로컬 데이터 초기화 + (선택) 샘플 데이터 재주입
/// - 사용자의 계정(users box)은 유지
/// - settings는 logged_in_user_id만 보존
class AppResetService {
  Future<void> reset({
    required bool withSampleData,
    required String myId,
    required String myName,
  }) async {
    // 1) Settings: 로그인 유지
    final settings = Hive.box('settings');
    final loggedIn = settings.get('logged_in_user_id');
    await settings.clear();
    if (loggedIn != null) {
      await settings.put('logged_in_user_id', loggedIn);
    }

    // 2) 도메인 데이터 초기화
    await Hive.box<Task>('tasks').clear();
    await Hive.box<Project>('projects').clear();
    await Hive.box<JournalEntry>('journals').clear();
    await Hive.box<Team>('teams').clear();
    await Hive.box<ChatMessage>('messages').clear();

    // Meta boxes
    await Hive.box('task_meta').clear();
    await Hive.box('journal_meta').clear();
    try {
      await Hive.box('schedules').clear();
    } catch (_) {}

    if (!withSampleData) return;

    // 3) 샘플 데이터 주입
    final now = DateTime.now();
    final teamId = const Uuid().v4();
    final team = Team(
      id: teamId,
      name: '샘플 팀',
      inviteCode: 'SAMPLE',
      memberIds: [myId],
      memberRoles: {myId: '관리자'},
    );
    await Hive.box<Team>('teams').put(team.id, team);
    await settings.put('last_team_id', team.id);

    // Projects
    final p1 = Project(id: const Uuid().v4(), teamId: teamId, name: 'A동 리모델링', colorValue: 0xFF2563EB);
    final p2 = Project(id: const Uuid().v4(), teamId: teamId, name: 'B동 안전 점검', colorValue: 0xFF10B981);
    await Hive.box<Project>('projects').putAll({p1.id: p1, p2.id: p2});

    // Tasks
    final t1 = Task(
      id: const Uuid().v4(),
      teamId: teamId,
      title: '자재 발주 확인',
      creatorId: myId,
      creatorName: myName,
      assigneeId: myId,
      assigneeName: myName,
      assigneeEmoji: '👷',
      projectId: p1.id,
      createdAt: now.subtract(const Duration(days: 2)),
      dueDate: now.add(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 1)),
      priority: TaskPriority.high,
      taskNotes: ['발주서 확인', '납기 일정 공유'],
    );
    final t2 = Task(
      id: const Uuid().v4(),
      teamId: teamId,
      title: '안전모/안전대 재고 점검',
      creatorId: myId,
      creatorName: myName,
      assigneeId: myId,
      assigneeName: myName,
      assigneeEmoji: '👷',
      projectId: p2.id,
      createdAt: now.subtract(const Duration(days: 1)),
      dueDate: now.add(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      priority: TaskPriority.medium,
    );
    await Hive.box<Task>('tasks').putAll({t1.id: t1, t2.id: t2});

    // Task meta (show in schedule by default for sample)
    final taskMeta = Hive.box('task_meta');
    await taskMeta.put(t1.id, {
      'includeInSchedule': true,
      // v5: 일정은 기간(DateTimeRange)로 저장
      'scheduleStart': t1.dueDate.toIso8601String(),
      'scheduleEnd': t1.dueDate.toIso8601String(),
    });
    await taskMeta.put(t2.id, {
      'includeInSchedule': false,
      'scheduleStart': t2.dueDate.toIso8601String(),
      'scheduleEnd': t2.dueDate.toIso8601String(),
    });

    // Personal schedule sample
    try {
      final schedules = Hive.box('schedules');
      final s1 = {
        'id': const Uuid().v4(),
        'teamId': teamId,
        'userId': myId,
        'userName': myName,
        'title': '개인 일정(샘플): 안전 교육',
        'note': '오전 9시, 교육장',
        'start': now.add(const Duration(days: 1)).toIso8601String(),
        'end': now.add(const Duration(days: 1)).toIso8601String(),
        'isAllDay': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      await schedules.put(s1['id'], s1);
    } catch (_) {}

    // Journals
    final j1 = JournalEntry(
      id: const Uuid().v4(),
      teamId: teamId,
      userId: myId,
      userName: myName,
      title: '현장 점검 완료 (샘플)',
      content: 'A동 302호 배관 점검 결과 이상 없습니다. 추가 자재 발주 예정입니다.',
      date: now,
      updatedAt: now,
      photos: const [],
      projectId: p1.id,
      isPrivate: false,
    );
    await Hive.box<JournalEntry>('journals').put(j1.id, j1);

    // Journal meta (sample kinds)
    final journalMeta = Hive.box('journal_meta');
    await journalMeta.put(j1.id, {
      'kind': 'note',
      'relatedTaskId': null,
      'progressUpdates': <Map<String, dynamic>>[],
    });

    // Messages
    final m1 = ChatMessage(
      id: const Uuid().v4(),
      teamId: teamId,
      senderId: myId,
      senderName: myName,
      content: '샘플 팀이 생성되었습니다. 테스트 메시지입니다 🙂',
      sentAt: now.subtract(const Duration(minutes: 3)),
    );
    await Hive.box<ChatMessage>('messages').put(m1.id, m1);
  }
}
