import 'dart:math';

import 'package:flutter_app/providers/settings_provider.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings.dart';
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

  /// 親との距離を調整し、孫ノードが親と子の延長線上に扇型に分散するように調整する
  static void _applyParentChildForces(Node node, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);
    if (node.parent != null) {
      vector_math.Vector2 direction = node.position - node.parent!.position;
      double idealDistance = node.children.isNotEmpty
          ? settings.parentChildDistance * 3 // 子を持つノードは距離を10倍
          : settings.parentChildDistance; // 子を持たない場合は通常の距離

      // 親と子の延長線上の位置を計算
      direction.normalize();
      vector_math.Vector2 targetPosition =
          node.parent!.position + direction * idealDistance;

      // 相当の効果を調整
      vector_math.Vector2 attractionForce = targetPosition - node.position;
      double attractionStrength = NodeConstants.parentChildAttraction * 0.0001;
      node.velocity += attractionForce * attractionStrength;
    }

    // 孫ノードに扇型分布を促す力を加える
    if (node.children.isNotEmpty) {
      _applyFanShapeForceToGrandchildren(node, settings);
    }
  }

  /// 孫ノードが扇型に分散するように力を加える
  static void _applyFanShapeForceToGrandchildren(
      Node parentNode, Settings settings) {
    final numGrandchildren = parentNode.children.length;
    final angleStep = 180 / (numGrandchildren + 1); // 扇型の角度を均等に分ける

    // 親ノードと子ノードの延長線上に孫ノードを配置
    for (int i = 0; i < numGrandchildren; i++) {
      final child = parentNode.children[i];

      // 親と子の位置を基に延長線の方向を決定
      final parentToChildDirection =
          (child.position - parentNode.position).normalized();

      // 延長線上に孫ノードを配置
      final desiredDirection = parentToChildDirection;

      // 延長線上で孫ノードがどれだけ遠くにいるか決定（距離は設定可能）
      final extensionDistance = settings.parentChildDistance * 2; // 延長線上に配置する距離
      final extendedPosition =
          parentNode.position + desiredDirection * extensionDistance;

      // 孫ノードに扇型の角度を加える
      final angle = (i + 1) * angleStep; // 角度を計算
      final radians = vector_math.radians(angle);
      final fanOffset = vector_math.Vector2(cos(radians), sin(radians)) *
          settings.parentChildDistance *
          0.5;

      // 孫ノードの最終的な位置
      final targetPosition = extendedPosition + fanOffset;

      // 孫ノードが扇型に広がる力を加える
      vector_math.Vector2 direction = targetPosition - child.position;
      double distance = direction.length;
      double forceStrength = distance * 0.0001; // 力の強さを調整
      child.velocity += direction * forceStrength;

      // 適切な距離を保つために、力を調整
      vector_math.Vector2 distanceToTarget = targetPosition - child.position;
      child.velocity += distanceToTarget * 0.00005; // 距離補正用の力
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
