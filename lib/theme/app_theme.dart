import 'package:flutter/material.dart';

class AppTheme {
  static const Color yellowColor = Color(0xFFFFD700);
  static const Color greenColor = Color(0xFF32CD32);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color purpleColor = Color(0xFF9370DB);
  static const Color blueColor = Color(0xFF1E90FF);
  static const Color foxColor = Color(0xFFFF6B35);
  static const Color bonusColor = Color(0xFFFFD700);

  static const Color primaryColor = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53935);

  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkPrimaryColor = Color(0xFF64B5F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: greenColor,
        tertiary: orangeColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryColor,
        brightness: Brightness.dark,
        primary: darkPrimaryColor,
        secondary: greenColor,
        tertiary: orangeColor,
        error: errorColor,
        surface: darkSurfaceColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurfaceColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: darkSurfaceColor,
      ),
    );
  }

  static Color getScoreAreaColor(String area) {
    switch (area.toLowerCase()) {
      case 'yellow':
        return yellowColor;
      case 'green':
        return greenColor;
      case 'orange':
        return orangeColor;
      case 'purple':
        return purpleColor;
      case 'blue':
        return blueColor;
      case 'fox':
        return foxColor;
      case 'bonus':
        return bonusColor;
      default:
        return Colors.grey;
    }
  }

  static Color getScoreAreaTextColor(String area) {
    switch (area.toLowerCase()) {
      case 'yellow':
        return Colors.black87;
      case 'green':
        return Colors.white;
      case 'orange':
        return Colors.white;
      case 'purple':
        return Colors.white;
      case 'blue':
        return Colors.white;
      case 'fox':
        return Colors.white;
      case 'bonus':
        return Colors.black87;
      default:
        return Colors.black87;
    }
  }
}
