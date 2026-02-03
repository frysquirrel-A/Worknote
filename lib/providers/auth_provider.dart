import 'package:flutter/material.dart';
import '../models.dart';
import '../services/drive_service.dart';

class AuthProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  
  List<AppUser> _users = [];
  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // 1. 유저 데이터 불러오기
  Future<void> loadUsers() async {
    _setLoading(true);
    final data = await _driveService.syncJsonData(
      _users.map((e) => e.toJson()).toList(), 
      'worknote_users.json'
    );
    
    if (data != null) {
      _users = data.map((e) => AppUser.fromJson(e)).toList();
    }
    _setLoading(false);
  }

  // 2. 로그인 (ID, PW 두 개를 받아야 함!)
  Future<bool> login(String id, String password) async {
    _setLoading(true);
    await loadUsers(); // 최신 데이터 확인
    
    try {
      // ID와 비밀번호가 모두 일치하는 유저 찾기
      final user = _users.firstWhere(
        (u) => u.id == id && u.password == password,
      );
      _currentUser = user;
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false; // 로그인 실패
    }
  }

  // 3. 회원가입
  Future<bool> signUp(String id, String password, String name, String role) async {
    _setLoading(true);
    await loadUsers();

    // ID 중복 체크
    if (_users.any((u) => u.id == id)) {
      _setLoading(false);
      return false;
    }

    final newUser = AppUser(id: id, password: password, name: name, role: role);
    _users.add(newUser);
    
    // 드라이브 저장
    await _driveService.syncJsonData(
      _users.map((e) => e.toJson()).toList(), 
      'worknote_users.json'
    );

    // 가입 후 자동 로그인
    _currentUser = newUser;
    notifyListeners();
    _setLoading(false);
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
