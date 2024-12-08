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
      _applyAttractionForces(node, ref); // 親子引力の適用
      _applyLinkForces(node);
      _updateNodePosition(node); // ノード位置の更新
    }
  }

  /// 反発力の適用
  static void _applyRepulsionForces(
      Node node, List<Node> nodes, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);

    for (var otherNode in nodes) {
      if (node == otherNode) continue;

      vector_math.Vector2 direction = node.position - otherNode.position;
      double distance = direction.length;

      if (distance < settings.idealNodeDistance) {
        direction.normalize();
        double repulsionStrength = (settings.idealNodeDistance - distance) *
            NodeConstants.repulsionCoefficient;
        node.velocity += direction * repulsionStrength;
      }
    }
  }

  /// リンク関係の引力適用
  static void _applyLinkForces(Node node) {
    for (var target in node.sourceNodes) {
      _applyAttractionForce(
        node,
        target,
        NodeConstants.linkAttractionCoefficient,
        NodeConstants.linkIdealDistance,
      );
    }

    for (var target in node.targetNodes) {
      _applyAttractionForce(
        node,
        target,
        NodeConstants.linkAttractionCoefficient,
        NodeConstants.linkIdealDistance,
      );
    }
  }

  /// 親子関係の引力適用
  static void _applyParentChildForces(Node node) {
    for (var child in node.children) {
      _applyAttractionForce(
        node,
        child,
        NodeConstants.parentChildAttractionCoefficient,
        NodeConstants.parentChildIdealDistance,
      );
    }

    if (node.parent != null) {
      _applyAttractionForce(
        node,
        node.parent!,
        NodeConstants.parentChildAttractionCoefficient,
        NodeConstants.parentChildIdealDistance,
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
          (distance - idealDistance) * attractionCoefficient;
      node.velocity += direction * attractionStrength;
    }
  }

  /// 親子関係の引力適用
  static void _applyAttractionForces(Node node, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);

    if (node.parent != null) {
      _applyAttraction(node, node.parent!, settings.idealNodeDistance);
    }

    for (var child in node.children) {
      _applyAttraction(node, child, settings.idealNodeDistance);
    }
  }

  /// 引力の計算と適用
  static void _applyAttraction(Node node, Node target, double idealDistance) {
    vector_math.Vector2 direction = target.position - node.position;
    double distance = direction.length;

    if (distance > idealDistance) {
      direction.normalize();
      double attractionStrength =
          (distance - idealDistance) * NodeConstants.linkAttractionCoefficient;
      node.velocity += direction * attractionStrength;
    }
  }

  /// ノードの位置を更新
  static void _updateNodePosition(Node node) {
    node.position += node.velocity;
    node.velocity *= NodeConstants.velocityDampingFactor;
  }

  /// 速度の減衰を適用
  static void _applyDamping(Node node) {
    node.velocity *= NodeConstants.velocityDampingFactor;
  }

  /// 反発力を適用
  static void _applyRepulsion(Node node, List<Node> nodes) {
    for (var otherNode in nodes) {
      if (otherNode != node) {
        vector_math.Vector2 direction = node.position - otherNode.position;
        double distance = direction.length;

        if (distance < 0.1) {
          // ノード同士が近すぎる場合は少し間隔を空ける
          direction = direction.normalized() * 0.1;
          node.velocity += direction * NodeConstants.repulsionCoefficient;
        } else if (distance < 50.0) {
          // 距離が近いときに反発力を加える
          direction.normalize();
          double repulsionStrength =
              (1 / distance) * NodeConstants.repulsionCoefficient;
          node.velocity += direction * repulsionStrength;
        }
      }
    }
  }

  static void applyForces(List<Node> nodes, WidgetRef ref) {
    for (var node in nodes) {
      _applyRepulsion(node, nodes); // 反発力
      _applyParentChildForces(node); // 親子関係の引力
      _applyLinkForces(node); // リンク関係の引力
      _applyDamping(node); // 速度の減衰
    }
  }
}
