import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../services/drive_service.dart';

class TeamProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  
  // --- States ---
  List<Team> _teams = [];
  String _currentTeamId = 'default';
  
  // Settings
  bool isDarkMode = true; // 다크모드 기본값
  bool isWifiOnly = true; // 와이파이 동기화 기본값

  // --- Getters ---
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

  // --- Actions ---
  
  // 1. 초기화 (앱 시작 시 호출)
  Future<void> loadTeams() async {
    // 드라이브에서 팀 목록 동기화
    final data = await _driveService.syncJsonData(
      _teams.map((e) => e.toJson()).toList(), 
      'worknote_teams.json'
    );
    
    if (data != null && data.isNotEmpty) {
      _teams = data.map((e) => Team.fromJson(e)).toList();
    } else if (_teams.isEmpty) {
      // 초기 팀 생성
      createTeam('메인 프로젝트 팀');
    }
    notifyListeners();
  }

  // 2. 팀 변경
  void switchTeam(String teamId) {
    _currentTeamId = teamId;
    notifyListeners();
  }

  // 3. 새 팀 생성
  void createTeam(String name) {
    final newTeam = Team(
      id: const Uuid().v4(),
      name: name,
      inviteCode: const Uuid().v4().substring(0, 8).toUpperCase(),
      memberIds: ['me'],
    );
    _teams.add(newTeam);
    _currentTeamId = newTeam.id; // 생성 후 바로 이동
    _sync(); // 저장
    notifyListeners();
  }

  // 4. 설정 변경
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void setWifiOnly(bool val) {
    isWifiOnly = val;
    notifyListeners();
  }

  // 내부 저장 함수
  Future<void> _sync() async {
    await _driveService.syncJsonData(
      _teams.map((e) => e.toJson()).toList(), 
      'worknote_teams.json'
    );
  }
}
