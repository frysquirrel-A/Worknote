import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/domain/models.dart';

class AppResetService {
  Future<void> reset({required bool withSampleData, required String myId, required String myName}) async {
    final settings = Hive.box('settings');
    final loggedIn = settings.get('logged_in_user_id');
    final authProfiles = settings.get('auth_profiles_v2');
    final currentProfileId = settings.get('auth_current_profile_id');
    await settings.clear();
    if (loggedIn != null) await settings.put('logged_in_user_id', loggedIn);
    if (authProfiles != null) await settings.put('auth_profiles_v2', authProfiles);
    if (currentProfileId != null) await settings.put('auth_current_profile_id', currentProfileId);

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
    final random = Random();
    final usersBox = Hive.box<AppUser>('users');

    // ✨ 팀별로 완전히 독립된 팀원과 역할/프로젝트 정의
    final teamDefinitions = [
      {
        'name': '마스터피스 건설 팀',
        'projects': ['A동 신축 공사', '지하 주차장 공사', '조경 및 마감'],
        'users': [
          {'id': '${myId}_w1', 'name': '김현장', 'role': '기사', 'emoji': '👷'},
          {'id': '${myId}_w2', 'name': '박안전', 'role': '안전관리자', 'emoji': '🛡️'},
          {'id': '${myId}_w3', 'name': '이자재', 'role': '자재담당', 'emoji': '📦'},
          {'id': '${myId}_w4', 'name': '최공무', 'role': '공무', 'emoji': '📑'},
        ]
      },
      {
        'name': '가족 모임 (본가)',
        'projects': ['어머니 환갑 잔치 준비', '여름 휴가 계획'],
        'users': [
          {'id': '${myId}_f1', 'name': '김동생', 'role': '막내', 'emoji': '👧'},
          {'id': '${myId}_f2', 'name': '이형님', 'role': '총무', 'emoji': '👨'},
          {'id': '${myId}_f3', 'name': '박매제', 'role': '운전기사', 'emoji': '🚗'},
        ]
      },
      {
        'name': '개발 동아리',
        'projects': ['WorkNote 앱 출시', '백엔드 서버 리팩토링', '랜딩 페이지 제작'],
        'users': [
          {'id': '${myId}_d1', 'name': '박프론트', 'role': '리드', 'emoji': '💻'},
          {'id': '${myId}_d2', 'name': '최서버', 'role': '인프라', 'emoji': '🔋'},
          {'id': '${myId}_d3', 'name': '정디쟌', 'role': 'UI/UX', 'emoji': '🎨'},
        ]
      },
    ];

    bool isFirstTeam = true;
    final taskBox = Hive.box<Task>('tasks');
    final metaBox = Hive.box('task_meta');

    for (var def in teamDefinitions) {
      final teamId = const Uuid().v4();
      final tName = def['name'] as String;
      final tUsers = def['users'] as List<Map<String, String>>;
      final tProjects = def['projects'] as List<String>;

      // 1. 유저 생성 및 팀원 목록 구성
      List<String> memberIds = [myId];
      Map<String, String> memberRoles = {myId: '방장'};
      List<Map<String, String>> membersForTask = [{'id': myId, 'name': myName, 'emoji': '😎'}];

      for (var u in tUsers) {
        final uid = u['id']!;
        if (!usersBox.containsKey(uid)) {
          await usersBox.put(uid, AppUser(id: uid, password: '1', name: u['name']!));
        }
        memberIds.add(uid);
        memberRoles[uid] = u['role']!;
        membersForTask.add(u);
      }

      // 2. 팀 저장
      final team = Team(id: teamId, name: tName, inviteCode: 'CODE_${random.nextInt(9999)}', memberIds: memberIds, memberRoles: memberRoles);
      await Hive.box<Team>('teams').put(team.id, team);
      
      if (isFirstTeam) {
        await settings.put('last_team_id', team.id);
        isFirstTeam = false;
      }

      // 3. 독립된 프로젝트 생성
      List<Project> createdProjects = [];
      final colors = [0xFF2563EB, 0xFF10B981, 0xFFF59E0B, 0xFF8B5CF6];
      for (int i = 0; i < tProjects.length; i++) {
        final p = Project(id: const Uuid().v4(), teamId: teamId, name: tProjects[i], colorValue: colors[i % colors.length]);
        await Hive.box<Project>('projects').put(p.id, p);
        createdProjects.add(p);
      }

      // 4. 팀별 20개의 샘플 업무 생성
      final List<String> titleSamples = ["진행 상황 체크", "관련 자료 조사", "일정 컨펌 받기", "공유 문서 정리", "예산안 작성", "피드백 반영", "현장/오프라인 모임"];
      
      for (int i = 0; i < 20; i++) {
        final taskId = const Uuid().v4();
        final project = createdProjects[random.nextInt(createdProjects.length)];
        final member = membersForTask[random.nextInt(membersForTask.length)];
        final priority = TaskPriority.values[random.nextInt(4)];
        final isDone = random.nextBool();
        final dueOffset = random.nextInt(60) - 30; 
        final dueDate = now.add(Duration(days: dueOffset));
        final createdAt = dueDate.subtract(Duration(days: random.nextInt(10) + 1));
        
        final task = Task(id: taskId, teamId: teamId, title: "${titleSamples[random.nextInt(titleSamples.length)]} ($i)", creatorId: myId, creatorName: myName, assigneeId: member['id']!, assigneeName: member['name']!, assigneeEmoji: member['emoji'] ?? '👤', projectId: random.nextDouble() > 0.15 ? project.id : null, createdAt: createdAt, dueDate: dueDate, updatedAt: isDone ? dueDate.add(const Duration(hours: 2)) : createdAt, completedAt: isDone ? dueDate : null, isDone: isDone, priority: priority);
        await taskBox.put(taskId, task);

        final includeInSchedule = random.nextDouble() > 0.4;
        if (includeInSchedule) {
          final startOffset = random.nextInt(3);
          final endOffset = startOffset + random.nextInt(3);
          final range = DateTimeRange(start: dueDate.subtract(Duration(days: startOffset)), end: dueDate.add(Duration(days: endOffset)));
          await metaBox.put(taskId, {'planInclude': true, 'scheduleInclude': true, 'scheduleStart': range.start.toIso8601String(), 'scheduleEnd': range.end.toIso8601String()});
        } else {
          await metaBox.put(taskId, {'planInclude': true, 'scheduleInclude': false});
        }
      }

      final j1 = JournalEntry(id: const Uuid().v4(), teamId: teamId, userId: myId, userName: myName, title: '샘플 일지 ($tName)', content: '자동 생성된 데이터입니다.', date: now, photos: ['https://picsum.photos/seed/${random.nextInt(100)}/800/800']);
      await Hive.box<JournalEntry>('journals').put(j1.id, j1);
    }
  }
}
