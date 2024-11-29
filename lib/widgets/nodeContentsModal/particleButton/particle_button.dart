import 'package:flutter/material.dart';
import 'dart:math';
import '/models/particle.dart';
import 'particle_painter.dart';

class ParticleButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;
  final double width;
  final double height;

  const ParticleButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.cyan,
    this.icon,
    this.width = 100.0, // デフォルトの幅
    this.height = 100.0, // デフォルトの高さ
  });

  @override
  ParticleButtonState createState() => ParticleButtonState();
}

class ParticleButtonState extends State<ParticleButton>
    with SingleTickerProviderStateMixin {
  final List<Particle> particles = [];
  bool isHovered = false;
  bool isDisintegrating = false;
  late AnimationController _controller;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )
      ..addListener(() {
        _updateParticles();
      })
      // アニメーション終了時にresetを呼び出す
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          reset();
          widget.onPressed(); // アニメーション完了後に遷移処理を呼び出す
        }
      });
  }

  void _createParticles(double width, double height) {
    particles.clear();
    // パーティクルの最大数を設定
    const int maxParticles = 10000; // 最大パーティクル数

    // パーティクル数を最大数に制限
    final particleCount =
        min(maxParticles, (width * height).toInt()); // 最大数と計算された数の小さい方を使用

    for (var i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final angle = random.nextDouble() * 2 * pi;
      final speed = 2.0 + random.nextDouble() * 3.0;

      particles.add(Particle(
        x: x,
        y: y,
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        size: 1,
        color: widget.color.withOpacity(0.8 + random.nextDouble() * 0.2),
      ));
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (var particle in particles) {
        // パーティクルの基本的な動き
        particle.x += particle.dx;
        particle.y += particle.dy;

        // 重力の影響を軽減
        particle.dy -= 0.03; // 重力を軽減

        // フェードアウトの速度を調整
        particle.size *= 0.98; // ここを小さくしてフェードアウトを遅くする
      }
    });
  }

  void reset() {
    if (!mounted) return;

    setState(() {
      isDisintegrating = false;
      isHovered = false;
      particles.clear();
      _controller.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          _createParticles(box.size.width, box.size.height);
        },
        onTap: () {
          setState(() {
            isDisintegrating = true;
          });

          _controller.forward(from: 0.0); // アニメーション開始
        },
        child: CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            progress: _controller.value,
            isHovered: isHovered,
            isDisintegrating: isDisintegrating,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: isDisintegrating ? 0.0 : 1.0,
            child: Container(
              width: widget.width, // 幅を設定
              height: widget.height, // 高さを設定
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.8),
                    blurRadius: 24.0,
                    spreadRadius: 8.0,
                    offset: const Offset(0, 0),
                  ),
                  if (isHovered)
                    BoxShadow(
                      color: widget.color.withOpacity(0.8),
                      blurRadius: 24.0,
                      spreadRadius: 8.0,
                      offset: const Offset(0, 0),
                    ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // アイコンとテキストがボタン内に収まるようにサイズを調整
                  double iconSize =
                      min(constraints.maxWidth, constraints.maxHeight) *
                          0.4; // アイコンの最大サイズをボタンサイズの40%
                  double fontSize =
                      min(constraints.maxWidth, constraints.maxHeight) *
                          0.15; // テキストサイズをボタンサイズの15%

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.icon != null)
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: iconSize, // アイコンのサイズを動的に設定
                        ),
                      if (widget.text.isNotEmpty)
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize, // テキストサイズを動的に設定
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
