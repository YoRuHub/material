import 'package:flutter/material.dart';
import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class NodeModel extends BaseModel {
  static const String table = 'node';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContents = 'contents';
  static const String columnColor = 'color';
  static const String columnProjectId = 'project_id';
  static const String columnCreatedAt = 'created_at';

  /// すべてのノードを取得
  Future<List<Map<String, dynamic>>> fetchAllNodes() async =>
      await select(table);

  /// プロジェクトに属するノード全件取得
  Future<List<Map<String, dynamic>>> fetchProjectNodes(int projectId) async {
    try {
      // ノードの取得
      final result = await select(
        table,
        columns: [
          columnId,
          columnTitle,
          columnContents,
          columnColor,
          columnProjectId,
          columnCreatedAt
        ],
        whereClause: '$columnProjectId = ?',
        whereArgs: [projectId],
      );

      // 結果が空でない場合にログとともに返す
      if (result.isNotEmpty) {
        return result;
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error fetching nodes for project $projectId: $e');
      return [];
    }
  }

  /// プロジェクトに属する特定のノードを取得
  Future<List<Map<String, dynamic>>> fetchNodeById(
      int id, int projectId) async {
    try {
      final result = await select(
        table,
        columns: [
          columnId,
          columnTitle,
          columnContents,
          columnColor,
          columnProjectId,
          columnCreatedAt
        ],
        whereClause: '$columnId = ? AND $columnProjectId = ?',
        whereArgs: [id, projectId],
      );
      if (result.isNotEmpty) {
        return result;
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error fetching nodes for project $projectId: $e');
      return [];
    }
  }

  /// プロジェクトに属するノードを更新または挿入し、処理後のデータを返す
  Future<Map<String, dynamic>> upsertNode(
    int id,
    String title,
    String contents,
    Color? color,
    int projectId,
  ) async {
    final createdAt = DateTime.now().toIso8601String();
    final data = {
      if (id != 0) columnId: id,
      columnTitle: title,
      columnContents: contents,
      if (color != null) columnColor: color.value,
      columnCreatedAt: createdAt,
      columnProjectId: projectId,
    };

    try {
      if (id != 0) {
        // 更新処理
        final updatedData = await upsert(
          table,
          data,
          '$columnId = ? AND $columnProjectId = ?',
          [id, projectId],
        );
        Logger.debug('Node updated successfully: $updatedData');
        return updatedData;
      } else {
        // 新規挿入処理
        final insertedData = await insert(table, data);
        Logger.debug('Node inserted successfully: $insertedData');
        return insertedData;
      }
    } catch (e) {
      Logger.error('Error upserting node: $e');
      rethrow;
    }
  }

  /// プロジェクトに属するノードを削除
  Future<void> deleteNode(int id, int projectId) async {
    try {
      await delete(
          table, '$columnId = ? AND $columnProjectId = ?', [id, projectId]);
      await resetAutoIncrement(table);
    } catch (e) {
      Logger.error('Error deleting node: $e');
      rethrow;
    }
  }

  /// プロジェクトに属するノードを全て削除
  Future<void> deleteAllNodes(int projectId) async {
    try {
      await delete(table, '$columnProjectId = ?', [projectId]);
      await resetAutoIncrement(table);
    } catch (e) {
      Logger.error('Error deleting all nodes: $e');
      rethrow;
    }
  }
}
