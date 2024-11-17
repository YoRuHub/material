import 'package:flutter/material.dart';
import 'base_model.dart';

class NodeModel extends BaseModel {
  static const String table = 'node';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContents = 'contents';
  static const String columnCreatedAt = 'created_at';

  Future<List<Map<String, dynamic>>> fetchAllNodes() async {
    try {
      final result = await select(
        table,
        columns: [columnId, columnTitle, columnContents, columnCreatedAt],
      );
      return result.isNotEmpty ? result : [];
    } catch (e) {
      debugPrint('Error fetching nodes: $e');
      return [];
    }
  }

  /// ノードのIDに基づいてノードを取得
  ///
  /// [id] ノードのID
  ///
  /// 取得に失敗した場合は空のリストを返す
  Future<List<Map<String, dynamic>>> fetchNodeById(int id) async {
    try {
      final result = await select(
        table,
        columns: [columnId, columnTitle, columnContents, columnCreatedAt],
        whereClause: '$columnId = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result : [];
    } catch (e) {
      debugPrint('Error fetching node: $e');
      return [];
    }
  }

  /// ノードのUPSERTを行う
  ///
  /// [id] が null の場合は新規挿入処理
  /// [id] が null 以外の場合は更新処理
  ///
  /// [title] ノードのタイトル
  /// [contents] ノードの内容
  ///
  /// 返り値: 挿入/更新されたID (0: エラー)
  Future<int> upsertNode(int id, String title, String contents) async {
    final createdAt = DateTime.now().toIso8601String();
    final data = {
      if (id != 0) columnId: id,
      columnTitle: title,
      columnContents: contents,
      columnCreatedAt: createdAt,
    };

    try {
      if (id != 0) {
        // 更新処理
        await upsert(table, data, '$columnId = ?', [id]);
        debugPrint('Node updated successfully');
        return id;
      } else {
        // 新規挿入処理
        final newId = await insert(table, data); // 挿入されたIDを取得
        debugPrint('Node inserted successfully with ID: $newId');
        return newId;
      }
    } catch (e) {
      debugPrint('Error upserting node: $e');
      return 0; // エラー時は 0 を返す
    }
  }

  /// ノードを削除
  ///
  /// [id] ノードのID
  ///
  /// 削除に失敗した場合はエラーを出力する
  Future<void> deleteNode(int id) async {
    try {
      await delete(table, '$columnId = ?', [id]);
      await resetAutoIncrement(table);
      debugPrint('Node deleted successfully with ID: $id');
    } catch (e) {
      debugPrint('Error deleting node: $e');
    }
  }
}
