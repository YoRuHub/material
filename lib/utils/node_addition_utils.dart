import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

import '../constants/node_constants.dart';
import '../database/models/node_map_model.dart';
import '../database/models/node_model.dart';
import '../models/node.dart';
import '../providers/node_state_provider.dart';
import '../utils/coordinate_utils.dart';
import '../utils/node_color_utils.dart';
import '../utils/node_operations.dart';

class NodeAdditionUtils {
  /// Adds a new node to the project, with flexible positioning and optional parent
  static Future<Node?> addNode({
    required BuildContext context,
    required WidgetRef ref,
    required int projectId,
    required int nodeId,
    required String title,
    required String contents,
    Color? color,
    Offset? currentOffset,
    double? currentScale,
  }) async {
    // 1. Access necessary providers
    final nodeState = ref.read(nodeStateNotifierProvider);
    final NodesNotifier nodesNotifier = ref.read(nodesProvider.notifier);
    final nodeModel = NodeModel();
    final nodeMapModel = NodeMapModel();

    // 2. Calculate base position for the new node
    vector_math.Vector2 basePosition = _calculateBasePosition(
      context,
      nodeState,
      currentOffset,
      currentScale,
      ref.read(nodesProvider),
    );

    // 4. Insert node into database
    final newNodeData =
        await nodeModel.upsertNode(nodeId, title, contents, color, projectId);
    int newNodeId = newNodeData['id'] as int;

    // 5. Create the new node
    Node newNode = NodeOperations.addNode(
      position: basePosition,
      nodeId: newNodeId,
      title: title,
      contents: contents,
      color: color,
      projectId: projectId,
    );

    // 6. Handle parent-child relationship if an active node exists
    if (nodeState.activeNode != null) {
      // Set the parent
      newNode.parent = nodeState.activeNode;

      // Add to parent's children list
      nodeState.activeNode!.children.add(newNode);

      // Insert node map in database to maintain parent-child relationship
      await nodeMapModel.insertNodeMap(
          nodeState.activeNode!.id, newNodeId, projectId);
    }

    // Update node colors in the hierarchy
    NodeColorUtils.updateNodeColor(newNode, projectId);
    // 7. Add the new node to the nodes list
    nodesNotifier.addNode(newNode);

    return newNode;
  }

  /// Calculate the base position for the new node
  static vector_math.Vector2 _calculateBasePosition(
    BuildContext context,
    NodeState nodeState,
    Offset? currentOffset,
    double? currentScale,
    List<Node> nodes, // 既存ノードのリストを渡す
  ) {
    vector_math.Vector2 basePosition;

    // currentOffsetとcurrentScaleがnullの場合、デフォルト値を設定
    currentOffset ??= const Offset(0.0, 0.0); // オフセットがnullなら(0,0)を設定
    currentScale ??= 1.0; // スケールがnullなら1.0を設定

    // 画面サイズとAppBarの高さを考慮して中央を計算
    final screenCenter = CoordinateUtils.calculateScreenCenter(
      MediaQuery.of(context).size, // 画面サイズ
      AppBar().preferredSize.height, // AppBarの高さ（指定がなければ0にしても良い）
    );

    // 中央座標をワールド座標に変換
    basePosition = CoordinateUtils.screenToWorld(
      screenCenter, // 画面中央
      currentOffset,
      currentScale,
    );

    // ノードの重なりチェックと調整
    basePosition = _adjustPositionToAvoidOverlap(basePosition, nodes);

    // Debugログで計算結果を出力
    Logger.debug('Calculated base position: $basePosition');

    return basePosition;
  }

  /// ノードの位置が重ならないように調整
  static vector_math.Vector2 _adjustPositionToAvoidOverlap(
    vector_math.Vector2 basePosition,
    List<Node> nodes,
  ) {
    const double minDistance = NodeConstants.nodePreferredDistance; // 最小距離

    // 既存ノードと重ならないように少しずらす
    for (var node in nodes) {
      final distance =
          CoordinateUtils.calculateDistance(basePosition, node.position);

      // 距離が最小距離より小さい場合、重なっているので少しずらす
      if (distance < minDistance) {
        basePosition = basePosition +
            vector_math.Vector2(
              (Random().nextDouble() * 2 - 1) * minDistance,
              (Random().nextDouble() * 2 - 1) * minDistance,
            );
      }
    }

    return basePosition;
  }
}
