import 'package:flutter/material.dart';

/// 직관적인 색 체계를 위한 확정 팔레트
class AppColors {
  static const bg = Color(0xFFF3F4F6);         // 화면 배경
  static const surface = Colors.white;         // 카드/시트
  static const border = Color(0xFFE5E7EB);

  static const text = Color(0xFF111827);       // 메인 텍스트(진하게)
  static const text2 = Color(0xFF374151);      // 보조(라벨)
  static const hint = Color(0xFF6B7280);       // 설명/날짜
  static const muted = Color(0xFF9CA3AF);      // 아주 작은 메타

  static const primary = Color(0xFF2563EB);    // 파랑
  static const danger = Color(0xFFDC2626);     // 빨강(기한/지연)
  static const success = Color(0xFF16A34A);    // 초록(완료)
  static const warning = Color(0xFFF59E0B);    // 주황(중요/주의)
}

/// Legacy 호환을 위한 클래스 (AppColors로 점진적 교체 권장)
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
