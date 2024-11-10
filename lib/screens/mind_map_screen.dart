import 'dart:collection';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class Node {
  vector_math.Vector2 position;
  vector_math.Vector2 velocity;
  vector_math.Vector2? _targetPosition;
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
  const NodeAnimation({super.key});

  @override
  NodeAnimationState createState() => NodeAnimationState();
}

class NodeAnimationState extends State<NodeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _signalAnimation;
  late List<Node> nodes;
  Node? _draggedNode;
  Node? _activeNode;
  static const double minDistance = 100.0;
  static const double repulsionStrength = 0.0001;
  static const double attractionStrength = 0.001;
  static const int totalSteps = 60;
  static const double initialDistanceThreshold = 100;
  static const double idealDistance = 100;
  static const double maxStrengthMultiplier = 0.1;

  static const double saturation = 0.7;
  static const double lightness = 0.6;
  static const double nodeHorizontalSpacing = 100.0;
  static const double levelHeight = 100.0;
  static const double alpha = 1.0;
  static const double hueShift = 20.0;
  static const double maxHue = 360.0;

  bool isAligning = false;

  Offset _offset = Offset.zero;
  Offset _offsetStart = Offset.zero; // 追加: ドラッグ開始時のオフセット
  Offset _dragStart = Offset.zero; // 追加: ドラッグ開始位置

  // ズームとパンの状態管理
  double _scale = 1.0;
  bool _isPanning = false;

  // ズーム制限
  static const double minScale = 0.1;
  static const double maxScale = 5.0;

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

  // スクリーン座標からワールド座標への変換
  vector_math.Vector2 screenToWorld(Offset screenPos) {
    return vector_math.Vector2(
      (screenPos.dx - _offset.dx) / _scale,
      (screenPos.dy - _offset.dy) / _scale,
    );
  }

  // ワールド座標からスクリーン座標への変換
  Offset worldToScreen(vector_math.Vector2 worldPos) {
    return Offset(
      worldPos.x * _scale + _offset.dx,
      worldPos.y * _scale + _offset.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Node Animation"),
        backgroundColor: Colors.black45,
      ),
      body: Stack(
        // StackをCenterの代わりに使用
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      setState(() {
                        double newScale = _scale;
                        if (pointerSignal.scrollDelta.dy > 0) {
                          newScale *= 0.95;
                        } else {
                          newScale *= 1.05;
                        }
                        _scale = newScale.clamp(minScale, maxScale);
                      });
                    }
                  },
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTapUp: _onTapUp,
                    onSecondaryTapDown: (details) {
                      setState(() {
                        _isPanning = true;
                      });
                    },
                    onSecondaryTapUp: (details) {
                      setState(() {
                        _isPanning = false;
                      });
                    },
                    onSecondaryTapCancel: () {
                      setState(() {
                        _isPanning = false;
                      });
                    },
                    onSecondaryLongPressMoveUpdate: (details) {
                      if (_isPanning) {
                        setState(() {
                          _offset += details.offsetFromOrigin;
                        });
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        _updatePhysics();
                        return CustomPaint(
                          size: Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height -
                                AppBar().preferredSize.height,
                          ),
                          painter: NodePainter(
                              nodes, _signalAnimation.value, _scale, _offset),
                        );
                      },
                    ),
                  ),
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
          // 座標表示を左上に配置
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'X: ${_offset.dx.toStringAsFixed(1)}\nY: ${_offset.dy.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

    for (int step = 0; step < totalSteps; step++) {
      for (var node in nodes) {
        if (node._targetPosition != null) {
          double progress = step / totalSteps;
          double easedProgress = _easeInOutCubic(progress);

          vector_math.Vector2 start = node.position;
          vector_math.Vector2 target = node._targetPosition!;
          node.position = vector_math.Vector2(
            start.x + (target.x - start.x) * easedProgress,
            start.y + (target.y - start.y) * easedProgress,
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
    node._targetPosition = vector_math.Vector2(x, y);

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

  void _addNode() {
    setState(() {
      if (_activeNode != null) {
        int generation = _calculateGeneration(_activeNode!);
        Node childNode = Node(
          vector_math.Vector2(
              _activeNode!.position.x + Random().nextDouble() * 100 - 50,
              _activeNode!.position.y + Random().nextDouble() * 100 - 50),
          vector_math.Vector2(0, 0),
          _getColorForGeneration(generation + 1),
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
          _getColorForGeneration(0),
          20.0,
        ));
      }
    });
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
    double hue = (generation * hueShift) % maxHue;
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness).toColor();
  }

  void _onPanStart(DragStartDetails details) {
    vector_math.Vector2 worldPos = screenToWorld(details.localPosition);

    // クリックした位置がノードに当たるかをチェック
    bool isNodeSelected = false;
    for (var node in nodes) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        // ノードがクリックされた場合、そのノードをドラッグ可能にする
        setState(() {
          _draggedNode = node; // ドラッグするノードを設定
          _isPanning = false; // 背景のドラッグではない
        });
        isNodeSelected = true;
        _checkForNodeSelection(worldPos);
        break;
      }
    }

    // ノードが選択されていない場合、背景のドラッグを開始
    if (!isNodeSelected) {
      setState(() {
        _isPanning = true;
        _offsetStart = _offset; // 現在のオフセットを記録
        _dragStart = details.localPosition; // ドラッグ開始位置を記録
        _draggedNode = null; // 背景ドラッグ時はノードを選択しない
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      // ノードが選択されている場合、そのノードを移動
      if (_activeNode == _draggedNode) {
        setState(() {
          vector_math.Vector2 worldPos = screenToWorld(details.localPosition);
          _draggedNode!.position = worldPos; // ノードの位置を更新
          _updateConnectedNodes(_draggedNode!); // ノード間の接続を更新
        });
      }
    } else if (_isPanning) {
      // ノードがアクティブでない場合、背景をドラッグして移動する
      setState(() {
        final dragDelta = details.localPosition - _dragStart;
        _offset = _offsetStart + dragDelta;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggedNode = null;
      _isPanning = false;
    });
  }

  void _onTapUp(TapUpDetails details) {
    vector_math.Vector2 worldPos = screenToWorld(details.localPosition);
    _checkForNodeSelection(worldPos);
  }

  void _checkForNodeSelection(vector_math.Vector2 worldPos) {
    // クリックした位置がノードに当たるかをチェック
    for (var node in nodes) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      // ノードを選択した場合
      if (distance < node.radius) {
        setState(() {
          // クリックしたノードをアクティブにする
          _activeNode?.isActive = false; // 前のノードを非アクティブにする（前のノードがあれば）

          node.isActive = true; // クリックしたノードをアクティブにする
          _activeNode = node; // アクティブなノードとして設定
          _draggedNode = node; // ドラッグするノードを設定
        });
        return;
      }
    }

    // ノードが選択されなかった場合
    setState(() {
      _activeNode?.isActive = false; // 前のノードを非アクティブにする
      _activeNode = null; // ノード選択を解除
    });
  }

  void _updateConnectedNodes(Node node) {
    Set<Node> connectedNodes = _findConnectedNodes(node);

    for (var connectedNode in connectedNodes) {
      if (connectedNode == node) continue;

      vector_math.Vector2 direction = node.position - connectedNode.position;
      double distance = direction.length;

      if (distance > initialDistanceThreshold) {
        vector_math.Vector2 targetPosition =
            node.position - direction.normalized() * idealDistance;

        double strengthMultiplier =
            (distance - initialDistanceThreshold) / idealDistance;
        strengthMultiplier = min(maxStrengthMultiplier, strengthMultiplier);

        vector_math.Vector2 movement =
            (targetPosition - connectedNode.position) *
                (attractionStrength * strengthMultiplier);

        connectedNode.velocity += movement;
      }
    }
  }

  Set<Node> _findConnectedNodes(Node startNode) {
    Set<Node> connectedNodes = {};
    Queue<Node> queue = Queue<Node>();
    queue.add(startNode);

    while (queue.isNotEmpty) {
      Node currentNode = queue.removeFirst();
      if (connectedNodes.contains(currentNode)) continue;

      connectedNodes.add(currentNode);

      for (var child in currentNode.children) {
        if (!connectedNodes.contains(child)) {
          queue.add(child);
        }
      }

      if (currentNode.parent != null &&
          !connectedNodes.contains(currentNode.parent)) {
        queue.add(currentNode.parent!);
      }

      if (currentNode.parent != null) {
        for (var sibling in currentNode.parent!.children) {
          if (!connectedNodes.contains(sibling)) {
            queue.add(sibling);
          }
        }
      }
    }

    return connectedNodes;
  }

  void _updatePhysics() {
    for (var node in nodes) {
      if (_draggedNode == node) continue;

      for (var otherNode in nodes) {
        if (node == otherNode) continue;

        double dx = node.position.x - otherNode.position.x;
        double dy = node.position.y - otherNode.position.y;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance < minDistance) {
          vector_math.Vector2 direction =
              vector_math.Vector2(dx, dy).normalized();
          double repulsionMagnitude =
              (minDistance - distance) * repulsionStrength;

          node.velocity += direction * repulsionMagnitude;
          otherNode.velocity -= direction * repulsionMagnitude;
        }
      }

      if (node.parent != null) {
        double dx = node.position.x - node.parent!.position.x;
        double dy = node.position.y - node.parent!.position.y;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance > 100) {
          vector_math.Vector2 direction =
              vector_math.Vector2(dx, dy).normalized();
          vector_math.Vector2 movement =
              direction * (distance - 100) * attractionStrength;
          node.position -= movement;
        }
      }

      node.position += node.velocity;
      node.velocity *= 0.95;
    }
  }
}

class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;
  final double scale;
  final Offset offset;

  NodePainter(this.nodes, this.signalProgress, this.scale, this.offset);

  // 座標変換のヘルパーメソッド
  Offset transformPoint(double x, double y) {
    return Offset(
      x * scale + offset.dx,
      y * scale + offset.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 接続線の描画
    for (var node in nodes) {
      if (node.parent != null) {
        final Paint linePaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..strokeWidth = 2 * scale // スケールに応じて線の太さを調整
          ..style = PaintingStyle.stroke
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, 2 * scale); // グロー効果もスケールに応じて調整

        final Offset start = transformPoint(
          node.parent!.position.x,
          node.parent!.position.y,
        );
        final Offset end = transformPoint(
          node.position.x,
          node.position.y,
        );

        // メインの線
        canvas.drawLine(start, end, linePaint);

        // 信号エフェクトの強度を交互に変える
        double opacity = 1 * (0.5 + 0.5 * sin(signalProgress * 3.14159 * 5));
        final Paint signalPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * scale);

        // 信号の位置も変換
        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(Offset(signalX, signalY), 2 * scale, signalPaint);
      }
    }

    // ノードの描画（細胞デザイン）
    for (var node in nodes) {
      final Offset center = transformPoint(node.position.x, node.position.y);
      final double scaledRadius = node.radius * scale;

      // 細胞膜の描画（グローの追加）
      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = node.color.withOpacity(0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
        canvas.drawCircle(center, scaledRadius * 1.8, glowPaint);
      }

      // 細胞膜の微細なテクスチャを追加
      final Paint texturePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 0.5 * scale;

      // 細胞膜に微細な模様
      for (double i = 0; i < 360; i += 15) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + scaledRadius * 1.5 * cos(angle);
        final double y1 = center.dy + scaledRadius * 1.5 * sin(angle);
        final double x2 = center.dx + scaledRadius * 1.6 * cos(angle);
        final double y2 = center.dy + scaledRadius * 1.6 * sin(angle);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), texturePaint);
      }

      // 細胞内部の描画（グラデーション）
      final gradient = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.2),
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final Paint spherePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: scaledRadius),
        );

      canvas.drawCircle(center, scaledRadius, spherePaint);

      // 細胞核をリアルに描画
      final double nucleusRadius = scaledRadius * 0.4;

      // 細胞核のグラデーション
      final nucleusGradient = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          node.color.withOpacity(0.9),
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final Paint nucleusGlowPaint = Paint()
        ..shader = nucleusGradient.createShader(
          Rect.fromCircle(center: center, radius: nucleusRadius),
        );
      canvas.drawCircle(center, nucleusRadius, nucleusGlowPaint);

      // 細胞核の表面テクスチャ
      final Paint nucleusTexturePaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..strokeWidth = 0.5 * scale;

      for (double i = 0; i < 360; i += 10) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + nucleusRadius * cos(angle);
        final double y1 = center.dy + nucleusRadius * sin(angle);
        final double x2 = center.dx + (nucleusRadius + 5 * scale) * cos(angle);
        final double y2 = center.dy + (nucleusRadius + 5 * scale) * sin(angle);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), nucleusTexturePaint);
      }

      // 光沢効果
      final Paint glossyPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale);

      canvas.drawCircle(center, nucleusRadius * 0.3, glossyPaint);

      // 陰影効果
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale);

      canvas.drawCircle(center, nucleusRadius * 0.4, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(NodePainter oldDelegate) {
    return true;
  }
}
