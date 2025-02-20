import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/node_tool_widget.dart';
import 'package:flutter_app/providers/drag_position_provider.dart';
import 'package:flutter_app/providers/node_state_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import '../models/node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node_tool_type.dart';
import '../providers/node_provider.dart';
import 'node_tool_painter.dart';

/// ノードの描画を行うクラス
class NodePainter extends CustomPainter {
  final double signalProgress;
  final BuildContext context; // BuildContextを追加
  final WidgetRef ref; // Riverpodの参照を追加

  /// コンストラクタ
  /// [signalProgress] 信号の進行割合
  NodePainter(this.signalProgress, this.context, this.ref);

  /// 座標をスケールとオフセットで変換する
  /// [x] X座標
  /// [y] Y座標
  Offset transformPoint(double x, double y) {
    double scale = ref.read(screenProvider).scale;
    Offset offset = ref.read(screenProvider).offset;
    return Offset(
      x * scale + offset.dx,
      y * scale + offset.dy,
    );
  }

  // ノードが共通の祖先を持つかチェック
  bool hasCommonAncestor(Node node1, Node node2) {
    Set<Node> ancestors1 = getAllAncestors(node1);
    Set<Node> ancestors2 = getAllAncestors(node2);
    return ancestors1.intersection(ancestors2).isNotEmpty;
  }

  Set<Node> getAllAncestors(Node node) {
    Set<Node> ancestors = {};
    Node? current = node.parent;
    while (current != null) {
      ancestors.add(current);
      current = current.parent;
    }
    return ancestors;
  }

  Set<Node> getAllDescendants(Node node) {
    Set<Node> descendants = {};
    for (var child in node.children) {
      descendants.add(child);
      descendants.addAll(getAllDescendants(child));
    }
    return descendants;
  }

  /// ノードがアクティブノードの系統に含まれるかを確認する
  bool isNodeInActiveLineage(Node node, Node? activeNode) {
    if (activeNode == null) return false;
    if (node == activeNode) return true;

    Set<Node> activeAncestors = getAllAncestors(activeNode);
    if (activeAncestors.contains(node)) return true;

    Set<Node> activeDescendants = getAllDescendants(activeNode);
    if (activeDescendants.contains(node)) return true;

    if (node.parent != null && activeNode.parent != null) {
      if (node.parent == activeNode.parent) return true;
    }

    if (hasCommonAncestor(node, activeNode)) return true;

    Set<Node> nodeDescendants = getAllDescendants(node);
    if (nodeDescendants.any(
        (descendant) => hasCommonAncestor(descendant, activeNode))) return true;

    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Riverpodのstateを参照してアクティブノードを取得
    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;
    final isTitleVisible = ref.read(screenProvider).isTitleVisible;
    final isLinkMode = ref.read(screenProvider).isLinkMode;
    final scale = ref.read(screenProvider).scale;
    final selectedNode = ref.read(nodeStateProvider).selectedNode;

    // ノード間の接続線の描画
    for (var node in ref.read(nodesProvider)) {
      // 親ノードとの線の描画
      if (node.parent != null) {
        bool isActiveLineage = activeNodes.any((activeNode) =>
            isNodeInActiveLineage(node, activeNode) ||
            isNodeInActiveLineage(node.parent!, activeNode));

        final Paint linePaint = Paint()
          ..color = isActiveLineage
              ? Colors.yellow // アクティブ系統の線は黄色
              : Theme.of(context).colorScheme.secondary
          ..strokeWidth = scale
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

        final Offset start = transformPoint(
          node.parent!.position.x,
          node.parent!.position.y,
        );
        final Offset end = transformPoint(
          node.position.x,
          node.position.y,
        );

        canvas.drawLine(start, end, linePaint);

        double opacity = 1 * (0.6 + 0.4 * sin(signalProgress * 3.14159 * 5));
        final Paint signalPaint = Paint()
          ..color = isActiveLineage
              ? Colors.yellow.withOpacity(opacity)
              : Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, isActiveLineage ? scale * 1.5 : scale);

        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(Offset(signalX, signalY),
            isActiveLineage ? 3 * scale : 2 * scale, signalPaint);
      }

      // sourceNodesの線の描画
      if (node.sourceNodes.isNotEmpty) {
        for (var sourceNode in node.sourceNodes) {
          final Paint sourceLinePaint = Paint()
            ..color = Colors.cyan.withOpacity(0.5)
            ..strokeWidth = scale
            ..style = PaintingStyle.stroke
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

          final Offset start = transformPoint(
            sourceNode.position.x,
            sourceNode.position.y,
          );

          final Offset end = transformPoint(
            node.position.x,
            node.position.y,
          );

          // Draw the base line
          canvas.drawLine(start, end, sourceLinePaint);

          // Add signal effect
          double opacity = 1 * (0.6 + 0.4 * sin(signalProgress * 3.14159 * 5));
          final Paint signalPaint = Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 1.5);

          // Calculate signal position along the line
          final double signalX =
              start.dx + (end.dx - start.dx) * signalProgress;
          final double signalY =
              start.dy + (end.dy - start.dy) * signalProgress;

          canvas.drawCircle(Offset(signalX, signalY), 2 * scale, signalPaint);
        }
      }
    }

    // LinkMode時のアクティブノードとドラッグ位置の線の描画
    if (isLinkMode && activeNodes.isNotEmpty) {
      final dragPosition = ref.read(dragPositionProvider);
      if (dragPosition.x != null && dragPosition.y != null) {
        final Offset dragOffset =
            transformPoint(dragPosition.x!, dragPosition.y!);

        for (var activeNode in activeNodes) {
          final Offset nodeOffset =
              transformPoint(activeNode.position.x, activeNode.position.y);

          // Line paint for the connection
          final Paint linkPaint = Paint()
            ..color = Theme.of(context).colorScheme.primary
            ..strokeWidth = scale
            ..style = PaintingStyle.stroke
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

          canvas.drawLine(nodeOffset, dragOffset, linkPaint);

          // Signal effect
          double opacity = 1 * (0.6 + 0.4 * sin(signalProgress * 3.14159 * 5));
          final Paint signalPaint = Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale * 1.5);

          // Calculate signal position along the line
          final double signalX =
              nodeOffset.dx + (dragOffset.dx - nodeOffset.dx) * signalProgress;
          final double signalY =
              nodeOffset.dy + (dragOffset.dy - nodeOffset.dy) * signalProgress;

          canvas.drawCircle(Offset(signalX, signalY), 2 * scale, signalPaint);
        }
      }
    }

    // ノードの描画
    for (var node in ref.read(nodesProvider)) {
      final Offset center = transformPoint(node.position.x, node.position.y);
      final double scaledRadius = node.radius * scale;

      // ドラッグ位置との重なりを正確に判定
      final dragPosition = ref.read(dragPositionProvider);
      bool isHovered = dragPosition.x != null &&
          dragPosition.y != null &&
          (center - transformPoint(dragPosition.x!, dragPosition.y!))
                  .distance <=
              scaledRadius;

      // ノードがアクティブノードに含まれる場合は協調しない
      if (activeNodes.contains(node)) {
        isHovered = false;
      }

      // ノードがドラッグ位置に重なっている場合の強調表示
      if (isHovered) {
        final Paint hoverPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
        canvas.drawCircle(center, scaledRadius * 1.3, hoverPaint);
      }

      if (isTitleVisible) {
        // スケールに基づいたフォントサイズを計算
        final scaledFontSize =
            Theme.of(context).textTheme.titleMedium?.fontSize ?? 14.0;
        final textStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: scaledFontSize * scale, // フォントサイズにスケールを適用
            );

        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: node.title, style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // タイトルの描画位置はそのまま
        textPainter.paint(
          canvas,
          Offset(
              center.dx - textPainter.width / 2, center.dy + scaledRadius + 5),
        );
      }

      // アクティブノードがリストに含まれている場合に強調表示 Todo:Settingsで管理
      if (activeNodes.contains(node)) {
        final Paint glowPaint = Paint()
          ..color = node.color!.withOpacity(0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * scale);
        canvas.drawCircle(center, scaledRadius * 1.3, glowPaint);
      }

      final gradient = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.3),
          node.color!.withOpacity(0.6),
          node.color!.withOpacity(1),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final Paint spherePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: scaledRadius),
        );

      canvas.drawCircle(center, scaledRadius, spherePaint);

      final double nucleusRadius = scaledRadius * 0.6;
      final Paint nuclearEnvelopePaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: nucleusRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.1;

      canvas.drawCircle(center, nucleusRadius * 0, nuclearEnvelopePaint);

      final Paint nucleolusPaint = Paint()
        ..color = node.color!.withOpacity(1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

      for (int i = 0; i < 3; i++) {
        final double angle = Random().nextDouble() * 2 * pi;
        final double radius = nucleusRadius * 0.3 * Random().nextDouble();
        final Offset nucleolusPosition = Offset(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
        canvas.drawCircle(nucleolusPosition, scale * 2, nucleolusPaint);
      }

      final Paint nucleoplasmPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

      for (int i = 0; i < 20; i++) {
        final double angle = Random().nextDouble() * 2 * pi;
        final double radius = nucleusRadius * Random().nextDouble() * 0.8;
        final Offset specklePosition = Offset(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
        canvas.drawCircle(specklePosition, scale * 0.5, nucleoplasmPaint);
      }

      final Paint highlightPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.2,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.05),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: nucleusRadius));

      canvas.drawCircle(center, nucleusRadius, highlightPaint);
    }

    // 選択中のノードに対しての処理
    if (selectedNode != null) {
      // NodeToolWidgetをリストとして生成
      final List<NodeToolWidget> toolWidgets = NodeToolType.values
          .asMap()
          .entries
          .map((entry) => NodeToolWidget(
                tool: entry.value.tool,
                id: entry.key,
              ))
          .toList();

      // ループを使って描画
      for (var toolWidget in toolWidgets) {
        NodeToolPainter(
          ref: ref,
          context: context,
          toolWidget: toolWidget,
        ).paint(canvas, size);
      }
    }
  }

  @override
  bool shouldRepaint(NodePainter oldDelegate) {
    return true;
  }
}
