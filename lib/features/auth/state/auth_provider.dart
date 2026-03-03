import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'package:worknote/domain/models.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/data/services/local_db_service.dart';

// ✨ [작업 지시 1] Firebase User 객체를 기존 UI 규격(id, name 등)으로 변환하는 통역기
extension FirebaseUserExtension on User {
  String get id => uid;
  String get name => displayName ?? '사용자';
  String? get profileImage => photoURL;
}

class AuthProvider extends ChangeNotifier {
  // ✨ [작업 지시 2] Firebase Auth 인스턴스 배치
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
  
  bool _isLoading = false;
  bool _isGoogleLinked = false;

  // ✨ 기존 UI가 쓰던 변수명 그대로 유지
  bool get isLoading => _isLoading;
  bool get isGoogleLinked => _isGoogleLinked;
  
  // ✨ Firebase 유저를 반환하지만, 위에서 만든 Extension 덕분에 id, name 등으로 접근 가능함
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  AuthProvider() {
    // 앱 시작 시 로그인 상태 변경 감지
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  // ✨ [작업 지시 3] 기존 메서드 이름과 반환 타입 완벽 유지 (loginLocal)
  Future<bool> loginLocal(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        await _localDb.saveSetting('logged_in_user_id', credential.user!.uid);
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('🚨 로그인 실패: $e');
    }
    _setLoading(false);
    return false;
  }

  // ✨ [작업 지시 3] 기존 메서드 이름과 반환 타입 완벽 유지 (signUpLocal)
  Future<bool> signUpLocal(String email, String password, String name) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 가입 성공 시 이름(DisplayName) 즉시 업데이트
        await credential.user!.updateDisplayName(name);
        await _localDb.saveSetting('logged_in_user_id', credential.user!.uid);
        
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('🚨 회원가입 실패: $e');
    }
    _setLoading(false);
    return false;
  }

  // ✨ [작업 지시 3] 이름 수정 기능 복구
  Future<void> updateName(String newName) async {
    if (currentUser != null) {
      try {
        await currentUser!.updateDisplayName(newName);
        notifyListeners();
      } catch (e) {
        debugPrint('🚨 이름 업데이트 실패: $e');
      }
    }
  }

  // ✨ [작업 지시 3] 프로필 이미지(에모지) 수정 기능 복구
  Future<void> updateProfileImage(String? emoji) async {
    if (currentUser != null && emoji != null) {
      try {
        await currentUser!.updatePhotoURL(emoji);
        notifyListeners();
      } catch (e) {
        debugPrint('🚨 프로필 이미지 업데이트 실패: $e');
      }
    }
  }

  // ✨ [작업 지시 3] 로그아웃 기능 복구
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _isGoogleLinked = false;
      _driveService.clearClient();
      await _localDb.saveSetting('logged_in_user_id', null);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 로그아웃 실패: $e');
    }
  }

  // 구글 드라이브 연동 (기존 뼈대 유지)
  Future<bool> connectGoogleDrive() async {
    try {
      _setLoading(true);
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final httpClient = await _googleSignIn.authenticatedClient();
        if (httpClient != null) {
             _driveService.setClient(httpClient);
            _isGoogleLinked = true;
            notifyListeners();
            _setLoading(false);
            return true;
        }
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
