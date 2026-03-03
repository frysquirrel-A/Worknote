/// 👤 WorkProfile: 로컬 및 구글 연동 계정을 통합 관리하는 프로필 모델
class WorkProfile {
  final String id;
  final String name;
  final String? profileImage;
  final bool isLocal;
  final String? linkedGoogleEmail;

  WorkProfile({
    required this.id,
    required this.name,
    this.profileImage,
    this.isLocal = true,
    this.linkedGoogleEmail,
  });

  WorkProfile copyWith({
    String? id,
    String? name,
    String? profileImage,
    bool? isLocal,
    String? linkedGoogleEmail,
  }) {
    return WorkProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      isLocal: isLocal ?? this.isLocal,
      linkedGoogleEmail: linkedGoogleEmail ?? this.linkedGoogleEmail,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profileImage': profileImage,
        'isLocal': isLocal,
        'linkedGoogleEmail': linkedGoogleEmail,
      };

  factory WorkProfile.fromJson(Map<String, dynamic> json) => WorkProfile(
        id: json['id'],
        name: json['name'],
        profileImage: json['profileImage'],
        isLocal: json['isLocal'] ?? true,
        linkedGoogleEmail: json['linkedGoogleEmail'],
      );
}
