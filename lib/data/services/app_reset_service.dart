import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/domain/models.dart';

class AppResetService {
  Future<void> reset({
    required bool withSampleData,
    required String myId,
    required String myName,
  }) async {
    final settings = Hive.box('settings');
    final loggedIn = settings.get('logged_in_user_id');
    await settings.clear();
    if (loggedIn != null) await settings.put('logged_in_user_id', loggedIn);

    await Hive.box<Task>('tasks').clear();
    await Hive.box<Project>('projects').clear();
    await Hive.box<JournalEntry>('journals').clear();
    await Hive.box<Team>('teams').clear();
    await Hive.box<ChatMessage>('messages').clear();
    await Hive.box('chat_threads').clear();
    await Hive.box('task_meta').clear();
    await Hive.box('journal_meta').clear();
    try { await Hive.box('schedules').clear(); } catch (_) {}

    if (!withSampleData) return;

    final now = DateTime.now();
    final teamId = const Uuid().v4();
    final team = Team(
      id: teamId, name: '샘플 팀', inviteCode: 'SAMPLE',
      memberIds: [myId, 'worker01', 'worker02', 'worker03'],
      memberRoles: {myId: '관리자', 'worker01': '팀원', 'worker02': '안전', 'worker03': '자재'},
    );
    await Hive.box<Team>('teams').put(team.id, team);
    await settings.put('last_team_id', team.id);

    final users = Hive.box<AppUser>('users');
    final dummyUsers = [
      AppUser(id: 'worker01', password: '1', name: '김현장'),
      AppUser(id: 'worker02', password: '1', name: '박안전'),
      AppUser(id: 'worker03', password: '1', name: '이자재'),
    ];
    for (var u in dummyUsers) { if (!users.containsKey(u.id)) await users.put(u.id, u); }

    final p1 = Project(id: 'p1', teamId: teamId, name: '현장 시공', colorValue: 0xFF2563EB);
    await Hive.box<Project>('projects').put(p1.id, p1);

    final t1 = Task(
      id: 't1', teamId: teamId, title: '자재 입고 확인', creatorId: myId, creatorName: myName,
      assigneeId: 'worker03', assigneeName: '이자재', assigneeEmoji: '📦', projectId: p1.id,
      createdAt: now.subtract(const Duration(days: 1)), dueDate: now.add(const Duration(days: 2)),
      priority: TaskPriority.high,
    );
    await Hive.box<Task>('tasks').put(t1.id, t1);

    final j1 = JournalEntry(
      id: 'j1', teamId: teamId, userId: myId, userName: myName, title: '갤러리 샘플 일지',
      content: '샘플 사진이 포함된 일지입니다.', date: now, photos: [
        'https://picsum.photos/seed/wn1/800/800',
        'https://picsum.photos/seed/wn2/800/800',
      ],
    );
    await Hive.box<JournalEntry>('journals').put(j1.id, j1);

    final threadId = 'grp_${teamId}_sample';
    await Hive.box('chat_threads').put(threadId, {
      'id': threadId, 'teamId': teamId, 'type': 'group', 'title': '안전 점검 단톡방',
      'memberIds': [myId, 'worker02'], 'createdAt': now.toIso8601String(),
    });

    final m1 = ChatMessage(id: 'm1', teamId: teamId, senderId: 'worker01', senderName: '김현장', content: '안녕하세요!', sentAt: now);
    final m2 = ChatMessage(id: 'm2', teamId: threadId, senderId: 'worker02', senderName: '박안전', content: '그룹방 테스트입니다.', sentAt: now);
    await Hive.box<ChatMessage>('messages').putAll({'m1': m1, 'm2': m2});
  }
}
