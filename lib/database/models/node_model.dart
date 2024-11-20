import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class NodeModel extends BaseModel {
  static const String table = 'node';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContents = 'contents';
  static const String columnProjectId = 'project_id';
  static const String columnCreatedAt = 'created_at';

  /// プロジェクトに属するノード全件取得
  Future<List<Map<String, dynamic>>> fetchAllNodes(int projectId) async {
    try {
      // ノードの取得
      final result = await select(
        table,
        columns: [
          columnId,
          columnTitle,
          columnContents,
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

  /// プロジェクトに属するノードを更新または挿入
  Future<int> upsertNode(
      int id, String title, String contents, int projectId) async {
    final createdAt = DateTime.now().toIso8601String();
    final data = {
      if (id != 0) columnId: id,
      columnTitle: title,
      columnContents: contents,
      columnCreatedAt: createdAt,
      columnProjectId: projectId
    };

    try {
      if (id != 0) {
        // 更新処理
        await upsert(table, data, '$columnId = ? AND $columnProjectId = ?',
            [id, projectId]);
        return id;
      } else {
        // 新規挿入処理
        final newId = await insert(table, data);
        return newId;
      }
    } catch (e) {
      Logger.error('Error upserting node: $e');
      return 0; // エラー時は 0 を返す
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
}
