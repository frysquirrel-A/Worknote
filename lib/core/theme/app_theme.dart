import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worknote/core/ui/app_palette.dart';

/// 앱 전역 테마 모음.
class AppTheme {
  static const Color _seedDark = Color(0xFF0F172A);

  static ThemeMode resolveThemeMode(String? setting) {
    return (setting ?? 'dark') == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData light({String? setting}) {
    final bool isBlue = setting == 'blue';
    final seed = AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: isBlue ? const Color(0xFFF0F7FF) : AppColors.bg,
      primaryColor: seed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme().copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
        titleLarge: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
        bodyMedium: const TextStyle(color: AppColors.text),
        bodySmall: const TextStyle(color: AppColors.hint),
        labelSmall: const TextStyle(color: AppColors.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.text2),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.text2, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: AppColors.hint),
        prefixIconColor: seed,
        suffixIconColor: seed,
        floatingLabelStyle: const TextStyle(color: AppColors.text2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? seed : null),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? seed.withValues(alpha: 0.5) : null),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      cardTheme: CardThemeData( // CardTheme -> CardThemeData 수정
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedDark, brightness: Brightness.dark),
      textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.w900),
        titleLarge: const TextStyle(fontWeight: FontWeight.w900),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
