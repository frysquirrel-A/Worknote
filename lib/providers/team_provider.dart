import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../services/drive_service.dart';
import '../services/local_db_service.dart';

class TeamProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  List<Team> _teams = [];
  String _currentTeamId = 'default';
  String _currentThemeMode = 'dark'; 

  List<Team> get teams => _teams;
  String get currentTeamId => _currentTeamId;
  String get currentThemeMode => _currentThemeMode;
  
  Team get currentTeam {
    if (_teams.isEmpty) return Team(id: 'default', name: '내 워크스페이스', inviteCode: 'START', memberIds: ['me'], memberRoles: {'me': '관리자'});
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
    _currentThemeMode = _localDb.getSetting('app_theme', defaultValue: 'dark');
    _teams = _localDb.getAll<Team>('teams');
    final lastTeamId = _localDb.getSetting('last_team_id');
    if (lastTeamId != null && _teams.any((t) => t.id == lastTeamId)) {
      _currentTeamId = lastTeamId;
    } else if (_teams.isNotEmpty) {
      _currentTeamId = _teams.first.id;
    }

    if (_teams.isEmpty) {
      await createTeam('메인 프로젝트 팀', '관리자', isSync: false); 
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
      print("⚠️ 팀 동기화 실패: $e");
    }
  }

  void switchTeam(String teamId) {
    _currentTeamId = teamId;
    _localDb.saveSetting('last_team_id', teamId);
    notifyListeners();
  }

  Future<void> createTeam(String name, String myRole, {bool isSync = true}) async {
    final newTeam = Team(
      id: const Uuid().v4(),
      name: name,
      inviteCode: const Uuid().v4().substring(0, 8).toUpperCase(),
      memberIds: ['me'], 
      memberRoles: {'me': myRole}, 
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

  // [부활] 드라이브 검색을 통한 팀 참여 로직
  Future<bool> joinTeam(String inviteCode, String myId) async {
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
          // 팀 찾음 -> 내 리스트에 추가 및 저장
          _teams.add(targetTeam);
          await _localDb.put<Team>('teams', targetTeam.id, targetTeam);
          switchTeam(targetTeam.id);
          return true;
        }
      }
    } catch (e) {
      print("❌ 팀 참여 에러: $e");
    }
    return false;
  }

  void changeTheme(String mode) {
    _currentThemeMode = mode;
    _localDb.saveSetting('app_theme', mode);
    notifyListeners();
  }
}