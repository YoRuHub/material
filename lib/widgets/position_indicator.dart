import 'package:flutter/material.dart';
import '../models/background.dart';

class PositionIndicator extends StatelessWidget {
  final Background background;

  const PositionIndicator({super.key, required this.background});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              'X: ${background.offset.dx.toStringAsFixed(2)}',
            ),
            Text(
              '  Y: ${background.offset.dy.toStringAsFixed(2)}',
            ),
            Text(
              '  Z: ${background.scale.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }
}
