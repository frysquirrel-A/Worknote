import 'package:flutter/material.dart';
import '../models.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  AppUser? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  AppUser? get currentUser => _currentUser;

  Future<void> loadUsers() async {
    // 초기 로드 로직 (필요 시 구현)
    notifyListeners();
  }

  void login(AppUser user) {
    _isLoggedIn = true;
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}
