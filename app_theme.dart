import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF112D52);
  static const blue = Color(0xFF1266D8);
  static const orange = Color(0xFFF58A18);
  static const green = Color(0xFF0B9D62);
  static const red = Color(0xFFD93E45);
  static const purple = Color(0xFF7D45CB);
  static const canvas = Color(0xFFF4F7FC);
  static const ink = Color(0xFF15253C);
  static const muted = Color(0xFF65788F);
}

ThemeData dailyControlTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    primary: AppColors.blue,
    secondary: AppColors.orange,
    surface: Colors.white,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    ),
    cardColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E3F0)),
      ),
    ),
  );
}
