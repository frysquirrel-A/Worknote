import 'package:flutter/material.dart';

/// Centralized color palette for consistent UI styling.
class AppPalette {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF1F5F9);
  static const Color shellBackground = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);

  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F5F9);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

/// [추가] 텍스트 및 상태별 컬러 시스템 (AppColors 명칭 지원)
class AppColors {
  static const bg = AppPalette.background;
  static const surface = AppPalette.surface;
  static const border = AppPalette.border;

  static const text = AppPalette.textDark;
  static const text2 = AppPalette.textMuted;
  static const hint = AppPalette.textHint;
  static const muted = Color(0xFF9CA3AF);

  static const primary = AppPalette.primary;
  static const danger = AppPalette.danger;
  static const success = AppPalette.success;
  static const warning = AppPalette.warning;
}

class AppTextColor {
  static const primary = AppColors.text;
  static const secondary = AppColors.text2;
  static const hint = AppColors.hint;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const danger = AppColors.danger;
}
