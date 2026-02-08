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
  
  bool isDarkMode = true;

  List<Team> get teams => _teams;
  String get currentTeamId => _currentTeamId;
  
  Team get currentTeam {
    if (_teams.isEmpty) {
      return Team(id: 'default', name: '내 워크스페이스', inviteCode: 'START', memberIds: ['me']);
    }
    return _teams.firstWhere(
      (t) => t.id == _currentTeamId, 
      orElse: () => _teams.first
    );
  }

  Future<void> loadTeams() async {
    _teams = _localDb.getAll<Team>('teams');
    
    final lastTeamId = _localDb.getSetting('last_team_id');
    if (lastTeamId != null && _teams.any((t) => t.id == lastTeamId)) {
      _currentTeamId = lastTeamId;
    } else if (_teams.isNotEmpty) {
      _currentTeamId = _teams.first.id;
    }

    if (_teams.isEmpty) {
      await createTeam('메인 프로젝트 팀', isSync: false); 
    }
    notifyListeners();

    try {
      final data = await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
      if (data != null && data.isNotEmpty) {
        _teams = data.map((e) => Team.fromJson(e)).toList();
        await _localDb.syncAll<Team>('teams', _teams, (t) => t.id);
        
        if (!_teams.any((t) => t.id == _currentTeamId)) {
          _currentTeamId = _teams.isNotEmpty ? _teams.first.id : 'default';
          await _localDb.saveSetting('last_team_id', _currentTeamId);
        }
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

  Future<void> createTeam(String name, {bool isSync = true}) async {
    final newTeam = Team(
      id: const Uuid().v4(),
      name: name,
      inviteCode: const Uuid().v4().substring(0, 8).toUpperCase(),
      memberIds: ['me'],
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

  Future<bool> joinTeam(String inviteCode) async {
    if (_teams.any((t) => t.inviteCode == inviteCode)) {
      final joined = _teams.firstWhere((t) => t.inviteCode == inviteCode);
      switchTeam(joined.id);
      return true;
    }

    try {
      final data = await _driveService.readJsonData('worknote_teams.json');
      if (data != null) {
        final cloudTeams = data.map((e) => Team.fromJson(e)).toList();
        final targetTeam = cloudTeams.firstWhere(
          (t) => t.inviteCode == inviteCode, 
          orElse: () => Team(id: '', name: '', inviteCode: '', memberIds: [])
        );

        if (targetTeam.id.isNotEmpty) {
          if (!_teams.any((t) => t.id == targetTeam.id)) {
             _teams.add(targetTeam);
             await _localDb.put<Team>('teams', targetTeam.id, targetTeam);
             switchTeam(targetTeam.id);
             return true;
          }
        }
      }
    } catch (e) {
      print("Join Team Error: $e");
    }
    return false;
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}