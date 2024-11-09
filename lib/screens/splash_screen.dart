import 'package:flutter/material.dart';
import 'package:flutter_app/screens/home_screen.dart'; // HomeScreenのインポート
import '../models/custom_icon.dart'; // CustomIcons のインポート

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 初期化処理を非同期で実行
    _initializeApp();
  }

  // 初期化処理を行い、その後画面遷移する非同期メソッド
  Future<void> _initializeApp() async {
    // まずプリロード処理
    await CustomIcons.preloadIcons();

    // その後、他の初期化処理があればここに追加

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
