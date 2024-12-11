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
      _applyParentChildForces(node, ref); // 親子引力の適用
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

    // If total force is extremely small, consider the node stationary
    if (totalForce.length < NodeConstants.forceThreshold) {
      node.velocity = vector_math.Vector2.zero();
    } else {
      node.velocity += totalForce;
    }
  }

  /// ノードのスナップ処理（ドラッグ中のノードが近くのノードに吸着する）
  static void _applySnapForce(Node draggedNode, List<Node> nodes) {
    for (var node in nodes) {
      if (draggedNode == node) continue;

      vector_math.Vector2 direction = draggedNode.position - node.position;
      double distance = direction.length;

      if (distance < NodeConstants.snapEffectRange) {
        direction.normalize();
        // スナップ距離内に近づいた場合、ドラッグ中のノードをターゲットノードの位置にスナップ
        draggedNode.position = node.position;
        draggedNode.velocity = vector_math.Vector2.zero(); // スナップ後は速度をリセット
        break; // 最初のノードにスナップしたら、これ以上の処理を停止
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

  /// 親子関係の引力適用
  static void _applyParentChildForces(Node node, ref) {
    final settings = ref.read(settingsNotifierProvider);
    for (var child in node.children) {
      _applyAttractionForce(
        node,
        child,
        settings.parentChildAttraction,
        settings.parentChildDistance,
      );
    }

    if (node.parent != null) {
      _applyAttractionForce(
        node,
        node.parent!,
        settings.parentChildAttraction,
        settings.parentChildDistance,
      );
    }
  }

  /// 引力の計算と適用
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
    vector_math.Vector2 oldPosition = node.position;
    node.position += node.velocity;

    // If position change is microscopic, stop the node
    if ((node.position - oldPosition).length < NodeConstants.forceThreshold) {
      node.velocity = vector_math.Vector2.zero();
    }

    node.velocity *= NodeConstants.velocityDampingFactor;
  }
}
