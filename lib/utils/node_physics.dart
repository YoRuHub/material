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

    // ドラッグ中のノードにも親ノード引っ張り力を適用
    if (draggedNode != null) {
      _applyParentPullForce(draggedNode, ref); // ドラッグ中の親ノード引っ張り
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

      // ドラッグ中のノードでスナップ可能な場合は反発しない
      if (_isSnapEligible(node, otherNode)) continue;

      vector_math.Vector2 direction = node.position - otherNode.position;
      double distance = direction.length;

      // 反発力の適用
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
      List<Node> siblings = node.parent!.children;
      int siblingCount = siblings.length;
      int siblingIndex = siblings.indexOf(node);

      // 祖父母ノードがある場合は対角線上に配置
      if (node.parent!.parent != null) {
        Node grandparent = node.parent!.parent!;

        // 祖父母と親のベクトルを計算
        vector_math.Vector2 grandparentToParentVector =
            node.parent!.position - grandparent.position;

        // 理想的な距離を計算（親子間距離の1.5倍）
        double idealDistance = settings.parentChildDistance * 1.5;

        // 角度にランダム性を加える
        double angleVariation =
            (siblingIndex - (siblingCount - 1) / 2) * (pi / 6);

        // 回転行列を使用してベクトルを回転
        vector_math.Vector2 rotatedVector = vector_math.Vector2(
            grandparentToParentVector.x * cos(angleVariation) -
                grandparentToParentVector.y * sin(angleVariation),
            grandparentToParentVector.x * sin(angleVariation) +
                grandparentToParentVector.y * cos(angleVariation));

        // 対角線上のターゲット位置を計算
        vector_math.Vector2 targetPosition =
            node.parent!.position + rotatedVector.normalized() * idealDistance;

        // 引力ベクトルを計算
        vector_math.Vector2 attractionForce = targetPosition - node.position;

        // 引力の強さを調整
        double attractionStrength = settings.parentChildAttraction *
            NodeConstants.attractionCoefficient;
        node.velocity += attractionForce * attractionStrength;
      }
      // 既存の兄弟ノード配置ロジックは維持
      else {
        // 既存のコード（円状配置）をそのまま維持
        double angleStep = pi / siblingCount;
        double nodeAngle = angleStep * siblingIndex;

        double idealDistance =
            settings.parentChildDistance * (1 + node.children.length * 0.5);

        vector_math.Vector2 targetPosition = vector_math.Vector2(
            node.parent!.position.x + idealDistance * cos(nodeAngle),
            node.parent!.position.y + idealDistance * sin(nodeAngle));

        vector_math.Vector2 attractionForce = targetPosition - node.position;

        double attractionStrength = settings.parentChildAttraction *
            NodeConstants.attractionCoefficient;
        node.velocity += attractionForce * attractionStrength;
      }
    }
  }

  /// 親ノードとその祖先ノードを引っ張る力を適用
  static void _applyParentPullForce(Node node, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);

    Node? currentNode = node.parent;

    while (currentNode != null) {
      vector_math.Vector2 direction = node.position - currentNode.position;
      double distance = direction.length;

      // 親ノードとの引力の強さを調整
      if (distance > settings.parentChildDistance) {
        direction.normalize();
        double pullStrength = (distance - settings.parentChildDistance) *
            settings.parentChildAttraction *
            NodeConstants.attractionCoefficient;

        currentNode.velocity += direction * pullStrength;
      }

      // 次の祖先ノードに進む
      currentNode = currentNode.parent;
    }
  }

  /// ノードのスナップ処理
  static void _applySnapForce(Node draggedNode, List<Node> nodes) {
    for (var node in nodes) {
      if (draggedNode == node) continue;

      // 親・子関係にある場合はスキップ
      if (_isParentOrChild(draggedNode, node)) continue;

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

  /// スナップ可能なノードかを判定
  static bool _isSnapEligible(Node nodeA, Node nodeB) {
    // 親や子ノードならスナップ不可 → false
    if (_isParentOrChild(nodeA, nodeB)) {
      return false;
    }
    return true; // それ以外のノードはスナップ可能
  }

  /// 親または子の関係かを判定
  static bool _isParentOrChild(Node nodeA, Node nodeB) {
    if (nodeA.parent == nodeB || nodeB.parent == nodeA) {
      return true;
    }
    return false;
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
      double attractionStrength = (distance - idealDistance) *
          attractionCoefficient *
          NodeConstants.attractionCoefficient;
      node.velocity += direction * attractionStrength;
    }
  }

  /// ノードの位置を更新/// ノードの位置を更新
  static void _updateNodePosition(Node node) {
    const double dampingFactor = 0.8; // 減衰を少し強める

    // 速度が十分に小さい場合、動きを停止
    if (node.velocity.length < 0.01) {
      node.velocity = vector_math.Vector2.zero();
    } else {
      node.velocity *= dampingFactor; // 減衰効果を適用
      node.position += node.velocity;
    }
  }
}
