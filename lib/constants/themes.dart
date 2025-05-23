import 'package:flutter/material.dart';

const Color primaryColor = Colors.orange; // Existing primary color
const Color accentColor = Colors.blue;   // Existing accent color (though accentColor is deprecated, we'll use it for secondary in ThemeData)

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: Colors.grey[100], // Light background
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: accentColor,
    onPrimary: Colors.white, // Text on primary color
    onSecondary: Colors.white, // Text on secondary color
    surface: Colors.white, // Card backgrounds, dialogs
    onSurface: Colors.black87, // Text on surface
    background: Colors.grey[100]!, // Overall background
    onBackground: Colors.black87, // Text on background
    error: Colors.redAccent,
    onError: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white, // Title and icon color for AppBar
    elevation: 4,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[400]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    labelStyle: const TextStyle(color: primaryColor),
    hintStyle: TextStyle(color: Colors.grey[600]),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
  ),
  iconTheme: const IconThemeData(
    color: primaryColor,
  ),
  textTheme:  TextTheme(
    displayLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.black87),
    titleSmall: TextStyle(color: Colors.black54),
    bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
    bodySmall: TextStyle(color: Colors.black54, fontSize: 12),
    labelLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.bold), // For button text
    labelMedium: TextStyle(color: Colors.black54),
    labelSmall: TextStyle(color: Colors.black54),
  ).apply(
    bodyColor: Colors.black87,
    displayColor: Colors.black87,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.white,
    surfaceTintColor: Colors.white, // Prevents cards from tinting with colorScheme.primary
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey[600],
    backgroundColor: Colors.white,
    type: BottomNavigationBarType.fixed,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor, // Keep primary color consistent
  scaffoldBackgroundColor: Colors.grey[850], // Dark background
  colorScheme: ColorScheme.dark(
    primary: primaryColor,
    secondary: accentColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    surface: Colors.grey[800]!, // Card backgrounds, dialogs
    onSurface: Colors.white, // Text on surface
    background: Colors.grey[850]!, // Overall background
    onBackground: Colors.white, // Text on background
    error: Colors.redAccent,
    onError: Colors.black,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900], // Darker AppBar
    foregroundColor: Colors.white,
    elevation: 4,
     titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    labelStyle: const TextStyle(color: primaryColor),
    hintStyle: TextStyle(color: Colors.grey[500]),
    fillColor: Colors.grey[800],
    filled: true,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
  ),
  iconTheme: const IconThemeData(
    color: primaryColor, // Keeping icons orange for consistency or could be Colors.white70
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white70),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
    bodySmall: TextStyle(color: Colors.white70, fontSize: 12),
    labelLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
    labelMedium: TextStyle(color: Colors.white70),
    labelSmall: TextStyle(color: Colors.white70),
  ).apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.grey[800],
    surfaceTintColor: Colors.grey[800],
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey[400],
    backgroundColor: Colors.grey[900],
    type: BottomNavigationBarType.fixed,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Colors.grey[800],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
); 