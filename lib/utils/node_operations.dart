import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_link_map_model.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../models/node.dart';
import '../constants/node_constants.dart';
import 'logger.dart';

class NodeOperations {
  /// ノードの追加
  static Future<Node> addNode({
    required WidgetRef ref,
    int nodeId = 0,
    String title = '',
    String contents = '',
    Color? color,
    String createdAt = '',
    Node? parentNode,
  }) async {
    final projectId = ref.read(screenProvider).projectNode?.id ?? 0;
    final NodesNotifier nodesNotifier =
        ref.read<NodesNotifier>(nodesProvider.notifier);
    final NodeModel nodeModel = NodeModel();
    // ノードの配置位置を取得
    vector_math.Vector2 basePosition = _calculateBasePosition(
      ref,
    );

    // ノードのカラーを取得
    if (color == null) {
      color = NodeColorUtils.getColorForCurrentGeneration(null);
      if (parentNode != null) {
        color = NodeColorUtils.getColorForNextGeneration(parentNode);
      }
    }

    final newNodeData =
        await nodeModel.upsertNode(nodeId, title, contents, color, projectId);
    final newNodeId = newNodeData['id'] as int;
    final newNodeTitle = newNodeData['title'] as String;
    final newNodeContents = newNodeData['contents'] as String;
    final newNodeColor = newNodeData['color'] as int?;
    final newNodeCreatedAt = newNodeData['created_at'] as String;

    // ノード要素を作成
    final newNode = Node(
        position: basePosition,
        velocity: vector_math.Vector2(0, 0),
        radius: NodeConstants.defaultNodeRadius,
        parent: parentNode,
        id: newNodeId,
        title: newNodeTitle,
        contents: newNodeContents,
        color: newNodeColor != null ? Color(newNodeColor) : null,
        projectId: projectId,
        createdAt: newNodeCreatedAt);

    if (parentNode != null) {
      await linkChildNode(ref, parentNode.id, newNode);
    }

    nodesNotifier.addNode(newNode);

    return newNode;
  }

  /// ノードの紐付け
  static Future<void> linkChildNode(
      WidgetRef ref, int parentNodeId, Node childNode) async {
    final projectId = ref.read(screenProvider).projectNode?.id ?? 0;
    ref
        .read(nodesProvider.notifier)
        .linkChildNodeToParent(parentNodeId, childNode, projectId);
    final nodeMapModel = NodeMapModel();
    await nodeMapModel.insertNodeMap(parentNodeId, childNode.id, projectId);
  }

  /// ノードのコピー
  static Future<Node> duplicateNode(
      {required BuildContext context,
      required Node targetNode,
      required WidgetRef ref,
      Node? newParent}) async {
    final newNode = await NodeOperations.addNode(
      ref: ref,
      nodeId: 0,
      title: targetNode.title,
      contents: targetNode.contents,
      color: targetNode.color,
      parentNode: newParent,
    );
    // 子ノードを再帰的にコピー
    for (var child in targetNode.children) {
      if (context.mounted) {
        await duplicateNode(
          context: context,
          targetNode: child,
          ref: ref,
          newParent: newNode,
        );
      }
    }

    return newNode;
  }

  /// ノードの削除
  static Future<void> deleteNode(
      {required int targetNodeId,
      required WidgetRef ref,
      required int projectId}) async {
    final nodeModel = NodeModel();
    final nodeMapModel = NodeMapModel();
    final NodeLinkMapModel nodeLinkMapModel = NodeLinkMapModel();
    final NodesNotifier nodesNotifier =
        ref.read<NodesNotifier>(nodesProvider.notifier);

    // 削除対象のIDをprojectIdとしているノードを取得
    final targetNodes = await nodeModel.fetchProjectNodes(targetNodeId);
    for (final node in targetNodes) {
      deleteNode(targetNodeId: node['id'], ref: ref, projectId: targetNodeId);
    }

    //providerにあれば削除
    final targetNode = nodesNotifier.findNodeById(targetNodeId);
    if (targetNode != null) {
      // 子ノードを逆順に削除
      for (var i = targetNode.children.length - 1; i >= 0; i--) {
        await deleteNode(
            targetNodeId: targetNode.children[i].id,
            ref: ref,
            projectId: projectId);
      }
      // 親ノードから削除
      final parentNode = targetNode.parent;
      if (parentNode != null) {
        await nodesNotifier.removeChildFromNode(parentNode.id, targetNode);
        nodeMapModel.deleteParentNodeMap(parentNode.id);
        nodeLinkMapModel.deleteSourceNodeMap(parentNode.id);
      }
      nodesNotifier.removeNode(targetNode);
      nodesNotifier.removeSourceNodeReferences(targetNode.id);
    }

    await nodeModel.deleteNode(targetNodeId, projectId);
    await nodeMapModel.deleteParentNodeMap(targetNodeId);
    await nodeLinkMapModel.deleteSourceNodeMap(targetNodeId);
    await nodeLinkMapModel.deleteTargetNodeMap(targetNodeId);
  }

  /// 子ノードを切り離す
  static Future<void> detachChildren(Node node, WidgetRef ref) async {
    final NodesNotifier nodesNotifier =
        ref.read<NodesNotifier>(nodesProvider.notifier);

    final nodeMapModel = NodeMapModel();
    // 削除する子ノードを保持するリストを作成
    List<Node> childrenToRemove = [];

    for (var child in node.children) {
      // ノードを弾く
      double angle = Random().nextDouble() * 2 * pi;
      child.velocity = vector_math.Vector2(
        cos(angle) * NodeConstants.touchSpeedMultiplier,
        sin(angle) * NodeConstants.touchSpeedMultiplier,
      );

      // 削除する子ノードをリストに追加
      childrenToRemove.add(child);
    }

    // ノードプロバイダーで子ノードの親を削除
    for (var child in childrenToRemove) {
      await nodesNotifier.removeChildFromNode(node.id, child);
      await nodeMapModel.deleteChildNodeMap(child.id);
    }
  }

  /// 親ノードを切り離す
  static Future<void> detachParent(
    Node targetNode,
    WidgetRef ref,
  ) async {
    if (targetNode.parent != null) {
      final nodeMapModel = NodeMapModel();
      final parentNode = targetNode.parent!;

      await ref
          .read(nodesProvider.notifier)
          .removeParentFromNode(targetNode.id);

      nodeMapModel.deleteChildNodeMap(targetNode.id);
      double angle = Random().nextDouble() * 2 * pi;
      vector_math.Vector2 velocity = vector_math.Vector2(
        cos(angle) * NodeConstants.touchSpeedMultiplier,
        sin(angle) * NodeConstants.touchSpeedMultiplier,
      );

      targetNode.velocity = velocity;
      parentNode.velocity = -velocity;
    }
  }

  /// ノード間の距離チェック
  static bool areNodesClose(Node node1, Node node2) {
    double distance = (node1.position - node2.position).length;
    return distance < NodeConstants.snapEffectRange;
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

  /// Calculate the base position for the new node
  static vector_math.Vector2 _calculateBasePosition(
    WidgetRef ref,
  ) {
    vector_math.Vector2 basePosition;

    final centerPosition = ref.read(screenProvider).centerPosition;

    // 中央座標をワールド座標に変換
    basePosition = CoordinateUtils.screenToWorld(
      centerPosition, // 画面中央
      ref.read(screenProvider).offset,
      ref.read(screenProvider).scale,
    );

    // ノードの重なりチェックと調整
    basePosition = _adjustPositionSlightly(basePosition);

    return basePosition;
  }

  /// ノードの位置が重ならないように調整
  static vector_math.Vector2 _adjustPositionSlightly(
      vector_math.Vector2 basePosition) {
    const double adjustmentFactor = 0.5; // ずらす範囲の調整係数

    // ランダムに少しだけずらす
    return basePosition +
        vector_math.Vector2(
          (Random().nextDouble() * 2 - 1) * adjustmentFactor,
          (Random().nextDouble() * 2 - 1) * adjustmentFactor,
        );
  }

  // 新しく作成するリンク処理関数
  static Future<void> linkNode({
    required WidgetRef ref,
    required Node activeNode,
    required Node hoveredNode,
  }) async {
    final NodeLinkMapModel nodeLinkMapModel = NodeLinkMapModel();
    final projectId = ref.read(screenProvider).projectNode?.id ?? 0;
    bool isAlreadyLinked = activeNode.targetNodes.contains(hoveredNode) ||
        hoveredNode.targetNodes.contains(activeNode);

    if (isAlreadyLinked) {
      // 既存のリンク解除
      Logger.debug('Unlinking nodes ${activeNode.id} and ${hoveredNode.id}');
      ref
          .read(nodesProvider.notifier)
          .unlinkTargetNodeFromSource(activeNode.id, hoveredNode.id);
      ref
          .read(nodesProvider.notifier)
          .unlinkTargetNodeFromSource(hoveredNode.id, activeNode.id);

      nodeLinkMapModel.deleteNodeMap(activeNode.id, hoveredNode.id, projectId);
      nodeLinkMapModel.deleteNodeMap(hoveredNode.id, activeNode.id, projectId);
    } else {
      // リンク前のチェック
      if (canLinkNodes(activeNode, hoveredNode)) {
        Logger.debug(
            'Linking source ${activeNode.id} to target ${hoveredNode.id}');
        ref
            .read(nodesProvider.notifier)
            .linkTargetNodeToSource(activeNode.id, hoveredNode);
        nodeLinkMapModel.insertNodeMap(
            activeNode.id, hoveredNode.id, projectId);
      } else {
        Logger.debug('Cannot link directly related nodes');
      }
    }
  }

  static bool canLinkNodes(Node sourceNode, Node targetNode) {
    // ノードが同じかどうかを確認
    if (sourceNode == targetNode) return false;

    // 同じ親ノードを持つ子ノード（兄弟ノード）かどうかを確認
    if (sourceNode.parent == targetNode.parent && sourceNode.parent != null) {
      return true;
    }

    // 直系の親子関係かどうかを確認
    if (sourceNode.parent == targetNode || targetNode.parent == sourceNode) {
      return false;
    }

    // 直接的な子ノード関係かどうかを確認
    if (sourceNode.children.contains(targetNode) ||
        targetNode.children.contains(sourceNode)) {
      return false;
    }

    // ソースノードとターゲットノードのすべての祖先を取得
    Set<Node> sourceAncestors = getAllAncestors(sourceNode);
    Set<Node> targetAncestors = getAllAncestors(targetNode);

    // Rootと孫ノードの接続を許可
    // 条件：一方のノードが他方のノードの祖先で、直接的な親子関係でないこと
    if (sourceAncestors.contains(targetNode) ||
        targetAncestors.contains(sourceNode)) {
      return true;
    }

    // 同じ祖父母を持つ後代（従兄弟/堂兄弟）かどうかを確認
    Set<Node> commonAncestors = sourceAncestors.intersection(targetAncestors);

    // 同じ祖父母を持つ後代ノードの接続を許可
    if (commonAncestors.isNotEmpty) {
      return true;
    }

    return true;
  }

  static Set<Node> getAllAncestors(Node node) {
    // Create an empty set to store ancestors
    Set<Node> ancestors = {};

    // Start with the node's parent
    Node? current = node.parent;

    // Continue climbing up the tree until there are no more parents
    while (current != null) {
      // Add the current parent to the ancestors set
      ancestors.add(current);

      // Move to the parent of the current node
      current = current.parent;
    }

    // Return the complete set of ancestors
    return ancestors;
  }

  // transformPoint関数の修正（非同期を同期に変更）
  static Offset transformPoint(double x, double y,
      {required double scale, required Offset offset}) {
    // スケールを適用して座標を変換
    double transformedX = x * scale + offset.dx;
    double transformedY = y * scale + offset.dy;

    // 座標を返す
    return Offset(transformedX, transformedY);
  }
}
