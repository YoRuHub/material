import 'package:flutter/material.dart';
import 'package:flutter_app/database/database_helper.dart';
import 'package:flutter_app/providers/project_provider.dart';
import 'package:flutter_app/screens/home_screen.dart'; // HomeScreenのインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_icon.dart'; // CustomIcons のインポート
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
    // SVGIconのプリロード処理
    await CustomIcons.preloadIcons();
    // データベースの初期化
    await _initDatabase();

    // プロジェクトデータの読み込み
    await _loadProjects();

    // 初期化処理が終わったら、HomeScreenに遷移
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const ProviderScope(child: HomeScreen())),
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

  // プロジェクトデータの読み込み
  Future<void> _loadProjects() async {
    final projectNotifier = ref.read(projectNotifierProvider.notifier);

    try {
      // プロジェクトデータを読み込み
      await projectNotifier.loadProjects(); // プロジェクトを読み込む処理を追加
    } catch (e) {
      debugPrint("Error loading projects: $e");
    }
  }
}
