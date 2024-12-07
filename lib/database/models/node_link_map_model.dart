import 'package:flutter_app/models/node_map.dart';
import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class NodeLinkMapModel extends BaseModel {
  static const String table = 'node_link_map';
  static const String columnSourceId = 'source_id';
  static const String columnTargetId = 'target_id';
  static const String columnProjectId = 'project_id';

  /// データベースから全てのノードマップを取得
  Future<List<NodeMap>> fetchAllNodeMap(int projectId) async {
    try {
      // データを取得
      final result = await select(
        table,
        columns: [columnSourceId, columnTargetId, columnProjectId],
        whereClause: '$columnProjectId = ?',
        whereArgs: [projectId],
      );
      // 結果が空でない場合にログとともに返す
      if (result.isNotEmpty) {
        final nodeMap = result
            .map((row) => NodeMap(
                row[columnSourceId], row[columnTargetId], row[columnProjectId]))
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
  Future<void> insertNodeMap(int sourceId, int targetId, int projectId) async {
    try {
      // 既存データをチェック
      final result = await select(
        table,
        columns: [columnSourceId, columnTargetId, columnProjectId],
        whereClause:
            '$columnSourceId = ? AND $columnTargetId = ? AND $columnProjectId = ?',
        whereArgs: [sourceId, targetId, projectId],
      );

      // データが存在しない場合のみ挿入
      if (result.isEmpty) {
        await insert(
          table,
          {
            columnSourceId: sourceId,
            columnTargetId: targetId,
            columnProjectId: projectId,
          },
        );
        Logger.info(
            'Inserted node map: sourceId=$sourceId, targetId=$targetId, projectId=$projectId');
      } else {
        Logger.info(
            'Node map already exists: sourceId=$sourceId, targetId=$targetId, projectId=$projectId');
      }
    } catch (e) {
      Logger.error('Error inserting node map: $e');
      rethrow;
    }
  }

  /// ノードマップ(親)を削除
  Future<void> deleteParentNodeMap(int sourceId) async {
    try {
      await delete(table, '$columnSourceId = ?', [sourceId]);
    } catch (e) {
      Logger.error('Error deleting node map: $e');
      rethrow;
    }
  }

  /// ノードマップ(子)を削除
  Future<void> deleteChildNodeMap(int targetId) async {
    try {
      await delete(table, '$columnTargetId = ?', [targetId]);
    } catch (e) {
      Logger.error('Error deleting node map: $e');
      rethrow;
    }
  }
}
