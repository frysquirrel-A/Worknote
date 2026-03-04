import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:worknote/domain/models.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/data/services/local_db_service.dart';

class TeamProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  List<Team> _teams = [];
  String _currentTeamId = 'default';
  String _currentThemeMode = 'light'; 

  List<Team> get teams => _teams;
  String get currentTeamId => _currentTeamId;
  String get currentThemeMode => _currentThemeMode;
  
  Team get currentTeam {
    if (_teams.isEmpty) {
      return Team(
        id: 'default',
        name: '내 워크스페이스',
        inviteCode: 'START',
        memberIds: ['me'],
        memberRoles: {'me': '관리자'},
      );
    }
    return _teams.firstWhere((t) => t.id == _currentTeamId, orElse: () => _teams.first);
  }

  String getMyRole(String userId) {
    return currentTeam.memberRoles[userId] ?? '팀원';
  }

  Future<void> updateMyRole(String userId, String newRole) async {
    currentTeam.memberRoles[userId] = newRole;
    notifyListeners();
    await _localDb.put<Team>('teams', currentTeam.id, currentTeam);
    await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
  }

  Future<void> loadTeams() async {
    _currentThemeMode = _localDb.getSetting('app_theme', defaultValue: 'light');
    _teams = _localDb.getAll<Team>('teams');
    final lastTeamId = _localDb.getSetting('last_team_id');
    if (lastTeamId != null && _teams.any((t) => t.id == lastTeamId)) {
      _currentTeamId = lastTeamId;
    } else if (_teams.isNotEmpty) {
      _currentTeamId = _teams.first.id;
    }

    if (_teams.isEmpty) {
      final myId = (_localDb.getSetting('logged_in_user_id') ?? 'me').toString();
      await createTeam('메인 프로젝트 팀', myId: myId, myRole: '관리자', isSync: false);
    }
    notifyListeners();

    try {
      final data = await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
      if (data != null && data.isNotEmpty) {
        _teams = data.map((e) => Team.fromJson(e)).toList();
        await _localDb.syncAll<Team>('teams', _teams, (t) => t.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ 팀 동기화 실패: $e");
    }
  }

  void switchTeam(String teamId) {
    _currentTeamId = teamId;
    _localDb.saveSetting('last_team_id', teamId);
    notifyListeners();
  }

  Future<void> createTeam(
    String name, {
    required String myId,
    required String myRole,
    bool isSync = true,
  }) async {
    final newTeam = Team(
      id: const Uuid().v4(),
      name: name,
      inviteCode: const Uuid().v4().substring(0, 8).toUpperCase(),
      memberIds: [myId],
      memberRoles: {myId: myRole},
    );
    
    _teams.add(newTeam);
    _currentTeamId = newTeam.id;
    await _localDb.put<Team>('teams', newTeam.id, newTeam);
    await _localDb.saveSetting('last_team_id', newTeam.id);
    notifyListeners();

    if (isSync) {
      await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
    }
  }

  Future<void> regenerateInviteCode(String teamId) async {
    final idx = _teams.indexWhere((t) => t.id == teamId);
    if (idx < 0) return;
    _teams[idx].inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
    await _localDb.put<Team>('teams', _teams[idx].id, _teams[idx]);
    notifyListeners();
    if (_driveService.isReady) {
      await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
    }
  }

  /// 팀 참여 (Drive에 저장된 worknote_teams.json 기준)
  /// - 같은 구글 계정(또는 같은 Drive 파일 접근)에서만 동작하는 방식임.
  /// - 참여 시 memberIds에 내 id를 추가하고, memberRoles 기본값은 '팀원'
  Future<bool> joinTeam(String inviteCode, String myId, {String myRole = '팀원'}) async {
    // 1. 이미 가입된 팀인지 확인
    if (_teams.any((t) => t.inviteCode == inviteCode)) {
      switchTeam(_teams.firstWhere((t) => t.inviteCode == inviteCode).id);
      return true;
    }

    // 2. 드라이브에서 해당 코드를 가진 팀 검색
    try {
      final data = await _driveService.readJsonData('worknote_teams.json');
      if (data != null) {
        final cloudTeams = data.map((e) => Team.fromJson(e)).toList();
        final targetTeam = cloudTeams.firstWhere(
          (t) => t.inviteCode == inviteCode, 
          orElse: () => Team(id: '', name: '', inviteCode: '', memberIds: [])
        );

        if (targetTeam.id.isNotEmpty) {
          if (!targetTeam.memberIds.contains(myId)) {
            targetTeam.memberIds.add(myId);
          }
          targetTeam.memberRoles[myId] = targetTeam.memberRoles[myId] ?? myRole;

          // 팀 찾음 -> 내 리스트에 추가 및 저장
          _teams.add(targetTeam);
          await _localDb.put<Team>('teams', targetTeam.id, targetTeam);
          switchTeam(targetTeam.id);

          // 참여 결과를 Drive에도 반영 (가능하면)
          if (_driveService.isReady) {
            await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint("❌ 팀 참여 에러: $e");
    }
    return false;
  }

  /// 레거시 데이터('me' 하드코딩) 마이그레이션
  /// - 팀 memberIds/memberRoles 안의 'me'를 실제 myId로 치환
  Future<void> migrateLegacyMeToUser(String myId, {String myRoleFallback = '관리자'}) async {
    bool changed = false;
    for (final t in _teams) {
      if (t.memberIds.contains('me') && !t.memberIds.contains(myId)) {
        t.memberIds = [...t.memberIds.where((e) => e != 'me'), myId];
        changed = true;
      } else if (t.memberIds.contains('me') && t.memberIds.contains(myId)) {
        t.memberIds = t.memberIds.where((e) => e != 'me').toList();
        changed = true;
      }

      if (t.memberRoles.containsKey('me') && !t.memberRoles.containsKey(myId)) {
        t.memberRoles[myId] = t.memberRoles['me'] ?? myRoleFallback;
        t.memberRoles.remove('me');
        changed = true;
      } else if (t.memberRoles.containsKey('me') && t.memberRoles.containsKey(myId)) {
        t.memberRoles.remove('me');
        changed = true;
      }

      t.memberRoles[myId] = t.memberRoles[myId] ?? myRoleFallback;
    }

    if (!changed) return;

    await _localDb.syncAll<Team>('teams', _teams, (t) => t.id);
    notifyListeners();
    if (_driveService.isReady) {
      await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
    }
  }


  Future<void> ensureCurrentUserMembership(String userId, {String defaultRole = '관리자'}) async {
    bool changed = false;
    for (final team in _teams) {
      if (!team.memberIds.contains(userId)) {
        team.memberIds = [...team.memberIds, userId];
        changed = true;
      }
      if (!team.memberRoles.containsKey(userId)) {
        team.memberRoles[userId] = defaultRole;
        changed = true;
      }
    }
    if (!changed) return;
    await _localDb.syncAll<Team>('teams', _teams, (t) => t.id);
    notifyListeners();
    if (_driveService.isReady) {
      await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
    }
  }

  void changeTheme(String mode) {
    _currentThemeMode = mode;
    _localDb.saveSetting('app_theme', mode);
    notifyListeners();
  }
}