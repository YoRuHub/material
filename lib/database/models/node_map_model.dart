import 'package:flutter/material.dart';

import 'base_model.dart';

class NodeMapModel extends BaseModel {
  static const String table = 'node_map';
  static const String columnParentId = 'parent_id';
  static const String columnChildId = 'child_id';

  /// ノードマップを取得
  Future<Map<String, dynamic>?> fetchNodeMap() async {
    try {
      final result = await select(
        table,
        columns: [columnParentId, columnChildId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error fetching node map: $e');
      return null;
    }
  }

  /// ノードマップを更新
}
