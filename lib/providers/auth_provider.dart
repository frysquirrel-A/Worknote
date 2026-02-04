import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models.dart';
import '../services/drive_service.dart';

class AuthProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    'https://www.googleapis.com/auth/drive.file',
  ]);
  
  List<AppUser> _users = [];
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isGoogleLinked = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isGoogleLinked => _isGoogleLinked;

  // 1. 로컬 로그인 (김반장 강제 소환)
  Future<bool> loginLocal(String id, String password) async {
    _setLoading(true);
    try {
      // [복구] 무조건 '김반장'으로 로그인되도록 수정 (테스트용)
      _currentUser = AppUser(
        id: id, 
        password: password, 
        name: "김반장", // 이름 고정
        role: "현장소장", // 직책 고정
        profileImage: null
      );
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // 2. 회원가입
  Future<bool> signUpLocal(String id, String password, String name, String role) async {
    _setLoading(true);
    final newUser = AppUser(id: id, password: password, name: name, role: role);
    _users.add(newUser);
    _currentUser = newUser;
    notifyListeners();
    _setLoading(false);
    return true;
  }

  // 3. 구글 연동
  Future<bool> connectGoogleDrive() async {
    try {
      _setLoading(true);
      final account = await _googleSignIn.signIn();
      if (account != null) {
        // 구글 로그인 성공 시, DriveService 초기화
        final authHeaders = await account.authHeaders;
        final client = GoogleAuthClient(authHeaders);
        _driveService.setClient(client);
        
        _isGoogleLinked = true;
        notifyListeners();
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      print("Google Sign In Error: $e");
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isGoogleLinked = false;
    _googleSignIn.signOut();
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}