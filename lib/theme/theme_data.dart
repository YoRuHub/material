import 'package:flutter/material.dart';

ThemeData buildThemeData() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0D0D0D), // 宇宙の暗い背景
    scaffoldBackgroundColor: const Color(0xFF0D0D0D), // 宇宙の深い背景
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.cyan,
      secondary: Color.fromARGB(100, 255, 255, 255),
      onSecondary: Color.fromARGB(255, 0, 0, 0),
      surface: Color.fromRGBO(31, 31, 31, 1),
      onSurface: Color.fromARGB(100, 255, 255, 255),
      error: Color(0xFFEE4266),
      onError: Colors.white,
      onPrimary: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.cyan[900]),
    primaryIconTheme: const IconThemeData(color: Colors.cyan),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(100, 0, 0, 0),
      titleTextStyle: TextStyle(
        color: Color.fromARGB(200, 255, 255, 255),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
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
      buttonColor: Colors.cyan,
      textTheme: ButtonTextTheme.primary,
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Color.fromARGB(255, 30, 30, 30),
      titleTextStyle: TextStyle(
        color: Color.fromARGB(200, 255, 255, 255),
        fontSize: 20, // フォントサイズを変更
        fontWeight: FontWeight.bold, // 太字に設定
      ),
      contentTextStyle: TextStyle(
        color: Color.fromARGB(100, 255, 255, 255),
        fontSize: 16, // フォントサイズを変更
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF333333), // Drawer 背景色
      elevation: 5, // Drawer の影
    ),
  );
}
