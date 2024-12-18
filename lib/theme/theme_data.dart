import 'package:flutter/material.dart';

ThemeData buildThemeData() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0D0D0D), // 宇宙の暗い背景
    scaffoldBackgroundColor: const Color(0xFF0D0D0D), // 宇宙の深い背景
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.cyan,
      secondary: Color.fromARGB(255, 200, 200, 200),
      onSecondary: Color.fromARGB(255, 0, 0, 0),
      surface: Color.fromARGB(255, 25, 25, 25),
      onSurface: Color.fromARGB(255, 50, 50, 50),
      onSurfaceVariant: Color.fromARGB(255, 100, 100, 100),
      error: Color(0xFFEE4266),
      onError: Colors.white,
      onPrimary: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.cyan[900]),
    primaryIconTheme: const IconThemeData(color: Colors.cyan),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 50, 50, 50), // 固定色
      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 200, 200, 200),
        fontSize: 24,
      ),
    ),
    textTheme: const TextTheme(
        titleMedium: TextStyle(
          color: Color.fromARGB(150, 200, 200, 200),
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(
          color: Color.fromARGB(255, 200, 200, 200),
        ),
        headlineSmall: TextStyle(
          color: Color.fromARGB(255, 200, 200, 200),
          fontWeight: FontWeight.bold,
        ),
        labelSmall: TextStyle(
          color: Color.fromARGB(255, 200, 200, 200),
        ),
        labelMedium: TextStyle(
          color: Color.fromARGB(150, 200, 200, 200),
        ),
        labelLarge: TextStyle(
          color: Color.fromARGB(150, 200, 200, 200),
        ),
        bodyMedium: TextStyle(
          color: Color.fromARGB(200, 200, 200, 200),
        ),
        bodySmall: TextStyle(
          color: Color.fromARGB(200, 200, 200, 200),
        )),
    // IconButton
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(Colors.cyan),
      ),
    ),
    //ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
            const Color.fromARGB(255, 25, 25, 25)),
        foregroundColor: WidgetStateProperty.all<Color>(Colors.cyan),
      ),
    ),
    // Card
    cardTheme: const CardTheme(
      color: Color.fromARGB(255, 25, 25, 25),
    ),
    // Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromARGB(255, 50, 50, 50),
    ),
    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromARGB(100, 0, 0, 0),
    ),
  );
}
