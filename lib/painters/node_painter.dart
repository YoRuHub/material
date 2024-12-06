import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/node_state_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import '../models/node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ノードの描画を行うクラス
class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;
  final double scale;
  final Offset offset;
  final BuildContext context; // BuildContextを追加
  final WidgetRef ref; // Riverpodの参照を追加

  /// コンストラクタ
  /// [nodes] 描画対象のノード
  /// [signalProgress] 信号の進行割合
  /// [scale] スケールの倍率
  /// [offset] オフセット位置
  NodePainter(this.nodes, this.signalProgress, this.scale, this.offset,
      this.context, this.ref);

  /// 座標をスケールとオフセットで変換する
  /// [x] X座標
  /// [y] Y座標
  Offset transformPoint(double x, double y) {
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
    Node? activeNode = ref.read(nodeStateProvider).activeNode;
    final isTitleVisible = ref.read(screenProvider).isTitleVisible;

    // ノード間の接続線の描画
    for (var node in nodes) {
      if (node.parent != null) {
        bool isActiveLineage = isNodeInActiveLineage(node, activeNode) ||
            isNodeInActiveLineage(node.parent!, activeNode);

        final Paint linePaint = Paint()
          ..color = isActiveLineage
              ? Colors.yellow // アクティブ系統の線は黄色
              : Theme.of(context).colorScheme.onSurface
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
    }

    // ノードの描画
    for (var node in nodes) {
      final Offset center = transformPoint(node.position.x, node.position.y);
      final double scaledRadius = node.radius * scale;

      if (isTitleVisible) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: node.title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16 * scale,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset(center.dx - textPainter.width / 2,
                center.dy + scaledRadius + 5));
      }

      if (activeNode != null && node == activeNode) {
        final Paint glowPaint = Paint()
          ..color = node.color!.withOpacity(0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
        canvas.drawCircle(center, scaledRadius * 1.8, glowPaint);
      }

      final Paint texturePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 0.5 * scale;

      for (double i = 0; i < 360; i += 15) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + scaledRadius * 1.5 * cos(angle);
        final double y1 = center.dy + scaledRadius * 1.5 * sin(angle);
        canvas.drawCircle(Offset(x1, y1), scale * 0.5, texturePaint);
      }

      final gradient = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.2),
          node.color!.withOpacity(0.7),
          node.color!.withOpacity(0.6),
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

      canvas.drawCircle(
          center, nucleusRadius - scale * 2, nuclearEnvelopePaint);

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
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: nucleusRadius));

      canvas.drawCircle(center, nucleusRadius, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(NodePainter oldDelegate) {
    return true;
  }
}
