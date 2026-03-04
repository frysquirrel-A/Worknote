/// 👤 WorkProfile: 로컬/구글 연동 프로필을 통합 관리하는 인증 프로필 모델.
///
/// - id: 앱 내부 식별자 (팀/업무/일지 작성자 식별에도 사용)
/// - isLocal: 순수 로컬 프로필 여부
/// - linkedGoogleEmail: 구글 연동 시 연결된 이메일
/// - slotIndex: 같은 구글 계정에서 쓰는 0~4 슬롯 번호
class WorkProfile {
  final String id;
  final String name;
  final String? profileImage;
  final bool isLocal;
  final String? linkedGoogleEmail;
  final int? slotIndex;
  final int createdAtMillis;

  const WorkProfile({
    required this.id,
    required this.name,
    this.profileImage,
    this.isLocal = true,
    this.linkedGoogleEmail,
    this.slotIndex,
    required this.createdAtMillis,
  });

  bool get isGoogleProfile => (linkedGoogleEmail ?? '').trim().isNotEmpty;
  bool get needsNameSetup => name.trim().isEmpty;

  WorkProfile copyWith({
    String? id,
    String? name,
    String? profileImage,
    bool? isLocal,
    String? linkedGoogleEmail,
    int? slotIndex,
    int? createdAtMillis,
  }) {
    return WorkProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      isLocal: isLocal ?? this.isLocal,
      linkedGoogleEmail: linkedGoogleEmail ?? this.linkedGoogleEmail,
      slotIndex: slotIndex ?? this.slotIndex,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profileImage': profileImage,
        'isLocal': isLocal,
        'linkedGoogleEmail': linkedGoogleEmail,
        'slotIndex': slotIndex,
        'createdAtMillis': createdAtMillis,
      };

  factory WorkProfile.fromJson(Map<String, dynamic> json) => WorkProfile(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        profileImage: json['profileImage']?.toString(),
        isLocal: json['isLocal'] ?? true,
        linkedGoogleEmail: json['linkedGoogleEmail']?.toString(),
        slotIndex: json['slotIndex'] is int ? json['slotIndex'] as int : int.tryParse('${json['slotIndex'] ?? ''}'),
        createdAtMillis: json['createdAtMillis'] is int
            ? json['createdAtMillis'] as int
            : int.tryParse('${json['createdAtMillis'] ?? ''}') ?? DateTime.now().millisecondsSinceEpoch,
      );
}
