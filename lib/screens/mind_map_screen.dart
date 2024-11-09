import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class Node {
  vector_math.Vector2 position;
  vector_math.Vector2 velocity;
  Color color;
  double radius;
  bool isActive;
  Node? parent;
  List<Node> children;

  Node(this.position, this.velocity, this.color, this.radius,
      {this.isActive = false, this.parent, List<Node>? children})
      : children = children ?? [];
}

class NodeAnimation extends StatefulWidget {
  @override
  _NodeAnimationState createState() => _NodeAnimationState();
}

class _NodeAnimationState extends State<NodeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _signalAnimation;
  late List<Node> nodes;
  Node? _draggedNode;
  Node? _activeNode;
  late Offset _dragStartOffset;
  final double minDistance = 100.0;
  final double repulsionStrength = 0.0001;
  final double attractionStrength = 0.001; // 引力の強さを調整

  @override
  void initState() {
    super.initState();
    nodes = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _signalAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight =
        MediaQuery.of(context).size.height - AppBar().preferredSize.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Node Animation"),
        backgroundColor: Colors.black45,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapUp: _onTapUp,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    _updatePhysics(screenWidth, screenHeight);
                    return CustomPaint(
                      size: Size(screenWidth, screenHeight),
                      painter: NodePainter(nodes, _signalAnimation.value),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _addNode,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[900],
                ),
                child: Text("Add Node"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNode() {
    setState(() {
      if (_activeNode != null) {
        Node childNode = Node(
          vector_math.Vector2(
              _activeNode!.position.x + Random().nextDouble() * 100 - 50,
              _activeNode!.position.y + Random().nextDouble() * 100 - 50),
          vector_math.Vector2(0, 0),
          [Colors.blue, Colors.red, Colors.pink][Random().nextInt(3)],
          20.0,
        );
        _activeNode!.children.add(childNode);
        childNode.parent = _activeNode;
        nodes.add(childNode);
      } else {
        nodes.add(Node(
          vector_math.Vector2(Random().nextDouble() * 400 + 100,
              Random().nextDouble() * 400 + 100),
          vector_math.Vector2(0, 0),
          [Colors.blue, Colors.red, Colors.pink][Random().nextInt(3)],
          20.0,
        ));
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    _checkForNodeSelection(details.localPosition);
    if (_draggedNode != null) {
      _dragStartOffset = details.localPosition;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      setState(() {
        _draggedNode!.position = vector_math.Vector2(
          details.localPosition.dx,
          details.localPosition.dy,
        );
        _updateConnectedNodes(_draggedNode!);
      });
    }
  }

  void _updateConnectedNodes(Node node) {
    // 子ノードの更新
    for (var child in node.children) {
      vector_math.Vector2 direction = node.position - child.position;
      double distance = direction.length;

      if (distance > 200) {
        // 最小距離より離れている場合
        vector_math.Vector2 targetPosition =
            node.position - direction.normalized() * 100;
        vector_math.Vector2 movement =
            (targetPosition - child.position) * attractionStrength;
        child.velocity += movement;
      }
    }

    // 親ノードの更新
    if (node.parent != null) {
      vector_math.Vector2 direction = node.position - node.parent!.position;
      double distance = direction.length;

      if (distance > 200) {
        vector_math.Vector2 targetPosition =
            node.position - direction.normalized() * 100;
        vector_math.Vector2 movement =
            (targetPosition - node.parent!.position) * attractionStrength;
        node.parent!.velocity += movement;
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggedNode = null;
    });
  }

  void _onTapUp(TapUpDetails details) {
    _checkForNodeSelection(details.localPosition);
  }

  void _checkForNodeSelection(Offset localPosition) {
    for (var node in nodes) {
      double dx = node.position.x - localPosition.dx;
      double dy = node.position.y - localPosition.dy;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        setState(() {
          _activeNode?.isActive = false;
          node.isActive = true;
          _activeNode = node;
          _draggedNode = node;
        });
        return;
      }
    }

    setState(() {
      _activeNode?.isActive = false;
      _activeNode = null;
    });
  }

  void _updatePhysics(double screenWidth, double screenHeight) {
    for (var node in nodes) {
      if (_draggedNode == node) continue;

      // ノード間の反発力を計算
      for (var otherNode in nodes) {
        if (node == otherNode) continue;

        double dx = node.position.x - otherNode.position.x;
        double dy = node.position.y - otherNode.position.y;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance < minDistance) {
          // ノードが近すぎる場合、反発力を加える
          vector_math.Vector2 direction =
              vector_math.Vector2(dx, dy).normalized();
          double repulsionMagnitude =
              (minDistance - distance) * repulsionStrength;

          // 反発力をノードの速度に加える
          node.velocity += direction * repulsionMagnitude;
          otherNode.velocity -= direction * repulsionMagnitude;
        }
      }

      // 速度の更新
      node.position += node.velocity;

      // 減衰（摩擦）
      node.velocity *= 0.95;

      // 画面端での跳ね返り
      if (node.position.x < node.radius) {
        node.position.x = node.radius;
        node.velocity.x *= -0.5;
      }
      if (node.position.x > screenWidth - node.radius) {
        node.position.x = screenWidth - node.radius;
        node.velocity.x *= -0.5;
      }
      if (node.position.y < node.radius) {
        node.position.y = node.radius;
        node.velocity.y *= -0.5;
      }
      if (node.position.y > screenHeight - node.radius) {
        node.position.y = screenHeight - node.radius;
        node.velocity.y *= -0.5;
      }
    }
  }
}

class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;

  NodePainter(this.nodes, this.signalProgress);

  @override
  void paint(Canvas canvas, Size size) {
    // 接続線の描画
    for (var node in nodes) {
      if (node.parent != null) {
        final Paint linePaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final Offset start =
            Offset(node.parent!.position.x, node.parent!.position.y);
        final Offset end = Offset(node.position.x, node.position.y);

        // メインの線
        canvas.drawLine(start, end, linePaint);

        // 信号エフェクト
        final Paint signalPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(Offset(signalX, signalY), 2, signalPaint);
      }
    }

    // ノードの描画
    for (var node in nodes) {
      final Offset center = Offset(node.position.x, node.position.y);

      // グロー効果
      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = node.color.withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);
        canvas.drawCircle(center, node.radius * 1.5, glowPaint);
      }

      // メインの球体
      final gradient = RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.9),
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.5),
        ],
        stops: [0.0, 0.3, 1.0],
      );

      final Paint spherePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: node.radius),
        );

      canvas.drawCircle(center, node.radius, spherePaint);

      // ハイライト
      final Paint highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(center.dx - node.radius * 0.3, center.dy - node.radius * 0.3),
        node.radius * 0.2,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
