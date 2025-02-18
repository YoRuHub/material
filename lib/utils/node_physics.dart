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

      _applyRepulsionForces(node, nodes, ref, draggedNode); // 反発力の適用
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
      Node node, List<Node> nodes, WidgetRef ref, Node? draggedNode) {
    vector_math.Vector2 totalForce = vector_math.Vector2.zero();

    for (var otherNode in nodes) {
      // 同じノードや親子関係のノードは除外
      if (node == otherNode || _isParentOrChild(node, otherNode)) continue;
      // ドラッグ中のノードは除外
      if (_isDraggedSnapEligible(node, otherNode, draggedNode)) continue;

      vector_math.Vector2 direction = node.position - otherNode.position;
      double distance = direction.length;

      // 異なるグループ間の最小距離を設定
      double minGroupDistance = NodeConstants.minGroupDistance;

      if (distance < minGroupDistance) {
        direction.normalize();

        // グループ間距離が近すぎる場合の反発力を計算
        double repulsionStrength =
            (minGroupDistance - distance) * NodeConstants.repulsionCoefficient;

        totalForce += direction * repulsionStrength;
      }
    }

    node.velocity += totalForce;
  }

  static void _applyParentChildForces(Node node, WidgetRef ref,
      {int depth = 1}) {
    final settings = ref.read(settingsNotifierProvider);

    // 親ノードが存在する場合
    if (node.parent != null) {
      Node parent = node.parent!;
      List<Node> siblings = parent.children;
      int siblingCount = siblings.length;
      int siblingIndex = siblings.indexOf(node);

      // 親からの基本距離を階層（depth）に応じて加算
      double baseDistance =
          settings.parentChildDistance * (1 + 0.5 * node.children.length);
      double idealDistance = baseDistance; // 階層が深いほど距離を増やす

      // 兄弟ノードの角度配置
      double angleStep = (2 * pi) / (siblingCount == 0 ? 1 : siblingCount);
      double nodeAngle = angleStep * siblingIndex;

      // ターゲット位置を計算（理想的な配置）
      vector_math.Vector2 targetPosition = vector_math.Vector2(
        parent.position.x + idealDistance * cos(nodeAngle),
        parent.position.y + idealDistance * sin(nodeAngle),
      );

      // 引力ベクトルを計算して適用
      vector_math.Vector2 attractionForce = targetPosition - node.position;
      double attractionStrength =
          settings.parentChildAttraction * NodeConstants.attractionCoefficient;
      node.velocity += attractionForce * attractionStrength;

      // 最大速度のクリッピングを追加
      const double maxVelocity = NodeConstants.maxVelocity; // 最大速度を設定
      if (node.velocity.length > maxVelocity) {
        node.velocity.normalize();
        node.velocity *= maxVelocity;
      }

      // 親ノードが適正距離に引っ張られるようにする
      // 親ノードと子ノードの間の理想的な距離を計算
      vector_math.Vector2 parentToChildDirection =
          node.position - parent.position;
      double distance = parentToChildDirection.length;
      double idealParentDistance =
          settings.parentChildDistance * (1 + node.children.length * 0.5);

      // 親ノードが適正距離よりも遠い場合、引力をかけて近づける
      if (distance > idealParentDistance) {
        parentToChildDirection.normalize();
        double pullStrength = (distance - idealParentDistance) *
            settings.parentChildAttraction *
            NodeConstants.attractionCoefficient;
        vector_math.Vector2 pullForce = parentToChildDirection * pullStrength;

        // 親ノードに引力を適用
        parent.velocity += pullForce;

        // 親ノードの速度制限
        if (parent.velocity.length > maxVelocity) {
          parent.velocity.normalize();
          parent.velocity *= maxVelocity;
        }
      }

      // 子ノード（孫ノード以降）にも再帰的に適用
      for (var child in node.children) {
        _applyParentChildForces(child, ref, depth: depth + 1);
      }
    }
  }

  static void _applyParentPullForce(Node node, WidgetRef ref) {
    final settings = ref.read(settingsNotifierProvider);

    Node? currentNode = node.parent;
    int depth = 0; // 祖先ノードの深さを追跡

    // 孫ノードがドラッグ中の場合、その親ノードのみを引っ張るように変更
    while (currentNode != null) {
      // 孫ノードがドラッグ中の場合、親ノードのみ引っ張る
      if (node.children.isEmpty) {
        // 子ノードがない場合（孫ノード）
        if (currentNode != node.parent) {
          currentNode = currentNode.parent; // 親ノードだけを引っ張る
          continue;
        }
      }

      vector_math.Vector2 direction = node.position - currentNode.position;
      double distance = direction.length;

      // ドラッグ中のノードの子の数を考慮した適正距離を計算
      double idealDistance =
          settings.parentChildDistance * (1 + node.children.length * 0.5);

      // 引っ張る力の強さを設定（深さが増えるごとに緩やかに減少）
      double pullStrengthCoefficient =
          1.0 / (1 + depth * 0.5); // 深さが増えるごとに緩やかに減少

      if (distance > idealDistance) {
        direction.normalize();

        // 引っ張る力を計算
        double pullStrength = (distance - idealDistance) *
            settings.parentChildAttraction *
            NodeConstants.attractionCoefficient *
            pullStrengthCoefficient; // 深さによって強さを調整

        // 速度にクリッピング処理を追加
        const double maxVelocity = 10.0; // 最大速度を設定
        vector_math.Vector2 pullForce = direction * pullStrength;

        currentNode.velocity += pullForce;
        if (currentNode.velocity.length > maxVelocity) {
          currentNode.velocity.normalize();
          currentNode.velocity *= maxVelocity;
        }
      } else {
        // 適正距離に到達したら速度をゼロにする
        currentNode.velocity = vector_math.Vector2.zero();
      }

      // 次の祖先ノードに進む
      currentNode = currentNode.parent;
      depth++; // 深さを増やす
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
  static bool _isDraggedSnapEligible(
      Node nodeA, Node nodeB, Node? draggedNode) {
    //どちらかがドラック中のノードかをチェック
    if (nodeA == draggedNode || nodeB == draggedNode) return true;
    return false;
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
    const double dampingFactor = 0.6; // 減衰係数を強める
    const double minVelocityThreshold = 0.05; // 停止の閾値

    // 速度が十分に小さい場合、動きを停止
    if (node.velocity.length < minVelocityThreshold) {
      node.velocity = vector_math.Vector2.zero();
    } else {
      node.velocity *= dampingFactor; // 減衰効果を適用
      node.position += node.velocity;
    }
  }
}
