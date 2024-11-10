import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class Node {
  vector_math.Vector3 position;
  vector_math.Vector3 velocity;
  vector_math.Vector3? _targetPosition;
  Color color;
  double radius;
  bool isActive;
  Node? parent;
  List<Node> children;

  Node(this.position, this.velocity, this.color, this.radius,
      {this.isActive = false, this.parent, List<Node>? children})
      : children = children ?? [];
}

class NodeAnimation3D extends StatefulWidget {
  const NodeAnimation3D({super.key});

  @override
  NodeAnimation3DState createState() => NodeAnimation3DState();
}

class NodeAnimation3DState extends State<NodeAnimation3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _signalAnimation;
  late List<Node> nodes;
  Node? _draggedNode;
  Node? _activeNode;
  double rotationX = 0;
  double rotationY = 0;
  double rotationZ = 0;
  double scale = 1.0;
  double _baseScale = 1.0;

  final double minDistance = 100.0;
  final double repulsionStrength = 0.0001;
  final double attractionStrength = 0.001;
  final double levelHeight = 150.0;
  final double nodeHorizontalSpacing = 150.0;
  bool isAligning = false;

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("3D Node Animation"),
        backgroundColor: Colors.black45,
      ),
      body: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            setState(() {
              final delta = pointerSignal.scrollDelta.dy;
              scale = (scale * (1 - delta / 500)).clamp(0.5, 3.0);
            });
          }
        },
        child: GestureDetector(
          onScaleStart: (details) {
            _baseScale = scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.pointerCount == 1) {
                rotationX += details.focalPointDelta.dy * 0.01;
                rotationY += details.focalPointDelta.dx * 0.01;
              } else {
                scale = (_baseScale * details.scale).clamp(0.5, 3.0);
              }
            });
          },
          onTapUp: (details) =>
              _handleTap(details.localPosition, context.size ?? Size.zero),
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    _updatePhysics();
                    return CustomPaint(
                      size: Size.infinite,
                      painter: NodePainter3D(
                        nodes,
                        _signalAnimation.value,
                        rotationX,
                        rotationY,
                        rotationZ,
                        scale,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _addNode,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue[900],
                      ),
                      child: const Text("Add Node"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: isAligning ? null : () => _alignNodes(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green[900],
                      ),
                      child: const Text("Align Nodes"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var matrix = vector_math.Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY)
      ..rotateZ(rotationZ);

    Node? closestNode;
    double closestDistance = double.infinity;

    for (var node in nodes) {
      var transformedPosition = matrix.transformed3(node.position);
      double perspectiveScale = 1000 / (1000 + transformedPosition.z);

      var nodeScreenPosition = Offset(
        center.dx + transformedPosition.x * perspectiveScale * scale,
        center.dy + transformedPosition.y * perspectiveScale * scale,
      );

      double distance = (position - nodeScreenPosition).distance;
      double scaledRadius = node.radius * perspectiveScale * scale;

      if (distance < scaledRadius && distance < closestDistance) {
        closestNode = node;
        closestDistance = distance;
      }
    }

    setState(() {
      for (var node in nodes) {
        node.isActive = false;
      }
      if (closestNode != null) {
        closestNode.isActive = true;
        _activeNode = closestNode;
      } else {
        _activeNode = null;
      }
    });
  }

  void _addNode() {
    setState(() {
      if (_activeNode != null) {
        int generation = _calculateGeneration(_activeNode!);
        Node childNode = Node(
          vector_math.Vector3(
            _activeNode!.position.x + (Random().nextDouble() - 0.5) * 100,
            _activeNode!.position.y + (Random().nextDouble() - 0.5) * 100,
            _activeNode!.position.z + (Random().nextDouble() - 0.5) * 100,
          ),
          vector_math.Vector3.zero(),
          _getColorForGeneration(generation + 1),
          20.0,
        );
        _activeNode!.children.add(childNode);
        childNode.parent = _activeNode;
        nodes.add(childNode);
      } else {
        nodes.add(Node(
          vector_math.Vector3(
            Random().nextDouble() * 400 - 200,
            Random().nextDouble() * 400 - 200,
            Random().nextDouble() * 400 - 200,
          ),
          vector_math.Vector3.zero(),
          _getColorForGeneration(0),
          20.0,
        ));
      }
    });
  }

  void _alignNodes(BuildContext context) async {
    if (nodes.isEmpty) return;

    setState(() {
      isAligning = true;
    });

    List<Node> rootNodes = nodes.where((node) => node.parent == null).toList();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double centerX = screenWidth / 2;
    const double startY = 100.0;

    for (int i = 0; i < rootNodes.length; i++) {
      double rootX = centerX +
          (i - (rootNodes.length - 1) / 2) * (nodeHorizontalSpacing * 2);
      _calculateTargetPositions(rootNodes[i], rootX, startY, screenWidth);
    }

    const int totalSteps = 60;
    for (int step = 0; step < totalSteps; step++) {
      for (var node in nodes) {
        if (node._targetPosition != null) {
          double progress = step / totalSteps;
          double easedProgress = _easeInOutCubic(progress);

          vector_math.Vector3 start = node.position;
          vector_math.Vector3 target = node._targetPosition!;
          node.position = vector_math.Vector3(
            start.x + (target.x - start.x) * easedProgress,
            start.y + (target.y - start.y) * easedProgress,
            start.z + (target.z - start.z) * easedProgress,
          );
        }
      }
      await Future.delayed(const Duration(milliseconds: 16));
      setState(() {});
    }

    setState(() {
      isAligning = false;
    });
  }

  void _calculateTargetPositions(
      Node node, double x, double y, double maxWidth) {
    node._targetPosition = vector_math.Vector3(x, y, 0);

    if (node.children.isEmpty) return;

    double totalWidth = (node.children.length - 1) * nodeHorizontalSpacing;
    double startX = x - totalWidth / 2;

    for (int i = 0; i < node.children.length; i++) {
      double childX = startX + i * nodeHorizontalSpacing;
      childX = childX.clamp(node.radius, maxWidth - node.radius);

      _calculateTargetPositions(
          node.children[i], childX, y + levelHeight, maxWidth);
    }
  }

  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  int _calculateGeneration(Node node) {
    int generation = 0;
    Node? current = node;
    while (current?.parent != null) {
      generation++;
      current = current?.parent;
    }
    return generation;
  }

  Color _getColorForGeneration(int generation) {
    double hue = (generation * 30) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
  }

  void _updatePhysics() {
    for (var node in nodes) {
      if (node == _draggedNode) continue;

      for (var otherNode in nodes) {
        if (node == otherNode) continue;

        vector_math.Vector3 direction = node.position - otherNode.position;
        double distance = direction.length;

        if (distance < minDistance) {
          vector_math.Vector3 normalizedDirection = direction.normalized();
          double repulsionMagnitude =
              (minDistance - distance) * repulsionStrength;

          node.velocity += normalizedDirection * repulsionMagnitude;
          otherNode.velocity -= normalizedDirection * repulsionMagnitude;
        }
      }

      node.position += node.velocity;
      node.velocity *= 0.95;
    }
  }
}

class NodePainter3D extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double scale;

  NodePainter3D(this.nodes, this.signalProgress, this.rotationX, this.rotationY,
      this.rotationZ, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var matrix = vector_math.Matrix4.identity()
      ..rotateX(rotationX)
      ..rotateY(rotationY)
      ..rotateZ(rotationZ);

    var sortedNodes = [...nodes];
    sortedNodes.sort((a, b) {
      var posA = matrix.transformed3(a.position);
      var posB = matrix.transformed3(b.position);
      return posB.z.compareTo(posA.z);
    });

    // Draw connections
    for (var node in sortedNodes) {
      if (node.parent != null) {
        var startPos = matrix.transformed3(node.parent!.position);
        var endPos = matrix.transformed3(node.position);

        double startScale = 1000 / (1000 + startPos.z);
        double endScale = 1000 / (1000 + endPos.z);

        final Offset start = Offset(
          center.dx + startPos.x * startScale * scale,
          center.dy + startPos.y * startScale * scale,
        );
        final Offset end = Offset(
          center.dx + endPos.x * endScale * scale,
          center.dy + endPos.y * endScale * scale,
        );

        // Main line
        final Paint linePaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(start, end, linePaint);

        // Signal effect
        final Paint signalPaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(Offset(signalX, signalY), 2, signalPaint);
      }
    }

    // Draw nodes
    for (var node in sortedNodes) {
      var transformedPosition = matrix.transformed3(node.position);
      double perspectiveScale = 1000 / (1000 + transformedPosition.z);
      double scaledRadius = node.radius * perspectiveScale * scale;

      final Offset center = Offset(
        size.width / 2 + transformedPosition.x * perspectiveScale * scale,
        size.height / 2 + transformedPosition.y * perspectiveScale * scale,
      );

      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = node.color.withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
        canvas.drawCircle(center, scaledRadius * 1.5, glowPaint);
      }

      final gradient = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.9),
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.5),
        ],
        stops: const [0.0, 0.3, 1.0],
      );

      final Paint nodePaint = Paint()
        ..shader = gradient
            .createShader(Rect.fromCircle(center: center, radius: scaledRadius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, scaledRadius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
