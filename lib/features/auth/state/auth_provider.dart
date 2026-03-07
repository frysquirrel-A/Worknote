import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'package:worknote/core/models/work_profile.dart';
import 'package:worknote/data/services/drive_service.dart';
import 'package:worknote/data/services/local_db_service.dart';
import 'package:worknote/domain/models.dart';

enum AuthFlowState {
  signedIn,
  requiresProfileSetup,
  requiresProfileSelection,
  bridgeCompleted,
  cancelled,
  failed,
}

class AuthFlowResult {
  final AuthFlowState state;
  final String? message;

  const AuthFlowResult(this.state, {this.message});

  bool get ok => state != AuthFlowState.failed && state != AuthFlowState.cancelled;
}

class AuthProvider extends ChangeNotifier {
  static const String _profilesKey = 'auth_profiles_v2';
  static const String _currentProfileIdKey = 'auth_current_profile_id';
  static const int _maxGoogleSlots = 5;

  final DriveService _driveService = DriveService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'email',
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
    ],
  );

  final List<WorkProfile> _profiles = <WorkProfile>[];
  WorkProfile? _currentProfile;
  bool _isLoading = true;

  // 구글 로그인 후 슬롯 선택용 임시 상태
  String? _pendingGoogleEmail;
  String? _pendingGoogleDisplayName;
  String? _pendingGooglePhotoUrl;

  // ---- Public getters ----
  WorkProfile? get currentProfile => _currentProfile;
  WorkProfile? get currentUser => currentProfile;

  String get id => _currentProfile?.id ?? 'local_me';
  String get name => _currentProfile?.name ?? '사용자';
  String? get profileImage => _currentProfile?.profileImage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentProfile != null;
  bool get isGoogleLinked => (_currentProfile?.linkedGoogleEmail ?? '').trim().isNotEmpty;
  bool get isDriveConnected => _driveService.isReady;
  bool get needsProfileSetup => _currentProfile != null && _currentProfile!.needsNameSetup;

  bool get hasPendingGoogleSelection => (_pendingGoogleEmail ?? '').trim().isNotEmpty;
  String? get pendingGoogleEmail => _pendingGoogleEmail;
  String? get pendingGoogleDisplayName => _pendingGoogleDisplayName;
  String? get pendingGooglePhotoUrl => _pendingGooglePhotoUrl;

  List<WorkProfile> get profiles => List.unmodifiable(_profiles);
  int get maxGoogleSlots => _maxGoogleSlots;

  List<WorkProfile> get pendingGoogleProfiles {
    final email = _pendingGoogleEmail;
    if (email == null || email.trim().isEmpty) return const <WorkProfile>[];
    return profilesForGoogleEmail(email);
  }

  AuthProvider() {
    debugPrint('[Auth] AuthProvider 초기화 시작');
    _loadStoredProfile();
  }

  // ---------------------------------------------------------------------------
  // Storage bootstrap
  // ---------------------------------------------------------------------------

  Future<void> _loadStoredProfile() async {
    _setLoading(true, notify: false);
    try {
      final rawProfiles = _localDb.getSetting(_profilesKey, defaultValue: <dynamic>[]);
      _profiles
        ..clear()
        ..addAll(_decodeProfiles(rawProfiles));

      final String? currentId = _localDb.getSetting(_currentProfileIdKey);
      if (currentId != null) {
        _currentProfile = _profiles.cast<WorkProfile?>().firstWhere((p) => p?.id == currentId, orElse: () => null);
      }

      _currentProfile ??= _profiles.isNotEmpty ? _profiles.first : null;

      if (_currentProfile != null) {
        await _persistCurrentProfileId(_currentProfile!.id);
        await _syncProfileToUsersBox(_currentProfile!);
        await _restoreDriveConnectionIfPossible();
      } else {
        _driveService.clearClient();
      }
    } catch (e, st) {
      debugPrint('[Auth] 프로필 로드 실패: $e\n$st');
    } finally {
      _setLoading(false);
    }
  }

  List<WorkProfile> _decodeProfiles(dynamic raw) {
    if (raw is! List) return <WorkProfile>[];
    return raw
        .whereType<Map>()
        .map((e) => WorkProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));
  }

  Future<void> _persistProfiles() async {
    await _localDb.saveSetting(_profilesKey, _profiles.map((e) => e.toJson()).toList());
  }

  Future<void> _persistCurrentProfileId(String? id) async {
    await _localDb.saveSetting(_currentProfileIdKey, id);
    await _localDb.saveSetting('logged_in_user_id', id);
  }

  Future<void> _activateProfile(WorkProfile? profile, {bool restoreDrive = true}) async {
    _currentProfile = profile;
    await _persistCurrentProfileId(profile?.id);
    if (profile != null) {
      await _syncProfileToUsersBox(profile);
      if (restoreDrive) {
        await _restoreDriveConnectionIfPossible();
      }
    } else {
      _driveService.clearClient();
    }
    notifyListeners();
  }

  Future<void> _syncProfileToUsersBox(WorkProfile profile) async {
    try {
      if (!Hive.isBoxOpen('users')) return;
      final box = Hive.box<AppUser>('users');
      final existing = box.get(profile.id);
      final name = profile.name.trim().isEmpty ? '사용자' : profile.name.trim();
      final user = existing ?? AppUser(id: profile.id, password: '', name: name, profileImage: profile.profileImage);
      user.name = name;
      user.profileImage = profile.profileImage;
      await box.put(profile.id, user);
    } catch (e) {
      debugPrint('[Auth] users box 동기화 실패: $e');
    }
  }

  Future<void> _restoreDriveConnectionIfPossible() async {
    final profile = _currentProfile;
    if (profile == null || !profile.isGoogleProfile) {
      _driveService.clearClient();
      return;
    }

    try {
      final silent = await _googleSignIn.signInSilently();
      if (silent == null) {
        _driveService.clearClient();
        return;
      }
      if (silent.email != profile.linkedGoogleEmail) {
        _driveService.clearClient();
        return;
      }
      final client = await _googleSignIn.authenticatedClient();
      if (client != null) {
        _driveService.setClient(client);
      } else {
        _driveService.clearClient();
      }
    } catch (e) {
      debugPrint('[Auth] Drive 세션 복구 실패: $e');
      _driveService.clearClient();
    }
  }

  void _setLoading(bool value, {bool notify = true}) {
    _isLoading = value;
    if (notify) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Query helpers
  // ---------------------------------------------------------------------------

  List<WorkProfile> profilesForGoogleEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final list = _profiles.where((p) => (p.linkedGoogleEmail ?? '').trim().toLowerCase() == normalized).toList();
    list.sort((a, b) => (a.slotIndex ?? 999).compareTo(b.slotIndex ?? 999));
    return list;
  }

  int? _firstAvailableSlot(String email) {
    final used = profilesForGoogleEmail(email).map((e) => e.slotIndex).whereType<int>().toSet();
    for (int i = 0; i < _maxGoogleSlots; i++) {
      if (!used.contains(i)) return i;
    }
    return null;
  }

  WorkProfile? _profileById(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Login / onboarding
  // ---------------------------------------------------------------------------

  Future<void> loginAsLocal([String? userName]) async {
    _setLoading(true);
    try {
      final localId = 'local_${const Uuid().v4()}';
      final profile = WorkProfile(
        id: localId,
        name: (userName ?? '').trim(),
        isLocal: true,
        linkedGoogleEmail: null,
        slotIndex: null,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      );
      _profiles.add(profile);
      await _persistProfiles();
      await _activateProfile(profile, restoreDrive: false);
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthFlowResult> loginWithGoogle({bool bridgeCurrentLocal = false}) async {
    _setLoading(true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const AuthFlowResult(AuthFlowState.cancelled, message: '구글 로그인이 취소되었습니다.');
      }

      final email = account.email.trim().toLowerCase();
      final displayName = (account.displayName ?? '').trim();
      final photo = account.photoUrl;

      final client = await _googleSignIn.authenticatedClient();
      if (client != null) {
        _driveService.setClient(client);
      }

      if (bridgeCurrentLocal && _currentProfile != null) {
        final current = _currentProfile!;

        if (current.isGoogleProfile) {
          if ((current.linkedGoogleEmail ?? '').trim().toLowerCase() != email) {
            return AuthFlowResult(
              AuthFlowState.failed,
              message: '현재 프로필은 이미 다른 구글 계정과 연결되어 있습니다.\n현재 연결: ${current.linkedGoogleEmail}',
            );
          }
          return const AuthFlowResult(AuthFlowState.bridgeCompleted, message: '구글 연결이 이미 활성화되어 있습니다.');
        }

        final slot = _firstAvailableSlot(email);
        if (slot == null) {
          return AuthFlowResult(AuthFlowState.failed, message: '$email 계정의 5개 슬롯이 모두 사용 중입니다.');
        }

        final bridged = current.copyWith(
          isLocal: false,
          linkedGoogleEmail: email,
          slotIndex: slot,
          profileImage: current.profileImage ?? photo,
        );
        final idx = _profiles.indexWhere((p) => p.id == current.id);
        if (idx >= 0) {
          _profiles[idx] = bridged;
        }
        await _persistProfiles();
        await _activateProfile(bridged);
        return AuthFlowResult(
          bridged.needsNameSetup ? AuthFlowState.requiresProfileSetup : AuthFlowState.bridgeCompleted,
          message: '로컬 프로필이 구글 계정과 연결되었습니다.',
        );
      }

      final matched = profilesForGoogleEmail(email);
      _pendingGoogleEmail = email;
      _pendingGoogleDisplayName = displayName;
      _pendingGooglePhotoUrl = photo;

      // 슬롯이 1개만 있으면 바로 진입, 그 외에는 선택 페이지로.
      if (matched.length == 1) {
        final single = matched.first;
        await _activateProfile(single);
        clearPendingGoogleSelection(notify: false);
        return AuthFlowResult(
          single.needsNameSetup ? AuthFlowState.requiresProfileSetup : AuthFlowState.signedIn,
          message: single.needsNameSetup ? '닉네임 설정이 필요합니다.' : '구글 프로필로 로그인되었습니다.',
        );
      }

      notifyListeners();
      return AuthFlowResult(
        AuthFlowState.requiresProfileSelection,
        message: matched.isEmpty ? '사용할 프로필 슬롯을 선택해 주세요.' : '연결된 프로필 슬롯을 선택해 주세요.',
      );
    } catch (e, st) {
      debugPrint('[Auth] 구글 로그인 실패: $e\n$st');
      return const AuthFlowResult(
        AuthFlowState.failed,
        message: '구글 로그인 중 오류가 발생했습니다.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthFlowResult> connectGoogleDrive({bool bridgeCurrentLocal = true}) async {
    return loginWithGoogle(bridgeCurrentLocal: bridgeCurrentLocal);
  }

  void clearPendingGoogleSelection({bool notify = true}) {
    _pendingGoogleEmail = null;
    _pendingGoogleDisplayName = null;
    _pendingGooglePhotoUrl = null;
    if (notify) notifyListeners();
  }

  Future<AuthFlowResult> selectPendingGoogleProfile(String profileId) async {
    final email = _pendingGoogleEmail;
    if (email == null || email.trim().isEmpty) {
      return const AuthFlowResult(AuthFlowState.failed, message: '선택 가능한 구글 계정 정보가 없습니다.');
    }
    final profile = _profileById(profileId);
    if (profile == null) {
      return const AuthFlowResult(AuthFlowState.failed, message: '프로필을 찾을 수 없습니다.');
    }
    if ((profile.linkedGoogleEmail ?? '').trim().toLowerCase() != email.trim().toLowerCase()) {
      return const AuthFlowResult(AuthFlowState.failed, message: '선택한 프로필이 현재 구글 계정과 일치하지 않습니다.');
    }

    await _activateProfile(profile);
    clearPendingGoogleSelection(notify: false);
    notifyListeners();
    return AuthFlowResult(
      profile.needsNameSetup ? AuthFlowState.requiresProfileSetup : AuthFlowState.signedIn,
      message: profile.needsNameSetup ? '닉네임 설정이 필요합니다.' : '프로필 전환이 완료되었습니다.',
    );
  }

  Future<AuthFlowResult> createPendingGoogleSlot({int? preferredSlot}) async {
    final email = _pendingGoogleEmail;
    if (email == null || email.trim().isEmpty) {
      return const AuthFlowResult(AuthFlowState.failed, message: '슬롯을 만들 구글 계정 정보가 없습니다.');
    }

    int? slot = preferredSlot;
    final used = profilesForGoogleEmail(email).map((e) => e.slotIndex).whereType<int>().toSet();
    if (slot != null && (slot < 0 || slot >= _maxGoogleSlots || used.contains(slot))) {
      slot = null;
    }
    slot ??= _firstAvailableSlot(email);

    if (slot == null) {
      return AuthFlowResult(AuthFlowState.failed, message: '$email 계정의 5개 슬롯이 모두 사용 중입니다.');
    }

    final profile = WorkProfile(
      id: const Uuid().v4(),
      name: '',
      isLocal: false,
      linkedGoogleEmail: email,
      slotIndex: slot,
      profileImage: _pendingGooglePhotoUrl,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    _profiles.add(profile);
    await _persistProfiles();
    await _activateProfile(profile);
    clearPendingGoogleSelection(notify: false);
    notifyListeners();

    return const AuthFlowResult(AuthFlowState.requiresProfileSetup, message: '새 슬롯이 생성되었습니다. 닉네임을 설정해 주세요.');
  }

  Future<AuthFlowResult> createAdditionalLocalProfile() async {
    _setLoading(true);
    try {
      final profile = WorkProfile(
        id: 'local_${const Uuid().v4()}',
        name: '',
        isLocal: true,
        linkedGoogleEmail: null,
        slotIndex: null,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      );
      _profiles.add(profile);
      await _persistProfiles();
      await _activateProfile(profile, restoreDrive: false);
      return const AuthFlowResult(AuthFlowState.requiresProfileSetup, message: '새 로컬 프로필이 생성되었습니다.');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Profile switching / management
  // ---------------------------------------------------------------------------

  Future<void> switchProfile(String profileId) async {
    final profile = _profileById(profileId);
    if (profile == null) return;
    await _activateProfile(profile);
  }

  Future<bool> renameProfile(String profileId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return false;

    final updated = _profiles[idx].copyWith(name: trimmed);
    _profiles[idx] = updated;
    await _persistProfiles();

    if (_currentProfile?.id == profileId) {
      await _activateProfile(updated);
    } else {
      await _syncProfileToUsersBox(updated);
      notifyListeners();
    }
    return true;
  }

  Future<bool> updateName(String newName) async {
    final current = _currentProfile;
    if (current == null) return false;
    return renameProfile(current.id, newName);
  }

  Future<bool> updateProfileImage(String? emoji) async {
    final current = _currentProfile;
    if (current == null) return false;

    final idx = _profiles.indexWhere((p) => p.id == current.id);
    if (idx < 0) return false;
    final updated = _profiles[idx].copyWith(profileImage: emoji);
    _profiles[idx] = updated;
    await _persistProfiles();
    await _activateProfile(updated, restoreDrive: false);
    return true;
  }

  Future<bool> unlinkGoogleProfile(String profileId) async {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return false;

    final target = _profiles[idx];
    if (!target.isGoogleProfile) return true;

    final updated = target.copyWith(
      isLocal: true,
      linkedGoogleEmail: null,
      slotIndex: null,
    );
    _profiles[idx] = updated;
    await _persistProfiles();

    if (_currentProfile?.id == profileId) {
      await _googleSignIn.signOut().catchError((_) => null);
      _driveService.clearClient();
      await _activateProfile(updated, restoreDrive: false);
    } else {
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteProfile(String profileId) async {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return false;

    final deletingCurrent = _currentProfile?.id == profileId;
    final removed = _profiles.removeAt(idx);
    await _persistProfiles();

    if (!deletingCurrent) {
      notifyListeners();
      return true;
    }

    if (removed.isGoogleProfile) {
      await _googleSignIn.signOut().catchError((_) => null);
    }

    if (_profiles.isNotEmpty) {
      await _activateProfile(_profiles.last);
    } else {
      _currentProfile = null;
      await _persistCurrentProfileId(null);
      _driveService.clearClient();
      notifyListeners();
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Legacy APIs kept for compatibility
  // ---------------------------------------------------------------------------

  Future<bool> loginLocal(String email, String password) async {
    // 현재 앱은 Local-First 프로필 기반으로 동작하며,
    // 별도 이메일/패스워드 저장형 로컬 회원 시스템은 비활성 상태.
    return false;
  }

  Future<bool> signUpLocal(String email, String password, String name) async {
    return false;
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
    _driveService.clearClient();
    _currentProfile = null;
    clearPendingGoogleSelection(notify: false);
    await _persistCurrentProfileId(null);
    notifyListeners();
  }
}
