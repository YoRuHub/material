import 'package:flutter/material.dart';
import 'package:flutter_app/db/database_helper.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 初期化処理を非同期で実行
    _initializeApp();
  }

  // 初期化処理を行い、その後画面遷移する非同期メソッド
  Future<void> _initializeApp() async {
    try {
      // ロガーの読み込み
      await Logger.initialize(true);
      // データベースの初期化
      await _initDatabase();

      // 初期化処理が終わったら、HomeScreenに遷移
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const ProviderScope(child: HomeScreen())),
        );
      }
      Logger.info('App initialized.');
    } catch (e) {
      Logger.error('Error initializing app: ${e.toString()}');
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
      Logger.info('Database initialized.');
    } catch (e) {
      Logger.error('Error initializing database: ${e.toString()}');
    }
  }
}
