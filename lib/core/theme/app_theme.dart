import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 전역 테마 모음.
/// - TeamProvider.currentThemeMode 값('dark'|'light'|'blue')에 따라 선택해서 사용.
class AppTheme {
  static const Color _seedBlue = Color(0xFF2563EB);
  static const Color _seedDark = Color(0xFF0F172A);

  static ThemeMode resolveThemeMode(String? setting) {
    return (setting ?? 'dark') == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData light({String? setting}) {
    // setting == 'blue'일 때만 배경을 살짝 더 푸른 톤으로.
    final bool isBlue = setting == 'blue';
    final seed = _seedBlue;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: isBlue ? const Color(0xFFF0F7FF) : const Color(0xFFF8FAFC),
      primaryColor: seed,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme().copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.w900),
        titleLarge: const TextStyle(fontWeight: FontWeight.w900),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedBlue, brightness: Brightness.dark),
      textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.w900),
        titleLarge: const TextStyle(fontWeight: FontWeight.w900),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
