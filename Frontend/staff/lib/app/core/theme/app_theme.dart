import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      primaryColor: const Color(0xFF023E8A),
      scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF023E8A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF023E8A),
        primary: const Color(0xFF023E8A),
        secondary: const Color(0xFFE6EEF6),
        background: const Color(0xFFF7F9FC),
        surface: Colors.white,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Color(0xFF023E8A),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF023E8A),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF2E3A44),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF4A5A6A),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF023E8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF023E8A)),
        ),
      ),

      /// ✅ FIXED
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
