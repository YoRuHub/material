import 'dart:math';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';

class NodePhysics {
  // メインの物理演算更新
  static void updatePhysics(
      {required List<Node> nodes,
      required Node? draggedNode,
      required bool isPhysicsEnabled}) {
    if (isPhysicsEnabled) return;

    for (var node in nodes) {
      if (node == draggedNode) continue;

      _applyRepulsionForces(node, nodes);
      _applyAttractionForces(node);
      _updateNodePosition(node);
    }
  }

  // 反発力の適用
  static void _applyRepulsionForces(Node node, List<Node> nodes) {
    for (var otherNode in nodes) {
      if (node == otherNode) continue;

      double dx = node.position.x - otherNode.position.x;
      double dy = node.position.y - otherNode.position.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < NodeConstants.minDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        double repulsionMagnitude = (NodeConstants.minDistance - distance) *
            NodeConstants.repulsionStrength;

        node.velocity += direction * repulsionMagnitude;
        otherNode.velocity -= direction * repulsionMagnitude;
      }
    }
  }

  // 引力の適用（親子関係に基づく）
  static void _applyAttractionForces(Node node) {
    if (node.parent != null) {
      double dx = node.position.x - node.parent!.position.x;
      double dy = node.position.y - node.parent!.position.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance > NodeConstants.minDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        vector_math.Vector2 movement = direction *
            (distance - NodeConstants.minDistance) *
            NodeConstants.attractionStrength;
        node.position -= movement;
      }
    }
  }

  // ノード位置の更新
  static void _updateNodePosition(Node node) {
    node.position += node.velocity;
    node.velocity *= NodeConstants.velocityDamping;
  }

  // 接続されたノード間の力の更新
  static void updateConnectedNodes(Node node) {
    Set<Node> connectedNodes = _findConnectedNodes(node);

    for (var connectedNode in connectedNodes) {
      if (connectedNode == node) continue;

      vector_math.Vector2 direction = node.position - connectedNode.position;
      double distance = direction.length;

      if (distance > NodeConstants.initialDistanceThreshold) {
        vector_math.Vector2 targetPosition = node.position -
            direction.normalized() * NodeConstants.idealDistance;

        double strengthMultiplier =
            (distance - NodeConstants.initialDistanceThreshold) /
                NodeConstants.idealDistance;
        strengthMultiplier =
            min(NodeConstants.maxStrengthMultiplier, strengthMultiplier);

        vector_math.Vector2 movement =
            (targetPosition - connectedNode.position) *
                (NodeConstants.attractionStrength * strengthMultiplier);

        connectedNode.velocity += movement;
      }
    }
  }

  // 近接ノードの移動
  static void handleNearbyNodes(Node draggedNode, List<Node> nodes) {
    for (Node node in nodes) {
      if (node == draggedNode) continue;

      double distance = (draggedNode.position - node.position).length;

      if (distance < NodeConstants.nodeInteractionDistance) {
        vector_math.Vector2 direction =
            (draggedNode.position - node.position).normalized();
        vector_math.Vector2 moveAmount =
            direction * NodeConstants.nodeMovementAmount;

        node.position += moveAmount;
      }
    }
  }

  // ノードの物理演算を停止する

  // 接続されたノードの検索
  static Set<Node> _findConnectedNodes(Node startNode) {
    Set<Node> connectedNodes = {};
    Set<Node> visited = {}; // 探索済みノードを追跡
    List<Node> queue = [startNode];

    while (queue.isNotEmpty) {
      Node currentNode = queue.removeAt(0);

      // 既に訪問済みのノードはスキップ
      if (visited.contains(currentNode)) continue;

      visited.add(currentNode);
      connectedNodes.add(currentNode);

      // 関連ノードを収集
      List<Node> relatedNodes = [
        // 子ノード
        ...currentNode.children,

        // 親ノード（存在する場合）
        if (currentNode.parent != null) currentNode.parent!,

        // 兄弟ノード（親が存在する場合）
        if (currentNode.parent != null)
          ...currentNode.parent!.children.where((node) => node != currentNode),
      ];

      // 未訪問の関連ノードをキューに追加
      for (var node in relatedNodes) {
        if (!visited.contains(node)) {
          queue.add(node);
        }
      }
    }

    return connectedNodes;
  }
}
