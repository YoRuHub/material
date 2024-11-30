import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';

class NodeOperations {
  // ノードの追加
  static Node addNode({
    required vector_math.Vector2 position,
    Node? parentNode,
    required int nodeId,
    String title = '',
    String contents = '',
    required int projectId,
    Color? color,
    String createdAt = '',
  }) {
    final node = Node(
      position: position,
      velocity: vector_math.Vector2(0, 0),
      color: color ?? NodeColorUtils.getColorForNextGeneration(parentNode),
      radius: NodeConstants.defaultNodeRadius,
      id: nodeId,
      title: title,
      contents: contents,
      projectId: projectId,
      createdAt: createdAt,
    );

    if (parentNode != null) {
      parentNode.children.add(node);
      node.parent = parentNode;
    }

    return node;
  }

  // ノードの削除（再帰的に子ノードも削除）
  static void deleteNodeAndChildren(Node node, List<Node> nodes) {
    // 子ノードを逆順に削除
    for (var i = node.children.length - 1; i >= 0; i--) {
      deleteNodeAndChildren(node.children[i], nodes);
    }

    // 親ノードから切り離す
    node.parent?.children.remove(node);

    // ノードリストから削除
    nodes.remove(node);
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
}
