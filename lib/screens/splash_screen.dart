import 'package:flutter/material.dart';
import 'package:flutter_app/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ビルド完了後に初期化処理を呼び出す
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // 初期化処理を行い、その後画面遷移する非同期メソッド
  Future<void> _initializeApp() async {
    // 必要な非同期処理を実行
    await Future.delayed(const Duration(seconds: 2)); // ダミーの遅延処理

    // 初期化処理が終わったら、HomeScreenに遷移
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Loading..."), // プリロード中のテキスト表示
      ),
    );
  }
}
