import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // SplashScreen をインポート
import 'theme/theme_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmic App',
      theme: buildThemeData(),
      home: const SplashScreen(), // 初期画面を SplashScreen に変更
    );
  }
}
