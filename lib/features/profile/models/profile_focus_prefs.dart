import 'package:hive/hive.dart';

part 'profile_focus_prefs.g.dart';

@HiveType(typeId: 7)
class ProfileFocusPrefs extends HiveObject {
  @HiveField(0)
  final String profileId;

  @HiveField(1)
  final String landingTab; // home, tasks, schedule, journal, gallery, messenger

  @HiveField(2)
  final String taskLayout; // classic, gallery

  @HiveField(3)
  final bool showTodayBriefingFirst;

  ProfileFocusPrefs({
    required this.profileId,
    this.landingTab = 'home',
    this.taskLayout = 'classic',
    this.showTodayBriefingFirst = true,
  });

  ProfileFocusPrefs copyWith({
    String? landingTab,
    String? taskLayout,
    bool? showTodayBriefingFirst,
  }) {
    return ProfileFocusPrefs(
      profileId: profileId,
      landingTab: landingTab ?? this.landingTab,
      taskLayout: taskLayout ?? this.taskLayout,
      showTodayBriefingFirst: showTodayBriefingFirst ?? this.showTodayBriefingFirst,
    );
  }
}
