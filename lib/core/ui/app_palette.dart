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
