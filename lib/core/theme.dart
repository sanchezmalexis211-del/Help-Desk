import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D1E);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color alertCritical = Color(0xFFFF6B6B);
  static const Color alertHigh = Color(0xFFFFB347);
  static const Color alertMedium = Color(0xFF4D96FF);
  static const Color alertLow = Color(0xFF6BCB77);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: textPrimary,
      colorScheme: ColorScheme.fromSeed(seedColor: textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}