import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'database_schemas.dart';

class DatabaseHelper {
  static const _databaseName = "home_garden.db";
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
      readOnly: false,
    );
    return _database!;
  }

  Future _onCreate(Database db, int version) async {
    try {
      for (var tableName in DatabaseSchemas.tableSchemas.keys) {
        await _createTable(db, tableName);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _createTable(Database db, String tableName) async {
    final schema = DatabaseSchemas.tableSchemas[tableName];
    if (schema == null) {
      return;
    }
    try {
      await db.execute(schema);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> dropTable(Database db, String tableName) async {
    try {
      await db.execute('DROP TABLE IF EXISTS $tableName');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> resetTables() async {
    final db = await database;

    final tableList = DatabaseSchemas.tableSchemas.keys.toList();

    for (var table in tableList) {
      try {
        await dropTable(db, table);
        await _createTable(db, table);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  // Init関数：テーブルが全て存在するか確認し、存在しない場合は作成
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
      debugPrint(e.toString());
    }
  }
}
