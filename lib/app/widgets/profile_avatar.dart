import 'package:flutter/material.dart';
import 'package:worknote/core/ui/app_palette.dart';

class ProfileAvatar extends StatelessWidget {
  final String emoji;
  final String userId;
  final double radius;
  final String? heroPrefix;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.emoji,
    required this.userId,
    this.radius = 22,
    this.heroPrefix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: "${heroPrefix ?? ''}_profile_avatar_$userId",
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            emoji,
            style: TextStyle(fontSize: radius * 0.9),
          ),
        ),
      ),
    );
  }
}
