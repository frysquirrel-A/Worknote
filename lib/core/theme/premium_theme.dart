import 'package:flutter/material.dart';

class WorkNotePremium {
  static const Color bg = Color(0xFF0B1220);
  static const Color surface = Color(0xFF121A2B);
  static const Color primary = Color(0xFF4F8CFF);
  static const Color secondary = Color(0xFF14C8C4);
  static const Color accent = Color(0xFFA78BFA);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
}

class WorkNoteType {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: WorkNotePremium.textMain,
    letterSpacing: -0.5,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: WorkNotePremium.textMain,
    letterSpacing: -0.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: WorkNotePremium.textMain,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: WorkNotePremium.textMuted,
  );
}

final List<BoxShadow> premiumShadow = [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 20,
    offset: const Offset(0, 10),
  ),
];
