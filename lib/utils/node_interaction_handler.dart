import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/providers/drag_position_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/providers/node_state_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../painters/node_tool_painter.dart';
import 'node_operations.dart';

class NodeInteractionHandler {
  final WidgetRef ref;
  final int projectId;

  Offset _offsetStart = Offset.zero;
  Offset _dragStart = Offset.zero;
  final _nodeMapModel = NodeMapModel();
  NodeInteractionHandler({required this.ref, required this.projectId});

  void onPanStart(DragStartDetails details) {
    final ScreenNotifier screenNotifier = ref.read(screenProvider.notifier);
    final screenState = ref.read(screenProvider);
    final isLinkMode = ref.read(screenProvider).isLinkMode;

    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      screenState.offset,
      screenState.scale,
    );

    // isLinkModeがtrueのとき、ノードとの重なりをチェックしてアクティブノードにする

    for (var node in ref.read(nodesProvider)) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      // ノードの半径より近ければ、そのノードをアクティブにする
      if (distance < node.radius) {
        ref.read(nodeStateProvider.notifier).setDraggedNode(node);
        if (isLinkMode) {
          ref
              .read(nodeStateProvider.notifier)
              .setActiveNodes([node]); // アクティブノードとして設定
        }
        screenNotifier.disablePanning();
        _dragStart = details.localPosition;
        return;
      }
    }

    // リンクモードでない場合は、通常のドラッグ処理を行う
    if (!isLinkMode) {
      screenNotifier.enablePanning();
      _offsetStart = screenState.offset;
      _dragStart = details.localPosition;
      ref.read(nodeStateProvider.notifier).setDraggedNode(null);
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    final draggedNode = ref.read(nodeStateProvider).draggedNode;
    final isPanning = ref.read(screenProvider).isPanning;
    final isLinkMode = ref.read(screenProvider).isLinkMode;

    if (draggedNode != null && isLinkMode == false) {
      // ノードの位置更新
      vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
        details.localPosition,
        ref.read(screenProvider).offset,
        ref.read(screenProvider).scale,
      );
      draggedNode.position = worldPos;
    } else if (isLinkMode) {
      // タップ位置に基づいて更新
      final dragPosition = ref.read(dragPositionProvider);
      vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
        details.localPosition,
        ref.read(screenProvider).offset,
        ref.read(screenProvider).scale,
      );
      dragPosition.setPosition(worldPos.x, worldPos.y); // 新たにsetPositionメソッドを追加
    } else if (isPanning) {
      // 画面のオフセット更新
      final dragDelta = details.localPosition - _dragStart;
      ref.read(screenProvider.notifier).setOffset(_offsetStart + dragDelta);
    }
  }

  void onPanEnd(DragEndDetails details) {
    final draggedNode = ref.read(nodeStateProvider).draggedNode;
    final linkMode = ref.read(screenProvider).isLinkMode;
    final scale = ref.read(screenProvider).scale; // scaleの取得
    final offset = ref.read(screenProvider).offset; // offsetの取得

    // ドラッグノードが存在する場合
    if (draggedNode != null) {
      _checkAndUpdateParentChildRelationship(draggedNode);
      draggedNode.velocity = vector_math.Vector2.zero();
      ref.read(nodeStateProvider.notifier).setDraggedNode(null);
    }

    // リンクモードが有効な場合
    if (linkMode) {
      final dragPosition = ref.read(dragPositionProvider);
      final nodes = ref.read(nodesProvider);

      // タッチ判定
      final hoveredNode = _getHoveredNode(nodes, dragPosition, scale, offset);

      // リンク処理
      if (hoveredNode != null) {
        // activeNodeを外で取得
        final activeNodes = ref.read(nodeStateProvider).activeNodes;
        if (activeNodes.isNotEmpty) {
          for (final activeNode in activeNodes) {
            NodeOperations.linkNode(
                ref: ref, activeNode: activeNode, hoveredNode: hoveredNode);
          }
        }
      }
    }

    // ドラッグ位置リセット
    ref.read(dragPositionProvider).reset();
    ref.read(screenProvider.notifier).disablePanning();
  }

  Node? _getHoveredNode(
    List<Node> nodes,
    DragPosition dragPosition,
    double scale,
    Offset offset,
  ) {
    for (var node in nodes) {
      final Offset center = NodeOperations.transformPoint(
          node.position.x, node.position.y,
          scale: scale, offset: offset);
      final double scaledRadius = node.radius * scale;

      bool isHovered = dragPosition.x != null &&
          dragPosition.y != null &&
          (center -
                      NodeOperations.transformPoint(
                          dragPosition.x!, dragPosition.y!,
                          scale: scale, offset: offset))
                  .distance <=
              scaledRadius;

      if (isHovered) {
        return node; // 重なっているノードを返す
      }
    }

    return null; // 重なっているノードがない場合
  }

  bool canLinkNodes(Node sourceNode, Node targetNode) {
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

  Set<Node> getAllAncestors(Node node) {
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

  void onTapUp(TapUpDetails details, BuildContext context) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      ref.read(screenProvider).offset,
      ref.read(screenProvider).scale,
    );
    _checkForNodeSelection(worldPos, context); // contextを渡す
  }

  bool _checkForNodeSelection(
      vector_math.Vector2 worldPos, BuildContext context) {
    bool isNodeSelected = false;

    // ノードが選択されているかチェック
    for (var node in ref.read(nodesProvider)) {
      double distance = _calculateDistance(node.position, worldPos);

      if (distance < node.radius) {
        isNodeSelected = _handleNodeSelection(node); // contextを渡す
        break;
      }
    }

    // ノードが選択されなかった場合、選択解除処理
    if (!isNodeSelected) {
      _handleDeselectNode(worldPos, context); // contextを渡す
    }

    return isNodeSelected;
  }

// ノードとタップ位置の距離を計算する関数
  double _calculateDistance(
      vector_math.Vector2 nodePos, vector_math.Vector2 worldPos) {
    double dx = nodePos.x - worldPos.x;
    double dy = nodePos.y - worldPos.y;
    return sqrt(dx * dx + dy * dy);
  }

// ノードが選択された場合の処理
  bool _handleNodeSelection(Node node) {
    bool isNodeSelected = false;

    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;

    if (activeNodes.contains(node)) {
      node.isActive = false;
      ref.read(nodeStateProvider.notifier).setActiveNodes(
          activeNodes.where((activeNode) => activeNode != node).toList());
      ref.read(nodeStateProvider.notifier).clearSelectedNode();
    } else {
      _toggleActiveNode(node);
      _toggleSelectedNode(node);
    }

    isNodeSelected = true;
    return isNodeSelected;
  }

// ノードが選択されなかった場合、選択解除処理
  void _handleDeselectNode(vector_math.Vector2 worldPos, BuildContext context) {
    final selectedNode = ref.read(nodeStateProvider).selectedNode;
    final scale = ref.read(screenProvider).scale;

    if (selectedNode != null) {
      double distance =
          _calculateDistanceWithScale(selectedNode.position, worldPos, scale);

      final double outerRadius = NodeConstants.defaultNodeRadius * 3 * scale;
      final double innerRadius = NodeConstants.defaultNodeRadius * 1.5 * scale;

      // 右側の場合のみ処理を行う
      if (distance > innerRadius &&
          distance < outerRadius &&
          worldPos.x > selectedNode.position.x) {
        final tapPosition = Offset(worldPos.x, worldPos.y);

        // どのエリアがタップされたのかを取得
        String tappedArea =
            NodeToolPainter(ref: ref, context: context, tool: 'edit')
                .isTapped(tapPosition);

        if (tappedArea.isEmpty) {
          tappedArea = NodeToolPainter(ref: ref, context: context, tool: 'add')
              .isTapped(tapPosition);
        }
        // Tapped area によって処理を分ける
        return;
      }
    }

    _clearActiveNodes();
    ref.read(nodeStateProvider.notifier).clearSelectedNode();
  }

// スケールを考慮したノードとタップ位置の距離を計算する関数
  double _calculateDistanceWithScale(
      vector_math.Vector2 nodePos, vector_math.Vector2 worldPos, double scale) {
    double adjustedNodeX = nodePos.x * scale;
    double adjustedNodeY = nodePos.y * scale;
    double adjustedWorldPosX = worldPos.x * scale;
    double adjustedWorldPosY = worldPos.y * scale;

    return _calculateDistance(vector_math.Vector2(adjustedNodeX, adjustedNodeY),
        vector_math.Vector2(adjustedWorldPosX, adjustedWorldPosY));
  }

// アクティブノードを解除する関数
  void _clearActiveNodes() {
    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;
    if (activeNodes.isNotEmpty) {
      for (var activeNode in activeNodes) {
        activeNode.isActive = false;
      }
      ref.read(nodeStateProvider.notifier).setActiveNodes([]);
    }
  }

  void _toggleActiveNode(Node newNode) {
    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;

    // もし新しいノードがすでにアクティブノードリストに含まれていない場合
    if (!activeNodes.contains(newNode)) {
      // 現在のアクティブノードを非アクティブにする処理
      for (var node in activeNodes) {
        node.isActive = false;
      }

      // 新しいノードをアクティブノードリストに追加
      newNode.isActive = true;
      activeNodes.add(newNode);
      ref.read(nodeStateProvider.notifier).setActiveNodes(activeNodes);
      Logger.debug('アクティブノードを追加しました');
    } else {
      // 新しいノードがすでにアクティブノードリストにある場合、非アクティブにする
      newNode.isActive = false;
      activeNodes.remove(newNode);
      ref.read(nodeStateProvider.notifier).setActiveNodes(activeNodes);
    }
  }

  void _toggleSelectedNode(Node newNode) {
    final currentSelectedNode = ref.read(nodeStateProvider).selectedNode;
    Logger.debug('現在の選択ノード:$currentSelectedNode');
    if (currentSelectedNode != null) {
      currentSelectedNode.isSelected = false;
      ref.read(nodeStateProvider.notifier).setSelectedNode(null);
    }
    newNode.isSelected = true;
    ref.read(nodeStateProvider.notifier).setSelectedNode(newNode);
  }

  void _checkAndUpdateParentChildRelationship(Node draggedNode) {
    for (Node node in ref.read(nodesProvider)) {
      if (node == draggedNode) continue;

      // ドラッグされたノードと他のノードとの距離を計算
      double distance = (draggedNode.position - node.position).length;

      // 規定のスナップ距離内の場合のみ処理を実行
      if (distance < NodeConstants.snapEffectRange) {
        // 循環参照が発生するか確認
        if (_wouldCreateCycle(draggedNode, node)) continue;

        // **リンク済みの関係があれば解除**
        if (draggedNode.targetNodes.contains(node) ||
            node.targetNodes.contains(draggedNode)) {
          NodeOperations.linkNode(
              ref: ref, activeNode: draggedNode, hoveredNode: node);
        }

        // 新しい親子関係を形成
        if (node != draggedNode.parent) {
          // 現在の親ノードからこのノードを削除
          if (draggedNode.parent != null) {
            _nodeMapModel.deleteChildNodeMap(draggedNode.id);
            draggedNode.parent!.children.remove(draggedNode);
          }

          // ノードを新しい親ノードに紐づける
          draggedNode.parent = node;
          _nodeMapModel.insertNodeMap(node.id, draggedNode.id, projectId);
          node.children.add(draggedNode);

          // 色を更新
          NodeColorUtils.updateNodeColor(node, projectId);

          // **孫ノードを子ノードに正しく紐づける**
          for (Node child in draggedNode.children) {
            child.parent = draggedNode; // 子ノードとして再設定
            _nodeMapModel.insertNodeMap(draggedNode.id, child.id, projectId);
            NodeColorUtils.updateNodeColor(child, projectId);
          }

          // 物理演算用のフラグをリセット
          draggedNode.isTemporarilyDetached = false;
          node.isTemporarilyDetached = false;
        }
      }
    }
  }

  // 循環参照が発生するかチェックするヘルパーメソッド
  bool _wouldCreateCycle(Node draggedNode, Node potentialParent) {
    // ドラッグされているノードが、新しい親の祖先になっているかチェック
    Node? current = potentialParent;
    while (current != null) {
      if (current == draggedNode) return true;
      current = current.parent;
    }
    return false;
  }
}
