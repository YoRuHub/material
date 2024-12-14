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

  NodeToolPainter({
    required this.ref,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final selectedNode = ref.read(nodeStateProvider).selectedNode;
    final scale = ref.read(screenProvider).scale;
    final offset = ref.read(screenProvider).offset;
    if (selectedNode != null) {
      // scaleとoffsetを考慮した中心座標
      final center = NodeOperations.transformPoint(
          selectedNode.position.x, selectedNode.position.y,
          scale: scale, offset: offset);

      // ホバー状態による色の透明度の変更
      final Paint paint = Paint()
        ..color = Theme.of(context).colorScheme.onSurface.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      // 扇形の半径（外側と内側）をscaleに応じて調整
      final double outerRadius =
          NodeConstants.defaultNodeRadius * 3 * scale; // 外側の半径
      final double innerRadius =
          NodeConstants.defaultNodeRadius * 1.5 * scale; // 内側の半径

      // 扇形の開始角度とスイープ角度（ラジアン単位）
      const double startAngle = -3.14 / 2;
      const double sweepAngle = 3.14 / 4;

      // 扇形の中心座標を計算
      double middleRadius = (outerRadius + innerRadius) / 2; // 半径の中間値
      const double centerAngle = startAngle + (sweepAngle / 2); // 扇形の中心角度
      final Offset arcCenter = Offset(
        center.dx + middleRadius * cos(centerAngle),
        center.dy + middleRadius * sin(centerAngle),
      );

      // Editアイコンを描画
      const IconData editIcon = Icons.edit; // 表示するアイコン
      final iconSize = 24.0 * scale; // アイコンサイズもscaleに応じて変更
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(editIcon.codePoint),
          style: TextStyle(
            fontSize: iconSize, // scaleを反映したアイコンサイズ
            fontFamily: editIcon.fontFamily,
            package: editIcon.fontPackage,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(arcCenter.dx - textPainter.width / 2,
              arcCenter.dy - textPainter.height / 2));

      // 輪っか状の扇形のパスを作成
      final Path path = Path()
        ..moveTo(center.dx + outerRadius * cos(startAngle),
            center.dy + outerRadius * sin(startAngle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius), // 外側の円
          startAngle, // 開始角度
          sweepAngle, // スイープ角度
          false,
        )
        ..lineTo(center.dx + innerRadius * cos(startAngle + sweepAngle),
            center.dy + innerRadius * sin(startAngle + sweepAngle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius), // 内側の円
          startAngle + sweepAngle, // 内側の開始角度
          -sweepAngle, // 内側は逆方向に弧を描く
          false,
        )
        ..close();

      // 輪っか状の扇形を描画
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
