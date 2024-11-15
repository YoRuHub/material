import 'package:flutter/material.dart';
import 'package:flutter_app/database/database_helper.dart';
import 'package:flutter_app/screens/home_screen.dart'; // HomeScreenのインポート
import '../models/custom_icon.dart'; // CustomIcons のインポート
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    // SVGIconのプリロード処理
    await CustomIcons.preloadIcons();
    // データベースの初期化
    await _initDatabase();

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

  Future<void> _initDatabase() async {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbHelper = DatabaseHelper();
      await dbHelper.database;
      dbHelper.initDatabaseTables();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
