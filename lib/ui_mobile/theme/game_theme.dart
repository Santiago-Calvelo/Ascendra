import 'package:flutter/material.dart';

class GameTheme {
  static const Color background = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color primary = Color(0xFF8B5CF6); // Violet for magic/leveling
  static const Color accent = Color(0xFFF59E0B);  // Gold for rewards/achievements
  static const Color foreground = Colors.white;
  static const Color mutedForeground = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);

  static const Color zoneComfort = Color(0xFF10B981); // Emerald
  static const Color zoneNormal = Color(0xFF8B5CF6); // Blue/Violet
  static const Color zoneGrowth = Color(0xFFF97316); // Red/Orange

  static const Color statStr = Color(0xFFEF4444); // Red
  static const Color statEnd = Color(0xFF10B981); // Green
  static const Color statDis = Color(0xFF3B82F6); // Blue

  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      cardColor: cardBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: cardBg,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: foreground,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: mutedForeground,
          fontSize: 12,
        ),
      ),
    );
  }
}
