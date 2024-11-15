import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';

class NodeOperations {
  // ノードの追加
  static Node addNode({
    required vector_math.Vector2 position,
    Node? parentNode,
    int? generation,
    required int nodeId,
    String title = '',
    String contents = '',
    String createdAt = '',
  }) {
    final node = Node(
      position: position,
      velocity: vector_math.Vector2(0, 0),
      color: _getColorForGeneration(generation ?? 0),
      radius: NodeConstants.defaultNodeRadius,
      id: nodeId,
      title: title,
      contents: contents,
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

  // 親子関係の更新
  static void updateParentChildRelationship(Node draggedNode, Node newParent) {
    // 現在の親ノードから子ノードを削除
    if (draggedNode.parent != null) {
      draggedNode.parent!.children.remove(draggedNode);
    }

    // 新しい親ノードを設定
    draggedNode.parent = newParent;
    newParent.children.add(draggedNode);

    // 色を更新
    updateNodeColor(newParent);
  }

  // ノードの色を更新（再帰的に子ノードも更新）
  static void updateNodeColor(Node node) {
    int generation = calculateGeneration(node);
    node.color = _getColorForGeneration(generation);

    // 子ノードの色も更新
    for (Node child in node.children) {
      updateNodeColor(child);
    }
  }

  // 世代数の計算
  static int calculateGeneration(Node node) {
    int generation = 0;
    Node? current = node;
    while (current?.parent != null) {
      generation++;
      current = current?.parent;
    }
    return generation;
  }

  // 世代に基づく色の取得
  static Color _getColorForGeneration(int generation) {
    double hue = (generation * NodeConstants.hueShift) % NodeConstants.maxHue;
    return HSLColor.fromAHSL(
      NodeConstants.alpha,
      hue,
      NodeConstants.saturation,
      NodeConstants.lightness,
    ).toColor();
  }

  // ノード間の距離チェック
  static bool areNodesClose(Node node1, Node node2) {
    double distance = (node1.position - node2.position).length;
    return distance < NodeConstants.nodeSnapDistance;
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
