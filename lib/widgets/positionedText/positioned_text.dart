import 'package:flutter/material.dart';

class PositionedText extends StatelessWidget {
  final double offsetX;
  final double offsetY;
  final double scaleZ;

  const PositionedText({
    super.key,
    required this.offsetX,
    required this.offsetY,
    required this.scaleZ,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          'X: ${offsetX.toStringAsFixed(1)}, Y: ${offsetY.toStringAsFixed(1)}, Z: ${scaleZ.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
