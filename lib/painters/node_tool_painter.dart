import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/node_constants.dart';
import '../providers/node_state_provider.dart';
import '../utils/node_operations.dart';

class NodeToolPainter extends CustomPainter {
  final WidgetRef ref;
  final BuildContext context;
  final String tool;

  NodeToolPainter({
    required this.ref,
    required this.context,
    required this.tool,
  });

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

    const double sweepAngle = pi / 4; // 扇形のスイープ角度

    // 'add'の時には角度をずらす
    final double startAngle = tool == 'add' ? -pi / 2 + sweepAngle : -pi / 2;

    // 扇形の描画

    // 塗りつぶしのペイント
    final Paint fillPaint = Paint()
      ..color = Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 境界線のペイント
    final Paint borderPaint = Paint()
      ..color = Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1; // 境界線の太さを設定

    _drawArc(canvas, center, outerRadius, innerRadius, startAngle, sweepAngle,
        fillPaint, borderPaint);

    // アイコンの描画
    final double middleRadius = (outerRadius + innerRadius) / 2;
    final double centerAngle = startAngle + sweepAngle / 2;
    final Offset arcCenter = Offset(
      center.dx + middleRadius * cos(centerAngle),
      center.dy + middleRadius * sin(centerAngle),
    );
    final IconData currentIcon = tool == 'add' ? Icons.add : Icons.edit;
    _drawIcon(canvas, arcCenter, currentIcon, scale);
  }

  void _drawIcon(Canvas canvas, Offset position, IconData icon, double scale) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24.0 * scale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Theme.of(context).colorScheme.onSurface,
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
      double sweepAngle,
      Paint fillPaint,
      Paint borderPaint) {
    // 塗りつぶしのパス
    final Path path = Path()
      ..moveTo(center.dx + outerRadius * cos(startAngle),
          center.dy + outerRadius * sin(startAngle))
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      )
      ..lineTo(center.dx + innerRadius * cos(startAngle + sweepAngle),
          center.dy + innerRadius * sin(startAngle + sweepAngle))
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();

    // 扇形の塗りつぶし
    canvas.drawPath(path, fillPaint);

    // 扇形の境界線
    canvas.drawPath(path, borderPaint);
  }

// タップ判定のロジック
  String isTapped(Offset tapPosition) {
    final selectedNode = ref.read(nodeStateProvider).selectedNode;
    if (selectedNode == null) return ''; // 選択されていない場合は空文字を返す

    final scale = ref.read(screenProvider).scale;
    final offset = ref.read(screenProvider).offset;

    final center = NodeOperations.transformPoint(
        selectedNode.position.x, selectedNode.position.y,
        scale: scale, offset: offset);

    final double outerRadius = NodeConstants.defaultNodeRadius * 2.5 * scale;
    final double innerRadius = NodeConstants.defaultNodeRadius * 1.5 * scale;

    const double sweepAngle = pi / 4; // 扇形のスイープ角度

    // 'add' と 'edit' のパスを一つの関数で判定
    String checkAreaTapped(double startAngle) {
      final Path path = Path()
        ..moveTo(center.dx + outerRadius * cos(startAngle),
            center.dy + outerRadius * sin(startAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius),
            startAngle, sweepAngle, false)
        ..lineTo(center.dx + innerRadius * cos(startAngle + sweepAngle),
            center.dy + innerRadius * sin(startAngle + sweepAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: innerRadius),
            startAngle + sweepAngle, -sweepAngle, false)
        ..close();

      return path.contains(tapPosition)
          ? (startAngle == -pi / 2 ? 'edit' : 'add')
          : '';
    }

    // 'add' と 'edit' のタップ判定
    final addAreaTapped = checkAreaTapped(-pi / 2 + sweepAngle);
    if (addAreaTapped.isNotEmpty) return addAreaTapped;

    final editAreaTapped = checkAreaTapped(-pi / 2);
    if (editAreaTapped.isNotEmpty) return editAreaTapped;

    return ''; // どちらにも当たらない場合
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
