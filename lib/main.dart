import 'package:flutter/material.dart';
import 'package:flutter_app/theme/theme_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flutter App',
        theme: buildThemeData(),
        home: const SplashScreen(), // 最初に表示する画面
      ),
    );
  }
}
