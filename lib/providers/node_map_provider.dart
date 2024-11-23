import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/utils/logger.dart';

// ノードマップの状態を管理するNotifierクラス
class NodeMapNotifier extends StateNotifier<List<MapEntry<int, int>>> {
  // 内部でNodeMapModelのインスタンスを作成して使用
  final NodeMapModel _nodeMapModel = NodeMapModel();

  NodeMapNotifier() : super([]);

  // ノードマップを全て取得
  Future<void> loadNodeMaps() async {
    try {
      final nodeMap = await _nodeMapModel.fetchAllNodeMap();
      state = nodeMap
          .map((entry) =>
              MapEntry<int, int>(entry.key as int, entry.value as int))
          .toList();
    } catch (e) {
      Logger.error('Error loading node maps: $e');
    }
  }

  // ノードマップを追加
  Future<void> addNodeMap(int parentId, int childId) async {
    try {
      await _nodeMapModel.insertNodeMap(parentId, childId);
      await loadNodeMaps(); // データ更新後に再ロード
    } catch (e) {
      Logger.error('Error adding node map: $e');
    }
  }

  // 親ノードマップを削除
  Future<void> deleteParentNodeMap(int parentId) async {
    try {
      await _nodeMapModel.deleteParentNodeMap(parentId);
      await loadNodeMaps(); // データ更新後に再ロード
    } catch (e) {
      Logger.error('Error deleting parent node map: $e');
    }
  }

  // 子ノードマップを削除
  Future<void> deleteChildNodeMap(int childId) async {
    try {
      await _nodeMapModel.deleteChildNodeMap(childId);
      await loadNodeMaps(); // データ更新後に再ロード
    } catch (e) {
      Logger.error('Error deleting child node map: $e');
    }
  }
}

// NodeMapNotifierのインスタンスを提供するプロバイダ
final nodeMapNotifierProvider =
    StateNotifierProvider<NodeMapNotifier, List<MapEntry<int, int>>>((ref) {
  return NodeMapNotifier(); // NodeMapNotifierを直接初期化
});
