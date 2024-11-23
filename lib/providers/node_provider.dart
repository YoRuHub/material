import 'package:flutter_app/providers/node_map_provider.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class NodeNotifier extends StateNotifier<List<Node>> {
  late final NodeModel _nodeModel;
  Node? _activeNode;

  Node? get activeNode => _activeNode;

  Node? _draggedNode; // ドラッグ中のノードを保持する

  Node? get draggedNode => _draggedNode; // ドラッグ中のノードを取得

  NodeNotifier() : super([]) {
    _nodeModel = NodeModel();
  }

  Future<void> loadNodes(int projectId) async {
    try {
      // データベースからノードを取得
      final nodesData = await _nodeModel.fetchAllNodes(projectId);
      state = nodesData.map((node) {
        return Node(
          id: node['id'] as int,
          position: vector_math.Vector2(
            (node['x'] as num?)?.toDouble() ?? 100.0,
            (node['y'] as num?)?.toDouble() ?? 100.0,
          ),
          velocity: vector_math.Vector2.zero(),
          color:
              node['color'] != null ? Color(node['color'] as int) : Colors.blue,
          radius: (node['radius'] as num?)?.toDouble() ?? 30.0,
          title: node['title'] as String,
          contents: node['contents'] as String,
          projectId: projectId,
          createdAt: node['created_at'] as String,
        );
      }).toList();
    } catch (e) {
      Logger.error('Error loading nodes: $e');
    }
  }

  Future<void> syncParentChildRelations(
      List<MapEntry<int, int>> nodeMap) async {
    try {
      Logger.debug('Syncing parent-child relations...');
      for (var entry in nodeMap) {
        int parentId = entry.key;
        int childId = entry.value;

        // 親ノードと子ノードを取得
        final parentNode =
            state.firstWhereOrNull((node) => node.id == parentId);
        final childNode = state.firstWhereOrNull((node) => node.id == childId);

        if (parentNode != null && childNode != null) {
          // 子ノードの親を設定
          childNode.parent = parentNode;

          // 親ノードの子リストに追加（重複を防ぐ）
          if (!parentNode.children.contains(childNode)) {
            parentNode.children.add(childNode);
            NodeColorUtils.updateNodeColor(childNode); // 子ノードの色を更新
          }
        }
        Logger.debug('Synced parent-child relation: $parentId -> $childId');
      }

      // 状態を更新
      state = [...state];
    } catch (e) {
      Logger.error('Error syncing parent-child relations: $e');
    }
  }

  Future<void> addNode(Node newNode, NodeMapNotifier nodeMapNotifier) async {
    try {
      Node updatedNode = newNode; // 変更前のノード

      if (activeNode == null) {
        // アクティブノードがない場合：親ノードとして追加
        Logger.debug("Adding a parent node");

        // ノードIDが0の場合、新規にデータベースに追加しIDを取得
        final result = await _nodeModel.upsertNode(newNode.id, newNode.title,
            newNode.contents, newNode.color, newNode.projectId);

        // upsert結果から新しいIDを取得して、更新されたノードを作成
        updatedNode = updatedNode.copyWith(id: result['id']);

        // 状態を更新
        state = [...state, updatedNode];
      } else {
        // アクティブノードがいる場合：子ノードとして追加
        Logger.debug("Adding a child node to active node: ${activeNode!.id}");

        // ノードIDが0の場合、新規にデータベースに追加しIDを取得
        final result = await _nodeModel.upsertNode(newNode.id, newNode.title,
            newNode.contents, newNode.color, newNode.projectId);

        // upsert結果から新しいIDを取得して、更新されたノードを作成
        updatedNode = updatedNode.copyWith(id: result['id']);

        // アクティブノードに子ノードを設定
        updatedNode = updatedNode.copyWith(parent: activeNode);
        activeNode!.children.add(updatedNode);

        // ノードマップを更新
        await nodeMapNotifier.addNodeMap(activeNode!.id, updatedNode.id);

        // 状態を更新
        state = [...state, updatedNode];
      }
    } catch (e) {
      Logger.error("Error adding node: $e");
    }
  }

  /// アクティブノードを設定
  void setActiveNode(Node? node) {
    if (_activeNode != null) {
      // 以前のアクティブノードを非アクティブ化
      updateNodeState(_activeNode!.copyWith(isActive: false));
    }

    // 新しいアクティブノードを設定
    if (node != null) {
      updateNodeState(node.copyWith(isActive: true));
    }

    _activeNode = node;
  }

  void updateNodeState(Node updatedNode) {
    state = [
      for (final node in state)
        if (node.id == updatedNode.id) updatedNode else node
    ];
  }

  void updateNodeData(Node updatedNode) {
    // DBに保存し、状態も更新
    _nodeModel.upsertNode(
      updatedNode.id,
      updatedNode.title,
      updatedNode.contents,
      updatedNode.color,
      updatedNode.projectId,
    );
    state = [
      for (var node in state)
        if (node.id == updatedNode.id) updatedNode else node
    ];
  }

  void removeNode(Node node) {
    // dbから削除
    _nodeModel.deleteNode(node.id, node.projectId);
    state = state.where((existingNode) => existingNode.id != node.id).toList();
  }

  void updateParentChildRelationships(Map<int, int> nodeMap) {
    final updatedNodes = [...state];

    for (var entry in nodeMap.entries) {
      final parentId = entry.key;
      final childId = entry.value;

      final parentNode = updatedNodes
          .cast<Node?>()
          .firstWhere((node) => node?.id == parentId, orElse: () => null);
      final childNode = updatedNodes
          .cast<Node?>()
          .firstWhere((node) => node?.id == childId, orElse: () => null);

      if (parentNode != null && childNode != null) {
        // 子ノードの親を設定
        childNode.parent = parentNode;

        // 親ノードの子リストに追加（重複を防ぐ）
        if (!parentNode.children.contains(childNode)) {
          parentNode.children.add(childNode);
          NodeColorUtils.updateNodeColor(childNode); // 子ノードの色を更新
        }
      }
    }

    // 状態を更新
    state = updatedNodes;
  }

  // ドラッグ中のノードを設定
  void setDraggedNode(Node node) {
    _draggedNode = node;
  }

  // ドラッグ中のノードをクリア
  void clearDraggedNode() {
    _draggedNode = null;
  }
}

final nodeNotifierProvider = StateNotifierProvider<NodeNotifier, List<Node>>(
  (ref) => NodeNotifier(), // NodeNotifierをインスタンス化
);
