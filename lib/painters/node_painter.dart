
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/node.dart';


class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;
  final double scale;
  final Offset offset;

  NodePainter(this.nodes, this.signalProgress, this.scale, this.offset);

  Offset transformPoint(double x, double y) {
    return Offset(
      x * scale + offset.dx,
      y * scale + offset.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 接続線の描画部分は変更なし
    for (var node in nodes) {
      if (node.parent != null) {
        final Paint linePaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
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

        double opacity = 1 * (0.5 + 0.5 * sin(signalProgress * 3.14159 * 5));
        final Paint signalPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(Offset(signalX, signalY), 2 * scale, signalPaint);
      }
    }

    // 細胞本体の描画
    for (var node in nodes) {
      final Offset center = transformPoint(node.position.x, node.position.y);
      final double scaledRadius = node.radius * scale;

      // 細胞膜のグロー効果
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

      // 細胞質のグラデーション
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
          Rect.fromCircle(center: center, radius: scaledRadius),
        );

      canvas.drawCircle(center, scaledRadius, spherePaint);

      // 細胞核の描画（改良版）
      final double nucleusRadius = scaledRadius * 0.6;

      // 核膜の二重構造表現

      final Paint nuclearEnvelopePaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: nucleusRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.1;

// 内側の二重構造を描画
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
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
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
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
        canvas.drawCircle(specklePosition, scale * 0.5, nucleoplasmPaint);
      }

      // 3D効果のための光沢
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
