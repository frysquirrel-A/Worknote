import 'package:flutter/material.dart';

import 'package:worknote/core/ui/app_palette.dart';

class EmptyStatePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onTap;
  final bool compact;
  final bool dark;

  const EmptyStatePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onTap,
    this.compact = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 36.0 : 56.0;
    final outerPadding = compact ? 18.0 : 24.0;
    final shellColor = dark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = dark ? AppColors.darkBorder : AppColors.border;
    final iconColor = dark ? AppColors.darkHint : AppColors.muted;
    final titleColor = dark ? AppColors.darkText : AppColors.text;
    final descriptionColor = dark ? AppColors.darkHint : AppColors.hint;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(outerPadding),
              decoration: BoxDecoration(
                color: shellColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.18 : 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: descriptionColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            if (ctaLabel != null && onTap != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.add_rounded),
                label: Text(ctaLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
