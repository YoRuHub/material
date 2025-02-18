import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/node_constants.dart';
import '../models/node_tool_widget.dart';
import '../providers/node_state_provider.dart';
import '../utils/node_operations.dart';

class NodeToolPainter extends CustomPainter {
  final WidgetRef ref;
  final BuildContext context;
  final NodeToolWidget toolWidget;

  NodeToolPainter({
    required this.ref,
    required this.context,
    required this.toolWidget,
  });

  // 共通の角度計算メソッドを追加
  ({double startAngle, double endAngle}) _calculateAngles() {
    const double sweepAngle = pi / 4; // 扇形のスイープ角度
    const int totalTools = 8; // 仮に最大8ツールで円形に分割する
    const double baseAngle = -pi / 2; // 真上からスタート

    // idに基づいて角度を調整
    const double anglePerTool = 2 * pi / totalTools;
    final double startAngle = baseAngle + toolWidget.id * anglePerTool;
    final double endAngle = startAngle + sweepAngle;

    return (startAngle: startAngle, endAngle: endAngle);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final selectedNode = ref.read(nodeStateProvider).selectedNode;
    if (selectedNode == null) return;

    final scale = ref.read(screenProvider).scale;
    final offset = ref.read(screenProvider).offset;

    // scaleとoffsetを考慮した中心座標
    final center = NodeOperations.transformPoint(
        selectedNode.position.x, selectedNode.position.y,
        scale: scale, offset: offset);

    final double outerRadius = NodeConstants.defaultNodeRadius * 2.5 * scale;
    final double innerRadius = NodeConstants.defaultNodeRadius * 1.5 * scale;

    // 扇形の描画
    final Paint fillPaint = Paint()
      ..color = toolWidget.toolColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = toolWidget.toolColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // 境界線の太さを設定

    final angles = _calculateAngles();
    _drawArc(canvas, center, outerRadius, innerRadius, angles.startAngle,
        angles.endAngle, fillPaint, borderPaint);

    // アイコンの描画
    final double middleRadius = (outerRadius + innerRadius) / 2;
    final double centerAngle =
        angles.startAngle + (angles.endAngle - angles.startAngle) / 2;
    final Offset arcCenter = Offset(
      center.dx + middleRadius * cos(centerAngle),
      center.dy + middleRadius * sin(centerAngle),
    );
    _drawIcon(canvas, arcCenter, toolWidget.icon, scale);
  }

  void _drawIcon(Canvas canvas, Offset position, IconData icon, double scale) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24.0 * scale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawArc(
      Canvas canvas,
      Offset center,
      double outerRadius,
      double innerRadius,
      double startAngle,
      double endAngle,
      Paint fillPaint,
      Paint borderPaint) {
    final Path path = Path()
      ..moveTo(center.dx + outerRadius * cos(startAngle),
          center.dy + outerRadius * sin(startAngle))
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        endAngle - startAngle,
        false,
      )
      ..lineTo(center.dx + innerRadius * cos(endAngle),
          center.dy + innerRadius * sin(endAngle))
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle,
        startAngle - endAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  // isTappedメソッドを追加
  NodeToolWidget? isTapped(Offset tapPosition) {
    final selectedNode = ref.read(nodeStateProvider).selectedNode;
    if (selectedNode == null) return null;

    final scale = ref.read(screenProvider).scale;
    final offset = ref.read(screenProvider).offset;

    // タップ位置をスクリーン座標系からノード座標系に変換
    final transformedTapPosition = NodeOperations.transformPoint(
        tapPosition.dx, tapPosition.dy,
        scale: scale, offset: offset);

    final center = NodeOperations.transformPoint(
        selectedNode.position.x, selectedNode.position.y,
        scale: scale, offset: offset);

    final double outerRadius = NodeConstants.defaultNodeRadius * 2.5 * scale;
    final double innerRadius = NodeConstants.defaultNodeRadius * 1.5 * scale;

    final angles = _calculateAngles();

    // タップ位置とノード中心点の相対座標を計算
    final dx = transformedTapPosition.dx - center.dx;
    final dy = transformedTapPosition.dy - center.dy;

    // 距離を計算
    final distance = sqrt(dx * dx + dy * dy);

    // 角度を計算（-πからπの範囲）
    final tapAngle = atan2(dy, dx);

    // 半径と角度の範囲を確認
    if (distance >= innerRadius && distance <= outerRadius) {
      if (tapAngle >= angles.startAngle && tapAngle <= angles.endAngle) {
        return toolWidget;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
