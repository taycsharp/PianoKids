import 'package:flutter/material.dart';

class AppTheme {
  static const Color pink = Color(0xFFFF77A9);
  static const Color purple = Color(0xFF8E7CFF);
  static const Color blue = Color(0xFF5BC0EB);
  static const Color yellow = Color(0xFFFFD166);
  static const Color green = Color(0xFF6EE7B7);
  static const Color orange = Color(0xFFFFA24C);
  static const Color background = Color(0xFFFFF8EC);
  static const Color darkText = Color(0xFF34344A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.light,
        primary: purple,
        secondary: pink,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: darkText,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: darkText),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkText),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: darkText),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
        bodyLarge: TextStyle(fontSize: 17, color: darkText, height: 1.35),
        bodyMedium: TextStyle(fontSize: 15, color: darkText, height: 1.35),
      ),
    );
  }

  static LinearGradient candyGradient(List<Color> colors) {
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
