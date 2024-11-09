import 'package:flutter/material.dart';

ThemeData buildThemeData() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0D0D0D), // 宇宙の暗い背景
    scaffoldBackgroundColor: const Color(0xFF000814), // 宇宙の深い背景
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.cyan,
      secondary: Color(0xFF001D3D),
      surface: Color(0xFF3C434B),
      onSecondary: Colors.white,
      onSurface: Colors.white70,
      error: Color(0xFFEE4266),
      onError: Colors.white,
      onPrimary: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
      titleMedium: TextStyle(
        color: Color(0xFFBFD3C1), // 薄い星の色
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF61C0BF), // 優しい青緑
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
