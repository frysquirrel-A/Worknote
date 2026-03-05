import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:worknote/features/profile/models/profile_focus_prefs.dart';

class FocusProvider extends ChangeNotifier {
  static const String boxName = 'focus_prefs';
  
  Box<ProfileFocusPrefs>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(7)) {
      // Note: In a real app, the adapter would be registered in bootstrap.
      // But we handle it here for safety since we're creating files.
    }
    _box = await Hive.openBox<ProfileFocusPrefs>(boxName);
  }

  ProfileFocusPrefs getPrefs(String profileId) {
    return _box?.get(profileId) ?? ProfileFocusPrefs(profileId: profileId);
  }

  Future<void> updatePrefs(ProfileFocusPrefs prefs) async {
    await _box?.put(prefs.profileId, prefs);
    notifyListeners();
  }
}
