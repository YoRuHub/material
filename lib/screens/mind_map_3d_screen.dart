import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class MindMapScreens extends StatefulWidget {
  const MindMapScreens({super.key});

  @override
  State<MindMapScreens> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreens>
    with SingleTickerProviderStateMixin {
  Vector3 _cameraPosition = Vector3(0, 0, -500); // 初期カメラ位置を調整
  Vector3 _cameraRotation = Vector3(0, 0, 0);
  double _zoomLevel = 1.0;
  Offset _lastPosition = Offset.zero;
  bool _isDragging = false;

  // アニメーション用のコントローラー
  late AnimationController _animationController;
  Vector3 _velocityVector = Vector3(0, 0, 0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePosition);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePosition() {
    if (!_isDragging && _velocityVector.length > 0.1) {
      setState(() {
        _cameraPosition += _velocityVector;
        _velocityVector *= 0.95; // 減衰
      });
    }
  }

  void _handleMouseDown(PointerDownEvent event) {
    _isDragging = true;
    _lastPosition = event.position;
    _animationController.stop();
  }

  void _handleMouseMove(PointerMoveEvent event) {
    if (!_isDragging) return;

    final delta = event.position - _lastPosition;
    // マウスの移動量に基づいて移動速度を調整
    final moveSpeed = 0.5 * _zoomLevel;

    setState(() {
      _cameraPosition += Vector3(
        -delta.dx * moveSpeed,
        -delta.dy * moveSpeed,
        0,
      );

      // 回転も追加（オプション）
      _cameraRotation += Vector3(
        -delta.dy * 0.001,
        -delta.dx * 0.001,
        0,
      );

      // 速度ベクトルを更新
      _velocityVector = Vector3(
        -delta.dx * moveSpeed * 0.1,
        -delta.dy * moveSpeed * 0.1,
        0,
      );
    });

    _lastPosition = event.position;
  }

  void _handleMouseUp(PointerUpEvent event) {
    _isDragging = false;
    _animationController.reset();
    _animationController.forward();
  }

  void _handleMouseWheel(PointerScrollEvent event) {
    final zoomDelta = event.scrollDelta.dy * 0.001;
    setState(() {
      _zoomLevel = (_zoomLevel * (1 - zoomDelta)).clamp(0.1, 5.0);
      _cameraPosition += Vector3(0, 0, event.scrollDelta.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive 3D Space'),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: _handleMouseDown,
            onPointerMove: _handleMouseMove,
            onPointerUp: _handleMouseUp,
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _handleMouseWheel(event);
              }
            },
            child: CustomPaint(
              painter: EnhancedStarFieldPainter(
                cameraPosition: _cameraPosition,
                cameraRotation: _cameraRotation,
                zoomLevel: _zoomLevel,
              ),
              size: Size.infinite,
            ),
          ),
          // HUD表示
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '航行データ',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '位置:\n'
                    'X: ${_cameraPosition.x.toStringAsFixed(1)}\n'
                    'Y: ${_cameraPosition.y.toStringAsFixed(1)}\n'
                    'Z: ${_cameraPosition.z.toStringAsFixed(1)}\n'
                    '回転: ${(_cameraRotation.y * 180 / pi).toStringAsFixed(1)}°\n'
                    'ズーム: ${_zoomLevel.toStringAsFixed(2)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 操作ガイド
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '操作方法',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ドラッグ: 空間移動\n'
                    'マウスホイール: ズーム\n'
                    'ドラッグ解放: 慣性移動',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedStarFieldPainter extends CustomPainter {
  final Vector3 cameraPosition;
  final Vector3 cameraRotation;
  final double zoomLevel;
  final List<Star> stars;
  final List<Star> nebulas;
  static const int starCount = 1000;
  static const int nebulaCount = 5;

  EnhancedStarFieldPainter({
    required this.cameraPosition,
    required this.cameraRotation,
    required this.zoomLevel,
  })  : stars = [],
        nebulas = [] {
    final random = Random();

    // 星雲の生成
    for (int i = 0; i < nebulaCount; i++) {
      nebulas.add(Star(
        position: Vector3(
          (random.nextDouble() - 0.5) * 4000,
          (random.nextDouble() - 0.5) * 4000,
          (random.nextDouble() - 0.5) * 2000,
        ),
        brightness: random.nextDouble() * 0.5 + 0.5,
        color: HSLColor.fromAHSL(
          1.0,
          random.nextDouble() * 360,
          0.8,
          0.6,
        ).toColor(),
        size: random.nextDouble() * 300 + 200,
      ));
    }

    // 恒星の生成
    for (int i = 0; i < starCount; i++) {
      final temp = random.nextDouble();
      final color = _getStarColor(temp);
      stars.add(Star(
        position: Vector3(
          (random.nextDouble() - 0.5) * 4000,
          (random.nextDouble() - 0.5) * 4000,
          (random.nextDouble() - 0.5) * 2000,
        ),
        brightness: random.nextDouble() * 0.5 + 0.5,
        color: color,
        size: random.nextDouble() * 3 + 1,
      ));
    }
  }

  Color _getStarColor(double temperature) {
    if (temperature < 0.2) return Colors.red[300]!;
    if (temperature < 0.4) return Colors.orange[300]!;
    if (temperature < 0.6) return Colors.white;
    if (temperature < 0.8) return Colors.blue[200]!;
    return Colors.blue[100]!;
  }

  Vector3 _rotatePoint(Vector3 point) {
    final dx = point.x;
    final dy = point.y;
    final dz = point.z;

    // Y軸回転
    final rotY = cameraRotation.y;
    final cosY = cos(rotY);
    final sinY = sin(rotY);

    final x = dx * cosY - dz * sinY;
    final z = dx * sinY + dz * cosY;

    return Vector3(x, dy, z);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 星雲の描画
    for (final nebula in nebulas) {
      final relativePos = nebula.position - cameraPosition;
      final rotatedPos = _rotatePoint(relativePos);
      final scale = 2000 / (2000 + rotatedPos.z.abs());

      final screenX = centerX + rotatedPos.x * scale * zoomLevel;
      final screenY = centerY + rotatedPos.y * scale * zoomLevel;

      if (_isInScreen(screenX, screenY, size)) {
        final paint = Paint()
          ..color = nebula.color.withOpacity(0.1 * scale)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

        canvas.drawCircle(
          Offset(screenX, screenY),
          nebula.size * scale * zoomLevel,
          paint,
        );
      }
    }

    // 恒星の描画
    for (final star in stars) {
      final relativePos = star.position - cameraPosition;
      final rotatedPos = _rotatePoint(relativePos);
      final scale = 2000 / (2000 + rotatedPos.z.abs());

      final screenX = centerX + rotatedPos.x * scale * zoomLevel;
      final screenY = centerY + rotatedPos.y * scale * zoomLevel;

      if (_isInScreen(screenX, screenY, size)) {
        final paint = Paint()
          ..color = star.color.withOpacity(scale)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

        // 星本体の描画
        canvas.drawCircle(
          Offset(screenX, screenY),
          star.size * scale * zoomLevel,
          paint,
        );

        // 光芒効果
        if (star.brightness > 0.8) {
          paint.color = star.color.withOpacity(0.3 * scale);
          canvas.drawCircle(
            Offset(screenX, screenY),
            star.size * 2 * scale * zoomLevel,
            paint,
          );
        }
      }
    }
  }

  bool _isInScreen(double x, double y, Size size) {
    return x >= -100 &&
        x <= size.width + 100 &&
        y >= -100 &&
        y <= size.height + 100;
  }

  @override
  bool shouldRepaint(covariant EnhancedStarFieldPainter oldDelegate) {
    return oldDelegate.cameraPosition != cameraPosition ||
        oldDelegate.cameraRotation != cameraRotation ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}

class Star {
  final Vector3 position;
  final double brightness;
  final Color color;
  final double size;

  Star({
    required this.position,
    required this.brightness,
    this.color = Colors.white,
    this.size = 1.0,
  });
}
