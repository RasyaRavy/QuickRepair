import 'package:flutter/material.dart';

// Colors based on PRD
class AppColors {
  // Primary color: Orange
  static const Color primaryColor = Color(0xFFFF9800);
  // Accent color: Blue
  static const Color accentColor = Color(0xFF2196F3);
  // Background colors
  static const Color lightBackground = Colors.white;
  static const Color darkBackground = Color(0xFF121212);
  // Text colors
  static const Color darkTextColor = Color(0xFF333333);
  static const Color lightTextColor = Colors.white;
  // Other UI colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
}

// Theme Data
class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.accentColor,
      background: AppColors.lightBackground,
      error: AppColors.errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.lightTextColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.lightTextColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.darkTextColor),
      displayMedium: TextStyle(color: AppColors.darkTextColor),
      displaySmall: TextStyle(color: AppColors.darkTextColor),
      headlineMedium: TextStyle(color: AppColors.darkTextColor),
      headlineSmall: TextStyle(color: AppColors.darkTextColor),
      titleLarge: TextStyle(color: AppColors.darkTextColor),
      bodyLarge: TextStyle(color: AppColors.darkTextColor),
      bodyMedium: TextStyle(color: AppColors.darkTextColor),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      secondary: AppColors.accentColor,
      background: AppColors.darkBackground,
      error: AppColors.errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF212121),
      foregroundColor: AppColors.lightTextColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.lightTextColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.lightTextColor),
      displayMedium: TextStyle(color: AppColors.lightTextColor),
      displaySmall: TextStyle(color: AppColors.lightTextColor),
      headlineMedium: TextStyle(color: AppColors.lightTextColor),
      headlineSmall: TextStyle(color: AppColors.lightTextColor),
      titleLarge: TextStyle(color: AppColors.lightTextColor),
      bodyLarge: TextStyle(color: AppColors.lightTextColor),
      bodyMedium: TextStyle(color: AppColors.lightTextColor),
    ),
  );
} 