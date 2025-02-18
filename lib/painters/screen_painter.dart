import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/screen_provider.dart';

class ScreenPainter extends CustomPainter {
  final WidgetRef ref;

  ScreenPainter(this.ref);

  @override
  void paint(Canvas canvas, Size size) {
    final isLinkMode = ref.read(screenProvider).isLinkMode;

    // リンクモードの場合、外枠に青色を適用
    if (isLinkMode) {
      final linkModePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.4, // グラデーションの範囲を少し広げる
          colors: [
            Colors.transparent, // 内側は透明
            Theme.of(ref.context).colorScheme.primary.withOpacity(0.6), // 中間
            Theme.of(ref.context).colorScheme.primary.withOpacity(0.3), // 外側
          ],
          stops: const [0.5, 0.8, 1.0], // グラデーションの開始と終了位置
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final shadowPaint = Paint()
        ..color = Theme.of(ref.context).colorScheme.primary.withOpacity(0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // ぼかし効果

      // 外枠をぼかしながら描画
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        shadowPaint, // ぼかしの影を描画
      );

      // グラデーションを外枠に描画
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        linkModePaint, // グラデーションを描画
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
