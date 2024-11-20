import 'package:flutter_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

abstract class BaseModel {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  /// データを挿入, IDを取得
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await _db;
    try {
      final id = await db.insert(table, values);
      Logger.debug('Successfully inserted into $table with ID $id');
      return id;
    } catch (e) {
      Logger.error('Error inserting data into $table: $e');
      rethrow;
    }
  }

  /// データを更新
  Future<void> update(String table, Map<String, dynamic> values,
      String whereClause, List<dynamic> whereArgs) async {
    final db = await _db;
    try {
      await db.update(table, values, where: whereClause, whereArgs: whereArgs);
      Logger.debug('Successfully updated data in $table');
    } catch (e) {
      Logger.error('Error updating data in $table: $e');
      rethrow;
    }
  }

  /// データを挿入または更新
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

      Logger.debug('Successfully upserted data in $table');
    } catch (e) {
      Logger.error('Error upserting data in $table: $e');
      rethrow;
    }
  }

  /// データを削除
  Future<void> delete(
      String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await _db;
    try {
      await db.delete(table, where: whereClause, whereArgs: whereArgs);
      Logger.debug('Successfully deleted data from $table');
    } catch (e) {
      Logger.error('Error deleting data from $table: $e');
      rethrow;
    }
  }

  /// データを取得するためのメソッド
  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? whereClause,
    List<dynamic>? whereArgs,
    int? limit,
    List<String>? columns,
  }) async {
    final db = await _db;
    try {
      final result = await db.query(
        table,
        columns: columns,
        where: whereClause,
        whereArgs: whereArgs,
        limit: limit,
      );
      Logger.debug(
          'Successfully fetched data from $table: ${result.length} rows');
      return result;
    } catch (e) {
      Logger.error('Error selecting data from $table: $e');
      rethrow;
    }
  }

  /// データを取得するためのメソッド
  Future<List<Map<String, dynamic>>> selectJoin({
    required String baseTable,
    required List<Map<String, String>> joinTables,
    String? whereClause,
    List<dynamic>? whereArgs,
    List<String>? columns,
    int? limit,
  }) async {
    final db = await _db;
    try {
      // ジョイン条件の生成
      final joinClause = joinTables.map((join) {
        final table = join.keys.first;
        final onCondition = join.values.first;
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

      Logger.debug('Executing query: $query with args: $whereArgs');
      final results = await db.rawQuery(query, whereArgs);

      Logger.debug(
          'Successfully fetched ${results.length} rows from $baseTable');
      return results;
    } catch (e) {
      Logger.error('Error selecting data with join from $baseTable: $e');
      rethrow;
    }
  }

  /// 自動インクリメントのIDシーケンスをリセットする
  Future<void> resetAutoIncrement(String table) async {
    final db = await _db;
    try {
      await db.execute('DELETE FROM sqlite_sequence WHERE name = ?', [table]);
      Logger.debug('Successfully reset auto-increment sequence for $table');
    } catch (e) {
      Logger.error('Error resetting auto-increment sequence for $table: $e');
      rethrow;
    }
  }
}
