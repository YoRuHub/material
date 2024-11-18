import 'package:flutter/material.dart';

class DottedBorderPainter extends CustomPainter {
  final Color color;

  DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint..strokeCap = StrokeCap.round);

    // Create a dashed path
    final dashedPath = Path();
    for (int i = 0; i < size.width; i += 8) {
      dashedPath.addRect(Rect.fromLTWH(i.toDouble(), 0, 5, size.height));
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
