import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF3F4F6);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);

  static const text = Color(0xFF111827);
  static const text2 = Color(0xFF374151);
  static const hint = Color(0xFF6B7280);
  static const muted = Color(0xFF9CA3AF);

  static const primary = Color(0xFF2563EB);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);

  static const darkBg = Color(0xFF061121);
  static const darkSurface = Color(0xFF0D1A32);
  static const darkSurface2 = Color(0xFF122347);
  static const darkBorder = Color(0xFF22324D);
  static const darkText = Color(0xFFF8FAFC);
  static const darkHint = Color(0xFF94A3B8);
  static const premiumBlue = Color(0xFF5B8CFF);
  static const premiumBlueStrong = Color(0xFF3F74F2);
  static const premiumTeal = Color(0xFF15C7D6);
  static const destructive = Color(0xFFFF5B65);
}

class AppGradients {
  static const messengerPanel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.darkSurface2, AppColors.darkBg],
  );

  static const premiumCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF162544), Color(0xFF0E1A33)],
  );
}

class AppPalette {
  static const Color primary = AppColors.primary;
  static const Color background = AppColors.bg;
  static const Color shellBackground = Color(0xFFF8FAFC);
  static const Color border = AppColors.border;
  static const Color textDark = AppColors.text;
  static const Color textMuted = AppColors.hint;
}

class AppTextColor {
  static const primary = AppColors.text;
  static const secondary = AppColors.text2;
  static const hint = AppColors.hint;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const danger = AppColors.danger;
}

class AppModePalette {
  const AppModePalette({
    required this.mode,
    required this.isDark,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.hint,
    required this.accent,
    required this.shadow,
  });

  final String mode;
  final bool isDark;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color hint;
  final Color accent;
  final Color shadow;

  static AppModePalette fromMode(String? rawMode) {
    final mode = (rawMode ?? 'light').toLowerCase();
    switch (mode) {
      case 'dark':
        return const AppModePalette(
          mode: 'dark',
          isDark: true,
          background: AppColors.darkBg,
          backgroundAlt: Color(0xFF08111F),
          surface: AppColors.darkSurface,
          surfaceAlt: AppColors.darkSurface2,
          border: AppColors.darkBorder,
          text: AppColors.darkText,
          hint: AppColors.darkHint,
          accent: AppColors.premiumBlue,
          shadow: Color(0x47000000),
        );
      case 'blue':
        return const AppModePalette(
          mode: 'blue',
          isDark: false,
          background: Color(0xFFF0F7FF),
          backgroundAlt: Color(0xFFE8F0FF),
          surface: Color(0xFFFFFFFF),
          surfaceAlt: Color(0xFFE4EEFF),
          border: Color(0xFFC9D9F4),
          text: AppColors.text,
          hint: Color(0xFF527199),
          accent: AppColors.premiumBlueStrong,
          shadow: Color(0x143F74F2),
        );
      default:
        return const AppModePalette(
          mode: 'light',
          isDark: false,
          background: AppColors.bg,
          backgroundAlt: Color(0xFFEDEFF3),
          surface: AppColors.surface,
          surfaceAlt: Color(0xFFF8FAFC),
          border: AppColors.border,
          text: AppColors.text,
          hint: AppColors.text2,
          accent: AppColors.primary,
          shadow: Color(0x110F172A),
        );
    }
  }
}
