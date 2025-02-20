import 'package:flutter_app/models/node_map.dart';
import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class NodeMapModel extends BaseModel {
  static const String table = 'node_map';
  static const String columnParentId = 'parent_id';
  static const String columnChildId = 'child_id';
  static const String columnProjectId = 'project_id';

  /// データベースから全てのノードマップを取得
  Future<List<NodeMap>> fetchAllNodeMap(int projectId) async {
    try {
      // データを取得
      final result = await select(
        table,
        columns: [columnParentId, columnChildId, columnProjectId],
        whereClause: '$columnProjectId = ?',
        whereArgs: [projectId],
      );
      // 結果が空でない場合にログとともに返す
      if (result.isNotEmpty) {
        final nodeMap = result
            .map((row) => NodeMap(
                row[columnParentId], row[columnChildId], row[columnProjectId]))
            .toList();
        return nodeMap;
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error fetching node map: $e');
      return [];
    }
  }

  /// ノードマップを追加
  Future<void> insertNodeMap(int parentId, int childId, int projectId) async {
    try {
      // 既存データをチェック
      final result = await select(
        table,
        columns: [columnParentId, columnChildId, columnProjectId],
        whereClause:
            '$columnParentId = ? AND $columnChildId = ? AND $columnProjectId = ?',
        whereArgs: [parentId, childId, projectId],
      );

      // データが存在しない場合のみ挿入
      if (result.isEmpty) {
        await insert(
          table,
          {
            columnParentId: parentId,
            columnChildId: childId,
            columnProjectId: projectId,
          },
        );
        Logger.info(
            'Inserted node map: parentId=$parentId, childId=$childId, projectId=$projectId');
      } else {
        Logger.info(
            'Node map already exists: parentId=$parentId, childId=$childId, projectId=$projectId');
      }
    } catch (e) {
      Logger.error('Error inserting node map: $e');
      rethrow;
    }
  }

  /// ノードマップ(親)を削除
  Future<void> deleteParentNodeMap(int parentId) async {
    try {
      await delete(table, '$columnParentId = ?', [parentId]);
    } catch (e) {
      Logger.error('Error deleting node map: $e');
      rethrow;
    }
  }

  /// ノードマップ(子)を削除
  Future<void> deleteChildNodeMap(int childId) async {
    try {
      await delete(table, '$columnChildId = ?', [childId]);
    } catch (e) {
      Logger.error('Error deleting node map: $e');
      rethrow;
    }
  }
}
