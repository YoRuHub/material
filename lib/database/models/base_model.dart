import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

abstract class BaseModel {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  // データを挿入し、挿入された行のIDを返す
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await _db;
    try {
      final id = await db.insert(table, values);
      debugPrint('Inserted data into $table successfully with ID: $id');
      return id; // 挿入されたIDを返す
    } catch (e) {
      debugPrint('Error inserting data into $table: $e');
      return -1; // エラー時は -1 を返す
    }
  }

  // データを更新
  Future<void> update(String table, Map<String, dynamic> values,
      String whereClause, List<dynamic> whereArgs) async {
    final db = await _db;
    try {
      await db.update(table, values, where: whereClause, whereArgs: whereArgs);
      debugPrint('Updated data in $table successfully.');
    } catch (e) {
      debugPrint('Error updating data in $table: $e');
    }
  }

  // データを挿入または更新
  Future<void> upsert(String table, Map<String, dynamic> values,
      String whereClause, List<dynamic> whereArgs) async {
    final db = await _db;
    try {
      final existingData = await db.query(
        table,
        where: whereClause,
        whereArgs: whereArgs,
      );

      if (existingData.isNotEmpty) {
        await update(table, values, whereClause, whereArgs);
      } else {
        await insert(table, values);
      }
    } catch (e) {
      debugPrint('Error upserting data in $table: $e');
    }
  }

  // データを削除
  Future<void> delete(
      String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await _db;
    try {
      await db.delete(table, where: whereClause, whereArgs: whereArgs);
      debugPrint('Deleted data from $table successfully.');
    } catch (e) {
      debugPrint('Error deleting data from $table: $e');
    }
  }

  // データを取得
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? whereClause,
    List<dynamic>? whereArgs,
    int? limit,
    List<String>? columns,
  }) async {
    final db = await _db;
    try {
      return await db.query(
        table,
        columns: columns,
        where: whereClause,
        whereArgs: whereArgs,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error selecting data from $table: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> selectJoin({
    required String baseTable,
    required List<String> joinTables,
    required String onCondition,
    String? whereClause,
    List<dynamic>? whereArgs,
    List<String>? columns,
    int? limit,
  }) async {
    final db = await _db;
    try {
      // ジョイン条件の生成
      final joinClause = joinTables.map((table) {
        return 'LEFT JOIN $table ON $onCondition';
      }).join(' ');

      // SQL クエリの生成
      final query = '''
        SELECT ${columns?.join(', ') ?? '*'}
        FROM $baseTable
        $joinClause
        ${whereClause != null ? 'WHERE $whereClause' : ''}
        ${limit != null ? 'LIMIT $limit' : ''}
      ''';
      final results = await db.rawQuery(query, whereArgs);
      return results;
    } catch (e) {
      debugPrint('Error selecting data from $baseTable: $e');
      return [];
    }
  }
}
