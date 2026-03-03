import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // ✨ [작업 지시] Firebase 비활성화로 인한 주석 처리
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:worknote/core/models/work_profile.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/data/services/local_db_service.dart';

class AuthProvider extends ChangeNotifier {
  // ✨ [작업 지시] Firebase 엔진 직접 호출 차단 (core/no-app 에러 방지)
  // final FirebaseAuth _auth = FirebaseAuth.instance; 
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  // GoogleSignIn은 Firebase와 별개로 동작할 수 있으나 안전을 위해 호출 자제
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  WorkProfile? _currentProfile;
  bool _isLoading = true;

  WorkProfile? get currentProfile => _currentProfile;
  WorkProfile? get currentUser => currentProfile;
  
  String get id => _currentProfile?.id ?? 'local_me';
  String get name => _currentProfile?.name ?? '사용자';
  String? get profileImage => _currentProfile?.profileImage;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentProfile != null;
  bool get isGoogleLinked => _currentProfile?.linkedGoogleEmail != null;

  AuthProvider() {
    print('[Debug] AuthProvider 생성자 호출됨 (Firebase 비활성 모드)');
    _loadStoredProfile();
  }

  Future<void> _loadStoredProfile() async {
    try {
      print('[Debug] 로컬 프로필 로드 시작...');
      final lastId = _localDb.getSetting('logged_in_user_id');
      
      if (lastId != null) {
        print('[Debug] 저장된 로컬 유저 ID 발견: $lastId');
        // 현재는 로컬 모드이므로 null 유지 혹은 간단한 WorkProfile 복구 로직이 들어갈 자리입니다.
      }
    } catch (e) {
      print('[Debug] 프로필 로드 중 에러: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsLocal(String userName) async {
    _setLoading(true);
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _currentProfile = WorkProfile(id: localId, name: userName, isLocal: true);
    await _localDb.saveSetting('logged_in_user_id', localId);
    _setLoading(false);
  }

  Future<void> loginWithGoogle() async {
    // ✨ [작업 지시] Firebase 비활성화에 따른 뼈대만 유지
    print('ℹ️ [AuthProvider] Firebase 기능은 현재 비활성화되어 있습니다.');
    notifyListeners();
  }

  Future<bool> connectGoogleDrive() async {
    print('ℹ️ [AuthProvider] 구글 드라이브 연동 기능은 현재 대기 중입니다.');
    return false;
  }

  Future<bool> loginLocal(String email, String password) async => false;
  Future<bool> signUpLocal(String email, String password, String name) async => false;

  Future<void> logout() async {
    // ✨ [작업 지시] Firebase signOut 호출 제거
    // await _auth.signOut();
    await _googleSignIn.signOut();
    _currentProfile = null;
    _driveService.clearClient();
    await _localDb.saveSetting('logged_in_user_id', null);
    notifyListeners();
  }

  Future<void> updateName(String newName) async {
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(name: newName);
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String? emoji) async {
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(profileImage: emoji);
      notifyListeners();
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
