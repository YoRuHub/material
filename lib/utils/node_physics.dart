import 'dart:math';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// メインの物理演算更新
class NodePhysics {
  /// メインの物理演算更新
  /// [nodes] = ノードリスト
  /// [draggedNode] = ドラッグ中のノード
  /// [isPhysicsEnabled] = 物理演算を有効にするか

  static void updatePhysics({
    required List<Node> nodes,
    required Node? draggedNode,
    required WidgetRef ref,
  }) {
    final isPhysicsEnabled =
        ref.watch(screenProvider.select((state) => state.isPhysicsEnabled));

    if (!isPhysicsEnabled) return;

    // ドラッグ中のノードは物理演算から完全に除外
    if (draggedNode != null) {
      draggedNode.velocity = vector_math.Vector2.zero();
    }

    for (var node in nodes) {
      if (node == draggedNode) continue;

      if (!node.isTemporarilyDetached) {
        _applyRepulsionForces(node, nodes, draggedNode, ref);
        _applyAttractionForces(node, draggedNode, ref);
        _updateNodePosition(node);
      }
    }

    // ドラッグ中のノードに紐づくノードの追従処理
    if (draggedNode != null) {
      // 親ノードへの追従
      if (draggedNode.parent != null) {
        _applyAttractionToParent(draggedNode, ref);
      }

      // 子ノードの追従
      for (var child in draggedNode.children) {
        _applyAttractionToChild(draggedNode, child, ref);
      }

      // 吸着処理
      for (var node in nodes) {
        if (node == draggedNode) continue;
        if (node == draggedNode.parent || draggedNode == node.parent) continue;

        double distance = (draggedNode.position - node.position).length;

        if (distance < NodeConstants.snapEffectRange) {
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

  /// 親ノードへの追従処理
  /// ドラッグ中のノードが親ノードに対して引力を働かせる
  /// ドラッグ中のノードと親ノードの距離が[idealNodeDistance]以上の場合に
  /// ドラッグ中のノードを親ノードに向かって引力をかける
  ///
  /// [draggedNode] ドラッグ中のノード
  static void _applyAttractionToParent(Node draggedNode, ref) {
    final settings = ref.read(settingsNotifierProvider);

    double dx = draggedNode.position.x - draggedNode.parent!.position.x;
    double dy = draggedNode.position.y - draggedNode.parent!.position.y;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance > settings.idealNodeDistance) {
      vector_math.Vector2 direction = vector_math.Vector2(dx, dy).normalized();
      vector_math.Vector2 movement = direction *
          (distance - settings.idealNodeDistance) *
          NodeConstants.attractionCoefficient;
      draggedNode.parent!.position += movement;
    }
  }

  /// 子ノードへの追従処理
  /// ドラッグ中のノードの子ノードに対して引力を働かせる
  /// ドラッグ中のノードと子ノードの距離が[nodePreferredDistance]以上の場合に
  /// ドラッグ中のノードを子ノードに向かって引力をかける
  ///
  /// [draggedNode] ドラッグ中のノード
  /// [child] ドラッグ中のノードの子ノード
  static void _applyAttractionToChild(Node draggedNode, Node child, ref) {
    final settings = ref.read(settingsNotifierProvider);
    double dx = child.position.x - draggedNode.position.x;
    double dy = child.position.y - draggedNode.position.y;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance > settings.idealNodeDistance) {
      vector_math.Vector2 direction = vector_math.Vector2(dx, dy).normalized();
      vector_math.Vector2 movement = direction *
          (distance - settings.idealNodeDistance) *
          NodeConstants.attractionCoefficient;
      child.position -= movement;
    }
  }

  /// 吸着処理
  /// ドラッグ中のノードに向かってノードを移動させる
  /// ノードの位置が[snapTriggerDistance]以上離れている場合のみ
  /// ドラッグ中のノードに向かって移動する
  ///
  /// [node] 移動するノード
  /// [draggedNode] ドラッグ中のノード
  static void _moveTowardsDraggedNode(Node node, Node draggedNode) {
    vector_math.Vector2 direction = draggedNode.position - node.position;
    double distance = direction.length;

    // 最小距離以上の場合のみ移動
    if (distance > NodeConstants.snapTriggerDistance) {
      // 移動方向の正規化
      direction.normalize();

      // 現在位置から目標位置への補間
      vector_math.Vector2 targetPosition =
          draggedNode.position - direction * NodeConstants.snapTriggerDistance;
      vector_math.Vector2 movement = (targetPosition - node.position) *
          NodeConstants.dragVelocityMultiplier;

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

  /// 反発力の計算
  /// ノード同士の反発力を計算し、各ノードの速度を更新する
  /// ドラッグ中のノードは完全にスキップ
  ///
  /// [node] 更新するノード
  /// [nodes] ノードリスト
  /// [draggedNode] ドラッグ中のノード
  static void _applyRepulsionForces(
      Node node, List<Node> nodes, Node? draggedNode, ref) {
    // ドラッグ中のノードは完全にスキップ
    if (node == draggedNode) return;

    final settings = ref.read(settingsNotifierProvider);

    for (var otherNode in nodes) {
      if (node == otherNode || otherNode == draggedNode) continue;

      double dx = node.position.x - otherNode.position.x;
      double dy = node.position.y - otherNode.position.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < settings.idealNodeDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        vector_math.Vector2 repulsion = direction *
            NodeConstants.repulsionCoefficient *
            (settings.idealNodeDistance - distance);
        node.velocity += repulsion;
      }
    }
  }

  /// ドラッグ中のノードを除き、ノード同士の引力を計算し、各ノードの位置を更新する
  ///
  /// [node] 更新するノード
  /// [draggedNode] ドラッグ中のノード
  static void _applyAttractionForces(Node node, Node? draggedNode, ref) {
    // ドラッグ中のノードは完全にスキップ
    if (node == draggedNode) return;

    final settings = ref.read(settingsNotifierProvider);

    // 親ノードとの引力
    if (node.parent != null) {
      // 親がドラッグ中のノードの場合はスキップ
      if (node.parent == draggedNode) return;

      double dx = node.position.x - node.parent!.position.x;
      double dy = node.position.y - node.parent!.position.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance > settings.idealNodeDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        vector_math.Vector2 movement = direction *
            (distance - settings.idealNodeDistance) *
            NodeConstants.attractionCoefficient;
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

      if (distance > settings.idealNodeDistance) {
        vector_math.Vector2 direction =
            vector_math.Vector2(dx, dy).normalized();
        vector_math.Vector2 movement = direction *
            (distance - settings.idealNodeDistance) *
            NodeConstants.attractionCoefficient;

        node.position += movement;
        child.position -= movement;
      }
    }
  }

  /// ノード位置の更新
  /// ドラッグ中のノードはスキップ
  ///
  /// [node] 更新するノード
  static void _updateNodePosition(Node node) {
    // ドラッグ中のノードは位置更新をスキップ
    if (!node.isTemporarilyDetached) {
      node.position += node.velocity;
      node.velocity *= NodeConstants.velocityDampingFactor;
    }
  }

  /// 接続されたノード間の力の更新
  /// 2つのノードが距離的に近づいている場合に
  /// その2つのノードを引き寄せる力の大きさを計算し
  /// その力に応じて velocity を更新する
  ///
  /// [node] 中心となるノード
  static void updateConnectedNodes(Node node, ref) {
    Set<Node> connectedNodes = _findConnectedNodes(node);

    final settings = ref.read(settingsNotifierProvider);
    for (var connectedNode in connectedNodes) {
      if (connectedNode == node) continue;

      vector_math.Vector2 direction = node.position - connectedNode.position;
      double distance = direction.length;

      if (distance > settings.idealNodeDistance) {
        vector_math.Vector2 targetPosition =
            node.position - direction.normalized() * settings.idealNodeDistance;

        double strengthMultiplier = (distance - settings.idealNodeDistance) /
            settings.idealNodeDistance;
        strengthMultiplier =
            min(NodeConstants.maxForceMultiplier, strengthMultiplier);

        vector_math.Vector2 movement =
            (targetPosition - connectedNode.position) *
                (NodeConstants.attractionCoefficient * strengthMultiplier);

        connectedNode.velocity += movement;
      }
    }
  }

  /// 近接ノードの移動
  /// ドラッグ中のノードに近いノードを移動させる
  /// ドラッグ中のノードから一定距離以内にあるノードは
  /// ドラッグ中のノードに追従するように移動する
  ///
  /// [draggedNode] ドラッグ中のノード
  /// [nodes] ノードのリスト
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

  /// 接続されたノードの検索
  /// 指定されたノードから繋がる全てのノードを検索する
  ///
  /// [startNode] 検索を開始するノード
  ///
  /// Returns: 接続されたノードのSet
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
