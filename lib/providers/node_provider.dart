import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_color_utils.dart';

class NodeNotifier extends StateNotifier<List<Node>> {
  NodeNotifier() : super([]);
  final _nodeModel = NodeModel();
  final _nodeMapModel = NodeMapModel();

  // ノードの読み込み
  Future<void> loadNodes(int projectId) async {
    try {
      final nodesData = await _nodeModel.fetchAllNodes(projectId);
      List<Node> loadedNodes = nodesData.map((node) {
        return Node(
          id: node['id'] as int,
          position: vector_math.Vector2(0, 0), // 初期位置は後で更新
          velocity: vector_math.Vector2(0, 0),
          color:
              node['color'] != null ? Color(node['color'] as int) : Colors.blue,
          radius: 30.0, // デフォルト値
          title: node['title'] as String,
          contents: node['contents'] as String,
          projectId: projectId,
          createdAt: node['created_at'] as String,
        );
      }).toList();

      // ノードの関係性マップを取得して親子関係を設定
      final nodeMap = await _nodeMapModel.fetchAllNodeMap();
      for (var entry in nodeMap) {
        int parentId = entry.key;
        int childId = entry.value;

        Node? parentNode = loadedNodes.cast<Node?>().firstWhere(
              (node) => node?.id == parentId,
              orElse: () => null,
            );

        Node? childNode = loadedNodes.cast<Node?>().firstWhere(
              (node) => node?.id == childId,
              orElse: () => null,
            );

        if (parentNode != null && childNode != null) {
          childNode.parent = parentNode;
          if (!parentNode.children.contains(childNode)) {
            parentNode.children.add(childNode);
            NodeColorUtils.updateNodeColor(childNode);
          }
        }
      }

      state = loadedNodes;
      Logger.debug('Nodes loaded successfully for project $projectId');
    } catch (e) {
      Logger.error('Error loading nodes: $e');
      rethrow;
    }
  }

  // ノードの追加
  Future<Node> addNode({
    required vector_math.Vector2 position,
    required int projectId,
    String title = '',
    String contents = '',
    Color? color,
    Node? parentNode,
  }) async {
    try {
      // データベースにノードを追加
      final nodeData = await _nodeModel.upsertNode(
        0,
        title,
        contents,
        color,
        projectId,
      );

      // 新しいノードを作成
      final newNode = Node(
        id: nodeData['id'] as int,
        position: position,
        velocity: vector_math.Vector2(0, 0),
        color: color ?? Colors.blue,
        radius: 30.0,
        title: title,
        contents: contents,
        projectId: projectId,
        createdAt: nodeData['created_at'] as String,
        parent: parentNode,
      );

      // 親ノードが指定されている場合、関係性を設定
      if (parentNode != null) {
        await _nodeMapModel.insertNodeMap(parentNode.id, newNode.id);
        parentNode.children.add(newNode);
        NodeColorUtils.updateNodeColor(newNode);
      }

      state = [...state, newNode];
      Logger.debug('Node added successfully: ID: ${newNode.id}');
      return newNode;
    } catch (e) {
      Logger.error('Error adding node: $e');
      rethrow;
    }
  }

  // ノードの更新
  Future<void> updateNode(Node node) async {
    try {
      await _nodeModel.upsertNode(
        node.id,
        node.title,
        node.contents,
        node.color,
        node.projectId,
      );

      state = state.map((n) => n.id == node.id ? node : n).toList();
      Logger.debug('Node updated successfully: ID: ${node.id}');
    } catch (e) {
      Logger.error('Error updating node: $e');
      rethrow;
    }
  }

  // ノードの削除（子ノードも含めて再帰的に削除）
  Future<void> deleteNode(Node node) async {
    try {
      // 子ノードを再帰的に削除
      for (var child in List.from(node.children)) {
        await deleteNode(child);
      }

      // 親子関係を削除
      if (node.parent != null) {
        node.parent!.children.remove(node);
        await _nodeMapModel.deleteChildNodeMap(node.id);
      }
      await _nodeMapModel.deleteParentNodeMap(node.id);

      // ノードを削除
      await _nodeModel.deleteNode(node.id, node.projectId);
      state = state.where((n) => n.id != node.id).toList();

      Logger.debug('Node deleted successfully: ID: ${node.id}');
    } catch (e) {
      Logger.error('Error deleting node: $e');
      rethrow;
    }
  }

  // ノードの位置を更新
  void updateNodePosition(int nodeId, vector_math.Vector2 newPosition) {
    state = state.map((node) {
      if (node.id == nodeId) {
        return Node(
          id: node.id,
          position: newPosition,
          velocity: node.velocity,
          color: node.color,
          radius: node.radius,
          title: node.title,
          contents: node.contents,
          projectId: node.projectId,
          createdAt: node.createdAt,
          parent: node.parent,
          children: node.children,
          isActive: node.isActive,
          isTemporarilyDetached: node.isTemporarilyDetached,
        );
      }
      return node;
    }).toList();
  }

  // 親子関係の更新
  Future<void> updateNodeRelationship(
      Node childNode, Node? newParentNode) async {
    try {
      // 古い親子関係を削除
      if (childNode.parent != null) {
        childNode.parent!.children.remove(childNode);
        await _nodeMapModel.deleteChildNodeMap(childNode.id);
      }

      // 新しい親子関係を設定
      if (newParentNode != null) {
        await _nodeMapModel.insertNodeMap(newParentNode.id, childNode.id);
        childNode.parent = newParentNode;
        newParentNode.children.add(childNode);
        NodeColorUtils.updateNodeColor(childNode);
      }

      state = [...state]; // 状態を更新して再描画をトリガー
      Logger.debug('Node relationship updated successfully');
    } catch (e) {
      Logger.error('Error updating node relationship: $e');
      rethrow;
    }
  }
}

// プロバイダーの定義
final nodeNotifierProvider =
    StateNotifierProvider<NodeNotifier, List<Node>>((ref) {
  return NodeNotifier();
});
