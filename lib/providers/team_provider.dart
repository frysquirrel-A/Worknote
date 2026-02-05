import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/drive_service.dart';

class TeamProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  
  List<Team> _teams = [];
  String _currentTeamId = 'default';
  
  bool isDarkMode = true;
  bool isWifiOnly = true;

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

  List<String> get teamMembers => currentTeam.memberIds;

  Future<void> loadTeams() async {
    final data = await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
    
    if (data != null && data.isNotEmpty) {
      _teams = data.map((e) => Team.fromJson(e)).toList();
    } else if (_teams.isEmpty) {
      createTeam('메인 프로젝트 팀');
    }
    notifyListeners();
  }

  void switchTeam(String teamId) {
    _currentTeamId = teamId;
    notifyListeners();
  }

  void createTeam(String name) {
    final newTeam = Team(
      id: const Uuid().v4(),
      name: name,
      inviteCode: const Uuid().v4().substring(0, 8).toUpperCase(),
      memberIds: ['김반장', '이대리', '박기사'],
    );
    _teams.add(newTeam);
    _currentTeamId = newTeam.id;
    _sync();
    notifyListeners();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  Future<void> _sync() async {
    await _driveService.syncJsonData(_teams.map((e) => e.toJson()).toList(), 'worknote_teams.json');
  }
}
