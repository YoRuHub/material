import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../constants/node_constants.dart';
import '../providers/settings_provider.dart';

class NodeAlignment {
  // 垂直方向の配置
  static Future<void> alignNodesVertical(
    List<Node> nodes,
    Size screenSize,
    void Function(VoidCallback fn) setState,
    WidgetRef ref,
  ) async {
    if (nodes.isEmpty) return;

    // 一度だけ設定を取得
    final settings = ref.read(settingsNotifierProvider);

    // ルートノードを特定
    List<Node> rootNodes = nodes.where((node) => node.parent == null).toList();

    // 画面の中心を計算
    final double screenCenterX = screenSize.width / 2;
    const double startY = NodeConstants.defaultStartY;

    // 各ルートノードのサブツリーの幅を計算
    Map<Node, double> nodeWidths = {};
    for (var root in rootNodes) {
      _calculateSubtreeWidth(root, nodeWidths, settings);
    }

    // ルートノードの合計幅を計算
    double totalWidth =
        rootNodes.fold(0.0, (sum, node) => sum + nodeWidths[node]!);
    double startX = screenCenterX - totalWidth / 2;

    // 各ルートノードとその子孫の目標位置を計算
    double currentX = startX;
    for (var root in rootNodes) {
      _calculateTargetPositionsVertical(
        root,
        currentX,
        startY,
        nodeWidths,
        setState,
        settings,
      );
      currentX += nodeWidths[root]!;
    }
  }

  // 水平方向の配置
  static Future<void> alignNodesHorizontal(
    List<Node> nodes,
    Size screenSize,
    void Function(VoidCallback fn) setState,
    WidgetRef ref,
  ) async {
    if (nodes.isEmpty) return;

    // 一度だけ設定を取得
    final settings = ref.read(settingsNotifierProvider);

    // ルートノードを特定
    List<Node> rootNodes = nodes.where((node) => node.parent == null).toList();

    // 画面の中心を計算
    final double screenCenterY = screenSize.height / 2;
    const double startX = NodeConstants.defaultStartX;

    // 各ルートノードのサブツリーの高さを計算
    Map<Node, double> nodeHeights = {};
    for (var root in rootNodes) {
      _calculateSubtreeHeight(root, nodeHeights, settings);
    }

    // ルートノードの合計高さを計算
    double totalHeight =
        rootNodes.fold(0.0, (sum, node) => sum + nodeHeights[node]!);
    double startY = screenCenterY - totalHeight / 2;

    // 各ルートノードとその子孫の目標位置を計算
    double currentY = startY;
    for (var root in rootNodes) {
      _calculateTargetPositionsHorizontal(
        root,
        startX,
        currentY,
        nodeHeights,
        setState,
        settings,
      );
      currentY += nodeHeights[root]!;
    }
  }

  // サブツリーの幅を計算
  static double _calculateSubtreeWidth(
    Node node,
    Map<Node, double> nodeWidths,
    dynamic settings, // 取得した設定値
  ) {
    if (node.children.isEmpty) {
      nodeWidths[node] = settings.idealNodeDistance;
      return settings.idealNodeDistance;
    }

    double width = node.children.fold(
        0.0,
        (sum, child) =>
            sum + _calculateSubtreeWidth(child, nodeWidths, settings));
    nodeWidths[node] = max(width, settings.idealNodeDistance);
    return nodeWidths[node]!;
  }

  // サブツリーの高さを計算
  static double _calculateSubtreeHeight(
    Node node,
    Map<Node, double> nodeHeights,
    dynamic settings, // 取得した設定値
  ) {
    if (node.children.isEmpty) {
      nodeHeights[node] = settings.idealNodeDistance;
      return settings.idealNodeDistance;
    }

    double height = node.children.fold(
        0.0,
        (sum, child) =>
            sum + _calculateSubtreeHeight(child, nodeHeights, settings));
    nodeHeights[node] = max(height, settings.idealNodeDistance);
    return nodeHeights[node]!;
  }

  // 垂直配置の目標位置を計算
  static void _calculateTargetPositionsVertical(
    Node node,
    double x,
    double y,
    Map<Node, double> nodeWidths,
    void Function(VoidCallback fn) setState,
    dynamic settings, // 取得した設定値
  ) {
    // ノードの目標位置を設定
    vector_math.Vector2 targetPosition = vector_math.Vector2(x, y);
    _animateNodeToPosition(node, targetPosition, setState);

    if (node.children.isEmpty) return;

    // 子ノードの開始X座標を計算
    double childrenTotalWidth =
        node.children.fold(0.0, (sum, child) => sum + nodeWidths[child]!);
    double childX = x - childrenTotalWidth / 2;

    // 各子ノードを配置
    for (var child in node.children) {
      _calculateTargetPositionsVertical(
        child,
        childX + nodeWidths[child]! / 2,
        y + settings.idealNodeDistance,
        nodeWidths,
        setState,
        settings,
      );
      childX += nodeWidths[child]!;
    }
  }

  // 水平配置の目標位置を計算
  static void _calculateTargetPositionsHorizontal(
    Node node,
    double x,
    double y,
    Map<Node, double> nodeHeights,
    void Function(VoidCallback fn) setState,
    dynamic settings, // 取得した設定値
  ) {
    // ノードの目標位置を設定
    vector_math.Vector2 targetPosition = vector_math.Vector2(x, y);
    _animateNodeToPosition(node, targetPosition, setState);

    if (node.children.isEmpty) return;

    // 子ノードの開始Y座標を計算
    double childrenTotalHeight =
        node.children.fold(0.0, (sum, child) => sum + nodeHeights[child]!);
    double childY = y - childrenTotalHeight / 2;

    // 各子ノードを配置
    for (var child in node.children) {
      _calculateTargetPositionsHorizontal(
        child,
        x + settings.idealNodeDistance,
        childY + nodeHeights[child]! / 2,
        nodeHeights,
        setState,
        settings,
      );
      childY += nodeHeights[child]!;
    }
  }

  // ノードを目標位置まで徐々に移動
  static void _animateNodeToPosition(
    Node node,
    vector_math.Vector2 targetPosition,
    void Function(VoidCallback fn) setState,
  ) {
    const int steps = NodeConstants.totalAnimationFrames;
    vector_math.Vector2 startPosition = node.position.clone();
    vector_math.Vector2 delta =
        (targetPosition - startPosition) / steps.toDouble();

    for (int i = 0; i < steps; i++) {
      Future.delayed(Duration(milliseconds: i * 16), () {
        setState(() {
          node.position = startPosition + delta * i.toDouble();
        });
      });
    }

    // 最終位置を設定
    Future.delayed(const Duration(milliseconds: steps * 16), () {
      setState(() {
        node.position = targetPosition;
      });
    });
  }
}
