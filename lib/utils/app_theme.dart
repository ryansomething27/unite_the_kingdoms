// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color lightBrown = Color(0xFF5D4037);
  static const Color parchment = Color(0xFFF5E6D3);
  static const Color bloodRed = Color(0xFF8B0000);

  static ThemeData get medievalTheme {
    return ThemeData(
      primarySwatch: MaterialColor(0xFFD4AF37, {
        50: primaryGold.withValues(alpha: 0.1),
        100: primaryGold.withValues(alpha: 0.2),
        200: primaryGold.withValues(alpha: 0.3),
        300: primaryGold.withValues(alpha: 0.4),
        400: primaryGold.withValues(alpha: 0.5),
        500: primaryGold,
        600: primaryGold.withValues(alpha: 0.7),
        700: primaryGold.withValues(alpha: 0.8),
        800: primaryGold.withValues(alpha: 0.9),
        900: primaryGold.withValues(alpha: 1.0),
      }),
      scaffoldBackgroundColor: parchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBrown,
        foregroundColor: primaryGold,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBrown,
          foregroundColor: primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: parchment,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBrown, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Serif',
          color: darkBrown,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: darkBrown,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}