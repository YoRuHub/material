import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/utils/logger.dart';
import 'database_schemas.dart';

class DatabaseHelper {
  static const _databaseName = "material.db";
  static const _databaseVersion = 2;

  static Database? _database;

  factory DatabaseHelper() => _instance;
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getApplicationDocumentsDirectory();
    final path = join(databasesPath.path, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      readOnly: false,
    );
    return _database!;
  }

  // 初期テーブル作成
  Future _onCreate(Database db, int version) async {
    try {
      for (var tableName in DatabaseSchemas.tableSchemas.keys) {
        await _createTable(db, tableName);
      }
    } catch (e) {
      Logger.error('Error during database creation: ${e.toString()}');
      rethrow;
    }
  }

  // データベースアップグレード時に呼ばれる
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < newVersion) {
        for (var tableName in DatabaseSchemas.tableSchemas.keys) {
          await _migrateTable(db, tableName, oldVersion, newVersion);
        }
      }
    } catch (e) {
      Logger.error('Error during database upgrade: ${e.toString()}');
      rethrow;
    }
  }

  // テーブル作成
  Future<void> _createTable(Database db, String tableName) async {
    final schema = DatabaseSchemas.tableSchemas[tableName];
    if (schema == null) {
      Logger.error('Table schema for $tableName not found.');
      return;
    }
    try {
      await db.execute(schema);
    } catch (e) {
      Logger.error('Error creating table $tableName: ${e.toString()}');
      rethrow;
    }
  }

  // スキーマ変更（カラム追加・変更・削除）のためのマイグレーション
  Future<void> _migrateTable(
      Database db, String tableName, int oldVersion, int newVersion) async {
    final schema = DatabaseSchemas.tableSchemas[tableName];
    if (schema != null) {
      try {
        // 必要に応じてスキーマの変更処理を実行
        if (oldVersion < newVersion) {
          await _alterTable(db, tableName);
        }
      } catch (e) {
        Logger.error('Error migrating table $tableName: ${e.toString()}');
        rethrow;
      }
    }
  }

  // テーブル変更処理（例：カラム追加）
  Future<void> _alterTable(Database db, String tableName) async {
    final alterSchema = DatabaseSchemas.alterTableSchemas[tableName];
    if (alterSchema != null) {
      try {
        for (var query in alterSchema) {
          await db.execute(query); // ALTER TABLE クエリ
        }
      } catch (e) {
        Logger.error('Error altering table $tableName: ${e.toString()}');
        rethrow;
      }
    }
  }

  // テーブル削除
  Future<void> dropTable(Database db, String tableName) async {
    try {
      await db.execute('DROP TABLE IF EXISTS $tableName');
    } catch (e) {
      Logger.error('Error dropping table $tableName: ${e.toString()}');
      rethrow;
    }
  }

  // テーブルリセット
  Future<void> resetTables() async {
    final db = await database;
    final tableList = DatabaseSchemas.tableSchemas.keys.toList();

    for (var table in tableList) {
      try {
        await dropTable(db, table);
        await _createTable(db, table);
      } catch (e) {
        Logger.error('Error resetting table $table: ${e.toString()}');
        rethrow;
      }
    }
  }

  // テーブルが存在しない場合、作成
  Future<void> initDatabaseTables() async {
    final db = await database;

    try {
      for (var tableName in DatabaseSchemas.tableSchemas.keys) {
        // テーブルの存在を確認
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );

        if (result.isEmpty) {
          await _createTable(db, tableName);
        }
      }
    } catch (e) {
      Logger.error('Error initializing database tables: ${e.toString()}');
      rethrow;
    }
  }
}
