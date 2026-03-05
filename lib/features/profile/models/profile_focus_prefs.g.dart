// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_focus_prefs.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileFocusPrefsAdapter extends TypeAdapter<ProfileFocusPrefs> {
  @override
  final int typeId = 7;

  @override
  ProfileFocusPrefs read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileFocusPrefs(
      profileId: fields[0] as String,
      landingTab: fields[1] as String,
      taskLayout: fields[2] as String,
      showTodayBriefingFirst: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileFocusPrefs obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.profileId)
      ..writeByte(1)
      ..write(obj.landingTab)
      ..writeByte(2)
      ..write(obj.taskLayout)
      ..writeByte(3)
      ..write(obj.showTodayBriefingFirst);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileFocusPrefsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
