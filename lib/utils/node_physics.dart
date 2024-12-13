import 'dart:math';

import 'package:flutter_app/providers/settings_provider.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/screen_provider.dart';

/// ノード物理演算クラス
class NodePhysics {
  /// 物理演算のメイン処理
  static void updatePhysics({
    required List<Node> nodes,
    required Node? draggedNode,
    required WidgetRef ref,
  }) {
    final isPhysicsEnabled =
        ref.watch(screenProvider.select((state) => state.isPhysicsEnabled));

    if (!isPhysicsEnabled) return;

    // ドラッグ中のノードはスキップ
    if (draggedNode != null) {
      draggedNode.velocity = vector_math.Vector2.zero();
    }

    for (var node in nodes) {
      if (node == draggedNode) continue;

      _applyRepulsionForces(node, nodes, ref); // 反発力の適用
      _applyParentChildForces(node, ref); // 親子の距離調整
      _applyLinkForces(node, ref); // リンク引力の適用
      _updateNodePosition(node); // ノード位置の更新
    }

    // ドラッグ中のノードのスナップ処理
    if (draggedNode != null) {
      _applySnapForce(draggedNode, nodes); // ドラッグ中のノードのスナップ
    }
  }

  /// 反発力の適用
  static void _applyRepulsionForces(
      Node node, List<Node> nodes, WidgetRef ref) {
    vector_math.Vector2 totalForce = vector_math.Vector2.zero();
    final settings = ref.read(settingsNotifierProvider);
    for (var otherNode in nodes) {
      if (node == otherNode) continue;

      vector_math.Vector2 direction = node.position - otherNode.position;
      double distance = direction.length;

      if (distance < settings.parentChildDistance) {
        direction.normalize();
        double repulsionStrength = (settings.parentChildDistance - distance) *
            NodeConstants.repulsionCoefficient;
        totalForce += direction * repulsionStrength;
      }
    }
    node.velocity += totalForce;
  }

  /// 親との距離を調整し、兄弟ノードを角度に基づいて展開する
  static void _applyParentChildForces(Node node, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);
    if (node.parent != null) {
      // 同じ親を持つ兄弟ノードを取得
      List<Node> siblings = node.parent!.children;
      int siblingCount = siblings.length;
      int siblingIndex = siblings.indexOf(node);

      // 子の数に応じて距離を調整（最低距離を確保する）
      double idealDistance = settings.parentChildDistance *
          (1 + node.children.length * 0.3); // 子の数だけ距離を増加

      // 子ノードを円状に均等に配置する角度計算
      double angleStep = 2 * pi / siblingCount; // 全円を均等に分割
      double nodeAngle = angleStep * siblingIndex;

      // 極座標から直交座標に変換
      vector_math.Vector2 targetPosition = vector_math.Vector2(
          node.parent!.position.x + idealDistance * cos(nodeAngle),
          node.parent!.position.y + idealDistance * sin(nodeAngle));

      // 現在位置と理想位置の間の引力ベクトルを計算
      vector_math.Vector2 attractionForce = targetPosition - node.position;

      // 引力の強さを調整
      double attractionStrength = NodeConstants.parentChildAttraction * 0.0001;
      node.velocity += attractionForce * attractionStrength;
    }
  }

  /// ノードのスナップ処理
  static void _applySnapForce(Node draggedNode, List<Node> nodes) {
    for (var node in nodes) {
      if (draggedNode == node) continue;

      vector_math.Vector2 direction = draggedNode.position - node.position;
      double distance = direction.length;

      if (distance < NodeConstants.snapEffectRange) {
        direction.normalize();
        draggedNode.position = node.position;
        draggedNode.velocity = vector_math.Vector2.zero();
        break;
      }
    }
  }

  /// リンク関係の引力適用
  static void _applyLinkForces(Node node, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);
    for (var target in node.sourceNodes) {
      _applyAttractionForce(
        node,
        target,
        settings.linkAttraction,
        settings.linkDistance,
      );
    }

    for (var target in node.targetNodes) {
      _applyAttractionForce(
        node,
        target,
        settings.linkAttraction,
        settings.linkDistance,
      );
    }
  }

  /// 引力の適用
  static void _applyAttractionForce(Node node, Node target,
      double attractionCoefficient, double idealDistance) {
    vector_math.Vector2 direction = target.position - node.position;
    double distance = direction.length;

    if (distance > idealDistance) {
      direction.normalize();
      double attractionStrength =
          (distance - idealDistance) * attractionCoefficient * 0.0001;
      node.velocity += direction * attractionStrength;
    }
  }

  /// ノードの位置を更新
  static void _updateNodePosition(Node node) {
    if (node.velocity.length > NodeConstants.velocityDampingFactor) {
      node.position += node.velocity;
    }

    node.velocity = vector_math.Vector2.zero();
  }
}
