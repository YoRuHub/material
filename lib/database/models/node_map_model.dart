import 'package:flutter/material.dart';

import 'base_model.dart';

class NodeMapModel extends BaseModel {
  static const String table = 'node_map';
  static const String columnParentId = 'parent_id';
  static const String columnChildId = 'child_id';

  /// ノードマップを取得
  Future<List<MapEntry>> fetchAllNodeMap() async {
    try {
      final result = await select(
        table,
        columns: [columnParentId, columnChildId],
      );
      debugPrint('result: $result');
      return result.isNotEmpty
          ? result
              .map((row) => MapEntry(row[columnParentId], row[columnChildId]))
              .toList()
          : [];
    } catch (e) {
      debugPrint('Error fetching node map: $e');
      return [];
    }
  }

  Future<void> insertNodeMap(int parentId, int childId) async {
    try {
      await insert(
        table,
        {columnParentId: parentId, columnChildId: childId},
      );
      debugPrint('Node map inserted successfully');
    } catch (e) {
      debugPrint('Error upserting node map: $e');
    }
  }

  Future<void> deleteParentNodeMap(int parentId) async {
    try {
      await delete(table, '$columnParentId = ?', [parentId]);
      debugPrint('Node map deleted successfully');
    } catch (e) {
      debugPrint('Error deleting node map: $e');
    }
  }

  Future<void> deleteChildNodeMap(int childId) async {
    try {
      await delete(table, '$columnChildId = ?', [childId]);
      debugPrint('Node map deleted successfully');
    } catch (e) {
      debugPrint('Error deleting node map: $e');
    }
  }
}
