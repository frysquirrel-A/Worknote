import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../services/drive_service.dart';
import '../services/local_db_service.dart';

class AuthProvider extends ChangeNotifier {
  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService(); 
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    drive.DriveApi.driveFileScope,
  ]);
  
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isGoogleLinked = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isGoogleLinked => _isGoogleLinked;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final lastUserId = _localDb.getSetting('logged_in_user_id');
    if (lastUserId != null) {
      final savedUser = Hive.box<AppUser>('users').get(lastUserId);
      if (savedUser != null) {
        _currentUser = savedUser;
        notifyListeners();
      }
    }
  }

  Future<bool> loginLocal(String id, String password) async {
    _setLoading(true);
    final user = Hive.box<AppUser>('users').get(id);
    
    if (user != null && user.password == password) {
      _currentUser = user;
      await _localDb.saveSetting('logged_in_user_id', id);
      notifyListeners();
      _setLoading(false);
      return true;
    } else {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpLocal(String id, String password, String name, String role) async {
    _setLoading(true);
    if (Hive.box<AppUser>('users').containsKey(id)) {
      _setLoading(false);
      return false;
    }

    final newUser = AppUser(
      id: id, 
      password: password, 
      name: name, 
      role: role,
      profileImage: null
    );
    
    await _localDb.put<AppUser>('users', id, newUser);
    _currentUser = newUser;
    await _localDb.saveSetting('logged_in_user_id', id);

    notifyListeners();
    _setLoading(false);
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isGoogleLinked = false;
    await _localDb.saveSetting('logged_in_user_id', null);
    await _googleSignIn.signOut();
    notifyListeners();
  }

  Future<bool> connectGoogleDrive() async {
    try {
      _setLoading(true);
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final authHeaders = await account.authHeaders;
        final client = GoogleAuthClient(authHeaders);
        _driveService.setClient(client);
        _isGoogleLinked = true;
        notifyListeners();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print("Google Sign In Error: $e");
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
