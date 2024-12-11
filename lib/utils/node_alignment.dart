import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../constants/node_constants.dart';
import '../providers/screen_provider.dart';
import '../providers/settings_provider.dart';
import 'coordinate_utils.dart';

class NodeAlignment {
  // 垂直方向の配置
  static Future<void> alignNodesVertical(
    BuildContext context,
    Size screenSize,
    void Function(VoidCallback fn) setState,
    WidgetRef ref,
  ) async {
    final List<Node> nodes = ref.read(nodesProvider);
    if (nodes.isEmpty) return;
    // 画面中心座標を計算
    final screenCenter = CoordinateUtils.calculateScreenCenter(
      MediaQuery.of(context).size, // 画面サイズ
      AppBar().preferredSize.height, // AppBarの高さ（指定がなければ0にしても良い）
    );

    // 画面の中央をワールド座標に変換
    final basePosition = CoordinateUtils.screenToWorld(
      screenCenter,
      ref.read(screenProvider).offset,
      ref.read(screenProvider).scale,
    );
    // 一度だけ設定を取得
    final settings = ref.read(settingsNotifierProvider);

    // ルートノードを特定
    List<Node> rootNodes = nodes.where((node) => node.parent == null).toList();

    // 画面の中心を計算
    final double startX = basePosition.x; // ワールド座標のX中央
    final double startY = basePosition.y; // ワールド座標のY中央

    // 各ルートノードのサブツリーの幅を計算
    Map<Node, double> nodeWidths = {};
    for (var root in rootNodes) {
      _calculateSubtreeWidth(root, nodeWidths, settings);
    }

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
    BuildContext context,
    Size screenSize,
    void Function(VoidCallback fn) setState,
    WidgetRef ref,
  ) async {
    final List<Node> nodes = ref.read(nodesProvider);
    if (nodes.isEmpty) return;

    // 画面中心座標を計算
    final screenCenter = CoordinateUtils.calculateScreenCenter(
      MediaQuery.of(context).size, // 画面サイズ
      AppBar().preferredSize.height, // AppBarの高さ（指定がなければ0にしても良い）
    );

    // 画面の中央をワールド座標に変換
    final basePosition = CoordinateUtils.screenToWorld(
      screenCenter,
      ref.read(screenProvider).offset,
      ref.read(screenProvider).scale,
    );

    final double startX = basePosition.x; // ワールド座標のX中央
    final double startY = basePosition.y; // ワールド座標のY中央

    // 一度だけ設定を取得
    final settings = ref.read(settingsNotifierProvider);

    // ルートノードを特定
    List<Node> rootNodes = nodes.where((node) => node.parent == null).toList();

    // 各ルートノードのサブツリーの高さを計算
    Map<Node, double> nodeHeights = {};
    for (var root in rootNodes) {
      _calculateSubtreeHeight(root, nodeHeights, settings);
    }

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
      nodeWidths[node] = settings.parentChildDistance;
      return settings.parentChildDistance;
    }

    double width = node.children.fold(
        0.0,
        (sum, child) =>
            sum + _calculateSubtreeWidth(child, nodeWidths, settings));
    nodeWidths[node] = max(width, settings.parentChildDistance);
    return nodeWidths[node]!;
  }

  // サブツリーの高さを計算
  static double _calculateSubtreeHeight(
    Node node,
    Map<Node, double> nodeHeights,
    dynamic settings, // 取得した設定値
  ) {
    if (node.children.isEmpty) {
      nodeHeights[node] = settings.parentChildDistance;
      return settings.parentChildDistance;
    }

    double height = node.children.fold(
        0.0,
        (sum, child) =>
            sum + _calculateSubtreeHeight(child, nodeHeights, settings));
    nodeHeights[node] = max(height, settings.parentChildDistance);
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
        y + settings.parentChildDistance,
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
        x + settings.parentChildDistance,
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
      Future.delayed(Duration(milliseconds: i * NodeConstants.frameInterval),
          () {
        setState(() {
          node.position = startPosition + delta * i.toDouble();
        });
      });
    }

    // 最終位置を設定
    Future.delayed(
        const Duration(milliseconds: steps * NodeConstants.frameInterval), () {
      setState(() {
        node.position = targetPosition;
      });
    });
  }
}
