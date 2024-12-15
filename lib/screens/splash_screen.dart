import 'package:flutter/material.dart';
import 'package:flutter_app/database/database_helper.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/mind_map_screen.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/models/api_model.dart';
import '../models/ai_model_data.dart';
import '../providers/api_provider.dart';

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
      // 設定データの読み込み
      await _loadSettings();
      // APIキーの読み込み
      await _loadApiSettings();

      // 初期化処理が終わったら、HomeScreenに遷移
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const ProviderScope(child: MindMapScreen(projectNode: null))),
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
    } catch (e) {
      Logger.error('Error initializing database: ${e.toString()}');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
      await settingsNotifier.loadSettings(); // 設定を読み込む処理を追加
    } catch (e) {
      Logger.error('Error loading settings: ${e.toString()}');
    }
  }

  Future<void> _loadApiSettings() async {
    try {
      final apiModel = ApiModel();

      // AiModel列挙型を使用してAPIタイプを取得
      final apiTypes = AiModel.values.map((e) => e.name).toList();

      for (var apiType in apiTypes) {
        final apiData = await apiModel.fetchApi(apiType);

        if (apiData != null) {
          // APIのステータスがnullまたは空であれば、noneとする
          final apiStatus = apiData['status']?.isEmpty ?? true
              ? ApiStatus.none
              : apiData['status'] == 'valid'
                  ? ApiStatus.valid
                  : ApiStatus.invalid;

          // プロバイダーに設定
          ref.read(apiStatusProvider.notifier).updateStatus(apiType, apiStatus);
        }
      }
    } catch (e) {
      Logger.error('Error loading API settings: ${e.toString()}');
    }
  }
}
