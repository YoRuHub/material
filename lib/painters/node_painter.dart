import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/logger.dart';
import '../models/node.dart';

/// ノードの描画を行うクラス
class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;
  final double scale;
  final Offset offset;
  final bool isTitleVisible;
  final BuildContext context;

  NodePainter(
    this.nodes,
    this.signalProgress,
    this.scale,
    this.offset,
    this.isTitleVisible,
    this.context,
  );

  Offset transformPoint(double x, double y) {
    return Offset(x * scale + offset.dx, y * scale + offset.dy);
  }

  // ノード間の接続線の描画
  @override
  void paint(Canvas canvas, Size size) {
    Node? activeNode;
    try {
      activeNode = nodes.firstWhere((node) => node.isActive);
    } catch (e) {
      activeNode = null;
    }

    for (var node in nodes) {
      if (node.parent != null) {
        // アクティブ系統のチェック
        bool isActiveLineage = isNodeInActiveLineage(node, activeNode);

        // 線の設定
        final Paint linePaint = Paint()
          ..color = isActiveLineage
              ? Colors.yellow
              : Theme.of(context).colorScheme.onSurface
          ..strokeWidth = scale
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

        final Offset start =
            transformPoint(node.parent!.position.x, node.parent!.position.y);
        final Offset end = transformPoint(node.position.x, node.position.y);

        canvas.drawLine(start, end, linePaint);

        // 信号エフェクト
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

      // タイトルの描画
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

      // ノードのグロー効果
      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = node.color.withOpacity(0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
        canvas.drawCircle(center, scaledRadius * 1.8, glowPaint);
      }

      // 細胞膜のテクスチャ
      final Paint texturePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 0.5 * scale;
      for (double i = 0; i < 360; i += 15) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + scaledRadius * 1.5 * cos(angle);
        final double y1 = center.dy + scaledRadius * 1.5 * sin(angle);
        canvas.drawCircle(Offset(x1, y1), scale * 0.5, texturePaint);
      }

      // 細胞質のグラデーション表現
      final gradient = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.2),
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      final Paint spherePaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: scaledRadius));
      canvas.drawCircle(center, scaledRadius, spherePaint);

      // 核の描画
      final double nucleusRadius = scaledRadius * 0.6;
      final Paint nuclearEnvelopePaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: nucleusRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.1;
      canvas.drawCircle(
          center, nucleusRadius - scale * 2, nuclearEnvelopePaint);

      // 核小体の表現
      final Paint nucleolusPaint = Paint()
        ..color = node.color.withOpacity(1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);
      for (int i = 0; i < 3; i++) {
        final double angle = Random().nextDouble() * 2 * pi;
        final double radius = nucleusRadius * 0.3 * Random().nextDouble();
        final Offset nucleolusPosition = Offset(
            center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
        canvas.drawCircle(nucleolusPosition, scale * 2, nucleolusPaint);
      }

      // 核質の質感表現
      final Paint nucleoplasmPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);
      for (int i = 0; i < 20; i++) {
        final double angle = Random().nextDouble() * 2 * pi;
        final double radius = nucleusRadius * Random().nextDouble() * 0.8;
        final Offset specklePosition = Offset(
            center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
        canvas.drawCircle(specklePosition, scale * 0.5, nucleoplasmPaint);
      }

      // 光沢の表現
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

  // ノードの系統（親ノード）をセットとして返す
  Set<Node> getAncestors(Node node) {
    Set<Node> ancestors = {};
    Node? currentNode = node.parent;
    while (currentNode != null) {
      ancestors.add(currentNode);
      currentNode = currentNode.parent;
    }
    return ancestors;
  }

  // ノードの子孫ノードをセットとして返す
  Set<Node> getAllDescendants(Node node) {
    Set<Node> descendants = {};
    void traverse(Node n) {
      descendants.add(n);
      for (var child in n.children) {
        traverse(child);
      }
    }

    traverse(node);
    return descendants;
  }

  // 修正されたisNodeInActiveLineageメソッド
  bool isNodeInActiveLineage(Node node, Node? activeNode) {
    if (activeNode == null) return false;
    if (node == activeNode) return true;

    // 親系統をセットとして取得
    Set<Node> activeAncestors = getAncestors(activeNode);

    // ノードがアクティブ系統に含まれているか確認
    if (activeAncestors.contains(node)) return true;

    // 子孫系統をセットとして取得
    Set<Node> activeDescendants = getAllDescendants(activeNode);

    // ノードがアクティブ系統の子孫に含まれているか確認
    if (activeDescendants.contains(node)) return true;

    // 親が同じかを確認
    if (node.parent != null && activeNode.parent != null) {
      if (node.parent == activeNode.parent) return true;
    }

    return false;
  }
}
