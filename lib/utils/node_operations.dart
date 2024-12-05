import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/providers/node_state_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';

class NodeOperations {
  /// ノードの追加
  static Future<Node> addNode({
    required BuildContext context,
    required WidgetRef ref,
    required int projectId,
    int nodeId = 0,
    String title = '',
    String contents = '',
    Color? color,
    String createdAt = '',
    Node? parentNode,
  }) async {
    final NodesNotifier nodesNotifier =
        ref.read<NodesNotifier>(nodesProvider.notifier);
    final NodeModel nodeModel = NodeModel();

    // ノードの配置位置を取得
    vector_math.Vector2 basePosition = _calculateBasePosition(
      context,
      ref,
    );

    // ノードのカラーを取得
    if (color == null) {
      color = NodeColorUtils.getColorForCurrentGeneration(null);
      if (ref.read(nodeStateNotifierProvider).activeNode != null) {
        color = NodeColorUtils.getColorForNextGeneration(
            ref.read(nodeStateNotifierProvider).activeNode);
      }
    }

    final newNodeData =
        await nodeModel.upsertNode(nodeId, title, contents, color, projectId);
    final newNodeId = newNodeData['id'] as int;
    final newNodeTitle = newNodeData['title'] as String;
    final newNodeContents = newNodeData['contents'] as String;
    final newNodeColor = newNodeData['color'] as int?;
    final newNodeCreatedAt = newNodeData['created_at'] as String;

    // ノード要素を作成
    final newNode = Node(
        position: basePosition,
        velocity: vector_math.Vector2(0, 0),
        radius: NodeConstants.defaultNodeRadius,
        parent: parentNode,
        id: newNodeId,
        title: newNodeTitle,
        contents: newNodeContents,
        color: newNodeColor != null ? Color(newNodeColor) : null,
        projectId: projectId,
        createdAt: newNodeCreatedAt);

    if (parentNode != null) {
      nodesNotifier.addChildToNode(parentNode.id, newNode, projectId);
    }

    nodesNotifier.addNode(newNode);

    return newNode;
  }

  /// ノードの削除
  static Future<void> deleteNode(
      Node node, int projectId, WidgetRef ref) async {
    final nodeModel = NodeModel();
    final nodeMapModel = NodeMapModel();
    final NodesNotifier nodesNotifier =
        ref.read<NodesNotifier>(nodesProvider.notifier);
    // 子ノードを逆順に削除
    for (var i = node.children.length - 1; i >= 0; i--) {
      await deleteNode(node.children[i], projectId, ref);
    }

    // 子ノードを削除
    if (node.parent != null) {
      await nodesNotifier.removeChildFromNode(node.parent!.id, node);
    }

    // プロバイダーから削除
    nodesNotifier.removeNode(node);

    // dbから削除
    await nodeModel.deleteNode(node.id, projectId);
    await nodeMapModel.deleteParentNodeMap(node.id);
  }

  // 子ノードの切り離し
  static void detachChildren(Node node) {
    for (var child in node.children) {
      child.parent = null;
      // 切り離した子ノードにランダムな初速度を与える
      child.velocity = vector_math.Vector2(
        Random().nextDouble() * NodeConstants.randomOffsetRange -
            NodeConstants.randomOffsetHalf,
        Random().nextDouble() * NodeConstants.randomOffsetRange -
            NodeConstants.randomOffsetHalf,
      );
    }
    node.children.clear();
  }

  // ノード間の距離チェック
  static bool areNodesClose(Node node1, Node node2) {
    double distance = (node1.position - node2.position).length;
    return distance < NodeConstants.snapTriggerDistance;
  }

  // ランダムな位置オフセットの生成
  static vector_math.Vector2 generateRandomOffset() {
    return vector_math.Vector2(
      Random().nextDouble() * NodeConstants.randomOffsetRange -
          NodeConstants.randomOffsetHalf,
      Random().nextDouble() * NodeConstants.randomOffsetRange -
          NodeConstants.randomOffsetHalf,
    );
  }

  // 接続されたノードの検索
  static Set<Node> findConnectedNodes(Node startNode) {
    Set<Node> connectedNodes = {};
    List<Node> queue = [startNode];

    while (queue.isNotEmpty) {
      Node currentNode = queue.removeAt(0);
      if (connectedNodes.contains(currentNode)) continue;

      connectedNodes.add(currentNode);

      // 子ノードを追加
      queue.addAll(currentNode.children
          .where((child) => !connectedNodes.contains(child)));

      // 親ノードを追加
      if (currentNode.parent != null &&
          !connectedNodes.contains(currentNode.parent)) {
        queue.add(currentNode.parent!);
      }

      // 兄弟ノードを追加
      if (currentNode.parent != null) {
        queue.addAll(currentNode.parent!.children
            .where((sibling) => !connectedNodes.contains(sibling)));
      }
    }

    return connectedNodes;
  }

  /// Calculate the base position for the new node
  static vector_math.Vector2 _calculateBasePosition(
    BuildContext context,
    WidgetRef ref,
  ) {
    vector_math.Vector2 basePosition;

    // 画面サイズとAppBarの高さを考慮して中央を計算
    final screenCenter = CoordinateUtils.calculateScreenCenter(
      MediaQuery.of(context).size, // 画面サイズ
      AppBar().preferredSize.height, // AppBarの高さ（指定がなければ0にしても良い）
    );

    // 中央座標をワールド座標に変換
    basePosition = CoordinateUtils.screenToWorld(
      screenCenter, // 画面中央
      ref.read(screenProvider).offset,
      ref.read(screenProvider).scale,
    );

    // ノードの重なりチェックと調整
    basePosition =
        _adjustPositionToAvoidOverlap(basePosition, ref.read(nodesProvider));

    return basePosition;
  }

  /// ノードの位置が重ならないように調整
  static vector_math.Vector2 _adjustPositionToAvoidOverlap(
    vector_math.Vector2 basePosition,
    List<Node> nodes,
  ) {
    const double minDistance = NodeConstants.nodePreferredDistance; // 最小距離

    // 既存ノードと重ならないように少しずらす
    for (var node in nodes) {
      final distance =
          CoordinateUtils.calculateDistance(basePosition, node.position);

      // 距離が最小距離より小さい場合、重なっているので少しずらす
      if (distance < minDistance) {
        basePosition = basePosition +
            vector_math.Vector2(
              (Random().nextDouble() * 2 - 1) * minDistance,
              (Random().nextDouble() * 2 - 1) * minDistance,
            );
      }
    }

    return basePosition;
  }
}
