import 'dart:math';
import 'package:flutter/material.dart';
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
    try {
      await Hive.box('schedules').clear();
    } catch (_) {}

    if (!withSampleData) return;

    final now = DateTime.now();
    final random = Random();
    final teamId = const Uuid().v4();

    // 1. 샘플 팀 및 멤버 설정
    final team = Team(
      id: teamId,
      name: '마스터피스 건설 팀',
      inviteCode: 'MASTER',
      memberIds: [myId, 'worker01', 'worker02', 'worker03', 'worker04'],
      memberRoles: {
        myId: '현장소장',
        'worker01': '기사',
        'worker02': '안전관리자',
        'worker03': '자재담당',
        'worker04': '공무',
      },
    );
    await Hive.box<Team>('teams').put(team.id, team);
    await settings.put('last_team_id', team.id);

    final users = Hive.box<AppUser>('users');
    final dummyUsers = [
      AppUser(id: 'worker01', password: '1', name: '김현장'),
      AppUser(id: 'worker02', password: '1', name: '박안전'),
      AppUser(id: 'worker03', password: '1', name: '이자재'),
      AppUser(id: 'worker04', password: '1', name: '최공무'),
    ];
    for (var u in dummyUsers) {
      if (!users.containsKey(u.id)) await users.put(u.id, u);
    }

    // 2. 샘플 프로젝트 생성
    final projects = [
      Project(id: 'p1', teamId: teamId, name: 'A동 아파트 신축', colorValue: 0xFF2563EB),
      Project(id: 'p2', teamId: teamId, name: '지하 주차장 공사', colorValue: 0xFF10B981),
      Project(id: 'p3', teamId: teamId, name: '조경 및 외부 마감', colorValue: 0xFFF59E0B),
    ];
    for (var p in projects) {
      await Hive.box<Project>('projects').put(p.id, p);
    }

    // 3. 샘플 업무(Task) 데이터 뻥튀기 (40개 생성)
    final List<String> titleSamples = [
      "회의",
      "자재 확인",
      "현장 점검",
      "도면 검토",
      "이번 주 금요일까지 현장 자재 입고 내역서 및 영수증 취합해서 보고할 것",
      "안전 교육 실시",
      "콘크리트 타설 대기",
      "민원 처리 대응",
      "하도급 업체 계약서 날인 확인 및 서류 일체 본사 제출 요망",
      "폐기물 반출",
      "오후 간식 구매",
      "주간 업무 보고",
      "월간 공정표 수정 및 기성 청구 서류 준비 (상세 내역 포함)",
      "장비 투입 요청",
      "현장 청소",
    ];

    final members = [
      {'id': myId, 'name': myName, 'emoji': '👷'},
      {'id': 'worker01', 'name': '김현장', 'emoji': '👤'},
      {'id': 'worker02', 'name': '박안전', 'emoji': '🛡️'},
      {'id': 'worker03', 'name': '이자재', 'emoji': '📦'},
      {'id': 'worker04', 'name': '최공무', 'emoji': '📑'},
    ];

    final taskBox = Hive.box<Task>('tasks');
    final metaBox = Hive.box('task_meta');

    for (int i = 0; i < 40; i++) {
      final taskId = const Uuid().v4();
      final project = projects[random.nextInt(projects.length)];
      final member = members[random.nextInt(members.length)];
      final priority = TaskPriority.values[random.nextInt(4)];
      final isDone = random.nextBool();
      
      // 날짜 분산 (한 달 전 ~ 한 달 후)
      final dueOffset = random.nextInt(60) - 30;
      final dueDate = now.add(Duration(days: dueOffset));
      final createdAt = now.subtract(Duration(days: random.nextInt(10) + 10));
      
      final task = Task(
        id: taskId,
        teamId: teamId,
        title: "${titleSamples[random.nextInt(titleSamples.length)]} ($i)",
        creatorId: myId,
        creatorName: myName,
        assigneeId: member['id']!,
        assigneeName: member['name']!,
        assigneeEmoji: member['emoji']!,
        projectId: random.nextDouble() > 0.2 ? project.id : null, // 20%는 프로젝트 없음
        createdAt: createdAt,
        dueDate: dueDate,
        updatedAt: isDone ? dueDate.add(const Duration(hours: 2)) : now,
        completedAt: isDone ? dueDate : null,
        isDone: isDone,
        priority: priority,
      );

      await taskBox.put(taskId, task);

      // 스케줄 메타 데이터 랜덤 생성
      final includeInSchedule = random.nextBool();
      if (includeInSchedule) {
        final startOffset = random.nextInt(3);
        final endOffset = startOffset + random.nextInt(5);
        final range = DateTimeRange(
          start: dueDate.subtract(Duration(days: startOffset)),
          end: dueDate.add(Duration(days: endOffset)),
        );
        await metaBox.put(taskId, {
          'includeInSchedule': true,
          'scheduleStart': range.start.toIso8601String(),
          'scheduleEnd': range.end.toIso8601String(),
        });
      } else {
        await metaBox.put(taskId, {'includeInSchedule': false});
      }
    }

    // 4. 샘플 일지 생성
    final j1 = JournalEntry(
      id: 'j1',
      teamId: teamId,
      userId: myId,
      userName: myName,
      title: '현장 사진 샘플 일지',
      content: '데이터 뻥튀기 및 필터 테스트를 위한 자동 생성 데이터입니다.',
      date: now,
      photos: [
        'https://picsum.photos/seed/wn1/800/800',
        'https://picsum.photos/seed/wn2/800/800',
      ],
    );
    await Hive.box<JournalEntry>('journals').put(j1.id, j1);

    // 5. 채팅 샘플
    final threadId = 'grp_${teamId}_sample';
    await Hive.box('chat_threads').put(threadId, {
      'id': threadId,
      'teamId': teamId,
      'type': 'group',
      'title': '현장 소통방',
      'memberIds': [myId, 'worker01', 'worker02'],
      'createdAt': now.toIso8601String(),
    });

    final m1 = ChatMessage(
      id: 'm1',
      teamId: teamId,
      senderId: 'worker01',
      senderName: '김현장',
      content: '오늘 자재 들어왔습니다!',
      sentAt: now.subtract(const Duration(minutes: 30)),
    );
    await Hive.box<ChatMessage>('messages').put(m1.id, m1);
  }
}
