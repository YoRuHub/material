import 'package:flutter/material.dart';
import '/models/particle.dart';

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final bool isHovered;
  final bool isDisintegrating;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isHovered,
    required this.isDisintegrating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}