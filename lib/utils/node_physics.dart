import 'dart:math';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';

// メインの物理演算更新
class NodePhysics {
  // メインの物理演算更新
  // メインの物理演算更新
  static void updatePhysics({
    required List<Node> nodes,
    required Node? draggedNode,
    required bool isPhysicsEnabled,
    required bool isDragging,
  }) {
    if (!isPhysicsEnabled) return;

    // ドラッグ中のノードは物理演算から完全に除外
    if (draggedNode != null) {
      draggedNode.velocity = vector_math.Vector2.zero();
    }

    for (var node in nodes) {
      if (node == draggedNode) continue;

      if (!node.isTemporarilyDetached) {
        _applyRepulsionForces(node, nodes, draggedNode);
        _applyAttractionForces(node, draggedNode);
        _updateNodePosition(node);
      }
    }

    // ドラッグ中のノードに紐づくノードの追従処理
    if (draggedNode != null && isDragging) {
      // 親ノードへの追従
      if (draggedNode.parent != null) {
        _applyAttractionToParent(draggedNode);
      }

      // 子ノードの追従
      for (var child in draggedNode.children) {
        _applyAttractionToChild(draggedNode, child);
      }

      // 吸着処理
      for (var node in nodes) {
        if (node == draggedNode) continue;
        if (node == draggedNode.parent || draggedNode == node.parent) continue;

        double distance = (draggedNode.position - node.position).length;

        if (distance < NodeConstants.snapDistance) {
          node.isTemporarilyDetached = true;
          _moveTowardsDraggedNode(node, draggedNode);
        } else {
          if (node.isTemporarilyDetached) {
            node.isTemporarilyDetached = false;
          }
        }
      }
    }
  }

  // 親ノードへの追従処理
  static void _applyAttractionToParent(Node draggedNode) {
    double dx = draggedNode.position.x - draggedNode.parent!.position.x;
    double dy = draggedNode.position.y - draggedNode.parent!.position.y;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance > NodeConstants.minDistance) {
      vector_math.Vector2 direction = vector_math.Vector2(dx, dy).normalized();
      vector_math.Vector2 movement = direction *
          (distance - NodeConstants.minDistance) *
          NodeConstants.attractionStrength;
      draggedNode.parent!.position += movement;
    }
  }

// 子ノードの追従処理
  static void _applyAttractionToChild(Node draggedNode, Node child) {
    double dx = child.position.x - draggedNode.position.x;
    double dy = child.position.y - draggedNode.position.y;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance > NodeConstants.minDistance) {
      vector_math.Vector2 direction = vector_math.Vector2(dx, dy).normalized();
      vector_math.Vector2 movement = direction *
          (distance - NodeConstants.minDistance) *
          NodeConstants.attractionStrength;
      child.position -= movement;
    }
  }

  static void _moveTowardsDraggedNode(Node node, Node draggedNode) {
    vector_math.Vector2 direction = draggedNode.position - node.position;
    double distance = direction.length;

    // 最小距離以上の場合のみ移動
    if (distance > NodeConstants.minApproachDistance) {
      // 移動方向の正規化
      direction.normalize();

      // 現在位置から目標位置への補間
      vector_math.Vector2 targetPosition =
          draggedNode.position - direction * NodeConstants.minApproachDistance;
      vector_math.Vector2 movement =
          (targetPosition - node.position) * NodeConstants.dragSpeed;

      // 急激な動きを防ぐために移動量を制限
      double maxMovement = 5.0;
      if (movement.length > maxMovement) {
        movement.normalize();
        movement *= maxMovement;
      }

      // 位置の更新
      node.position += movement;

      // 既存の速度をリセット（滑らかな動きのため）
      node.velocity = vector_math.Vector2.zero();
    }
  }

  // 反発力の計算メソッドも修正
  static void _applyRepulsionForces(
      Node node, List<Node> nodes, Node? draggedNode) {
    // ドラッグ中のノードは完全にスキップ
    if (node == draggedNode) return;

    for (var otherNode in nodes) {
      if (node == otherNode || otherNode == draggedNode) continue;

      double dx = node.position.x - otherNode.position.x;
      double dy = node.position.y - otherNode.position.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < NodeConstants.minDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        vector_math.Vector2 repulsion = direction *
            NodeConstants.repulsionStrength *
            (NodeConstants.minDistance - distance);
        node.velocity += repulsion;
      }
    }
  }

  // 引力の適用（親子関係に基づく）
  static void _applyAttractionForces(Node node, Node? draggedNode) {
    // ドラッグ中のノードは完全にスキップ
    if (node == draggedNode) return;

    // 親ノードとの引力
    if (node.parent != null) {
      // 親がドラッグ中のノードの場合はスキップ
      if (node.parent == draggedNode) return;

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

    // 子ノードとの引力
    for (var child in node.children) {
      // 子がドラッグ中のノードの場合はスキップ
      if (child == draggedNode) continue;

      double dx = child.position.x - node.position.x;
      double dy = child.position.y - node.position.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance > NodeConstants.minDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        vector_math.Vector2 movement = direction *
            (distance - NodeConstants.minDistance) *
            NodeConstants.attractionStrength;

        node.position += movement;
        child.position -= movement;
      }
    }
  }

// ノード位置の更新
  static void _updateNodePosition(Node node) {
    // ドラッグ中のノードは位置更新をスキップ
    if (!node.isTemporarilyDetached) {
      node.position += node.velocity;
      node.velocity *= NodeConstants.velocityDamping;
    }
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
