import 'dart:collection';
import 'dart:math';
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
  final double minDistance = 100.0;
  final double repulsionStrength = 0.0001;
  final double attractionStrength = 0.001; // 引力の強さを調整
  final double levelHeight = 100.0; // 階層間の垂直距離
  final double nodeHorizontalSpacing = 110.0; // ノード間の水平距離
  bool isAligning = false; // 整列中かどうかのフラグ

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
        title: const Text("Node Animation"),
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
    );
  }

  // ノードを整列させる処理
  void _alignNodes(BuildContext context) async {
    if (nodes.isEmpty) return;

    setState(() {
      isAligning = true;
    });

    // ルートノードを見つける（親がないノード）
    List<Node> rootNodes = nodes.where((node) => node.parent == null).toList();

    // 画面の中心を計算
    final double screenWidth = MediaQuery.of(context).size.width;
    final double centerX = screenWidth / 2;
    const double startY = 100.0; // 上部からの開始位置

    // 各ルートノードとその子孫の目標位置を計算
    for (int i = 0; i < rootNodes.length; i++) {
      double rootX = centerX +
          (i - (rootNodes.length - 1) / 2) * (nodeHorizontalSpacing * 2);
      _calculateTargetPositions(rootNodes[i], rootX, startY, screenWidth);
    }

    // アニメーションで位置を更新
    const int totalSteps = 60; // アニメーションのステップ数
    for (int step = 0; step < totalSteps; step++) {
      for (var node in nodes) {
        if (node._targetPosition != null) {
          double progress = step / totalSteps;
          // イージング関数を適用（滑らかな動き）
          double easedProgress = _easeInOutCubic(progress);

          vector_math.Vector2 start = node.position;
          vector_math.Vector2 target = node._targetPosition!;
          node.position = vector_math.Vector2(
            start.x + (target.x - start.x) * easedProgress,
            start.y + (target.y - start.y) * easedProgress,
          );
        }
      }

      // 短い待機時間を入れて、アニメーションをスムーズに
      await Future.delayed(const Duration(milliseconds: 16));
      setState(() {});
    }

    setState(() {
      isAligning = false;
    });
  }

  void _calculateTargetPositions(
      Node node, double x, double y, double maxWidth) {
    // このノードの目標位置を設定
    node._targetPosition = vector_math.Vector2(x, y);

    if (node.children.isEmpty) return;

    // 子ノードの水平方向の範囲を計算
    double totalWidth = (node.children.length - 1) * nodeHorizontalSpacing;
    double startX = x - totalWidth / 2;

    // 各子ノードの位置を計算
    for (int i = 0; i < node.children.length; i++) {
      double childX = startX + i * nodeHorizontalSpacing;
      // 画面端に近づきすぎないように調整
      childX = childX.clamp(node.radius, maxWidth - node.radius);

      _calculateTargetPositions(
          node.children[i], childX, y + levelHeight, maxWidth);
    }
  }

  // イージング関数
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  void _addNode() {
    setState(() {
      if (_activeNode != null) {
        // アクティブなノードの階層に応じて子ノードを作成
        int generation = _calculateGeneration(_activeNode!);
        Node childNode = Node(
          vector_math.Vector2(
              _activeNode!.position.x + Random().nextDouble() * 100 - 50,
              _activeNode!.position.y + Random().nextDouble() * 100 - 50),
          vector_math.Vector2(0, 0),
          _getColorForGeneration(generation + 1), // 次世代の色を取得
          20.0,
        );
        _activeNode!.children.add(childNode);
        childNode.parent = _activeNode;
        nodes.add(childNode);
      } else {
        // ルートノードとして親ノードを作成
        nodes.add(Node(
          vector_math.Vector2(Random().nextDouble() * 400 + 100,
              Random().nextDouble() * 400 + 100),
          vector_math.Vector2(0, 0),
          _getColorForGeneration(0), // 最初の世代の色
          20.0,
        ));
      }
    });
  }

// ノードの世代を計算するヘルパーメソッド
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
    // HSL色モデルの色相（Hue）は0〜360度で表現可能。世代ごとに10度ずつ色相をずらす。
    double hue = (generation * 10) % 360; // 世代ごとに異なる色相を設定
    double saturation = 0.7; // 彩度（Saturation）を一定に設定
    double lightness = 0.6; // 明度（Lightness）を一定に設定

    // HSLからColorに変換
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  void _onPanStart(DragStartDetails details) {
    _checkForNodeSelection(details.localPosition);
    if (_draggedNode != null) {}
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

// _updateConnectedNodesメソッドを以下のように変更します
  void _updateConnectedNodes(Node node) {
    // 関連するすべてのノードを探索
    Set<Node> connectedNodes = _findConnectedNodes(node);

    // 関連するすべてのノードに対して移動処理を適用
    for (var connectedNode in connectedNodes) {
      if (connectedNode == node) continue;

      vector_math.Vector2 direction = node.position - connectedNode.position;
      double distance = direction.length;

      // 一定距離以上離れている場合、追従させる
      if (distance > 150) {
        // 追従開始距離を150に設定
        vector_math.Vector2 targetPosition =
            node.position - direction.normalized() * 100; // 理想的な距離を100に設定

        // 距離に応じて追従の強さを調整
        double strengthMultiplier = (distance - 150) / 100; // 距離が離れるほど強く追従
        strengthMultiplier = min(0.1, strengthMultiplier); // 最大値を1.0に制限

        vector_math.Vector2 movement =
            (targetPosition - connectedNode.position) *
                (attractionStrength * strengthMultiplier);

        connectedNode.velocity += movement;
      }
    }
  }

// 関連するすべてのノードを見つけるためのヘルパーメソッドを追加
  Set<Node> _findConnectedNodes(Node startNode) {
    Set<Node> connectedNodes = {};
    Queue<Node> queue = Queue<Node>();
    queue.add(startNode);

    while (queue.isNotEmpty) {
      Node currentNode = queue.removeFirst();
      if (connectedNodes.contains(currentNode)) continue;

      connectedNodes.add(currentNode);

      // 子ノードを追加
      for (var child in currentNode.children) {
        if (!connectedNodes.contains(child)) {
          queue.add(child);
        }
      }

      // 親ノードを追加
      if (currentNode.parent != null &&
          !connectedNodes.contains(currentNode.parent)) {
        queue.add(currentNode.parent!);
      }

      // 同じ親を持つ兄弟ノードを追加
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

      // 親子ノード間の距離が離れすぎないように制御
      if (node.parent != null) {
        // 親ノードと子ノード間の距離を計算
        double dx = node.position.x - node.parent!.position.x;
        double dy = node.position.y - node.parent!.position.y;
        double distance = sqrt(dx * dx + dy * dy);

        // 親ノードと子ノードが離れすぎていた場合、近づける
        if (distance > 100) {
          // 近づける処理（親ノードに向かって移動）
          vector_math.Vector2 direction =
              vector_math.Vector2(dx, dy).normalized();
          vector_math.Vector2 movement =
              direction * (distance - 100) * 0.001; // 近づく強さを調整
          node.position -= movement;
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
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(Offset(signalX, signalY), 2, signalPaint);
      }
    }

    // ノードの描画（細胞デザイン）
    for (var node in nodes) {
      final Offset center = Offset(node.position.x, node.position.y);

      // 細胞膜の描画（グローの追加）
      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = node.color.withOpacity(0.9) // 色の明るさを強調
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawCircle(center, node.radius * 1.8, glowPaint); // 細胞膜を少し大きく
      }

      // 細胞膜の微細なテクスチャを追加
      final Paint texturePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 0.5;

      // 細胞膜に微細な模様（模様を繰り返し描画）
      for (double i = 0; i < 360; i += 15) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + node.radius * 1.5 * cos(angle);
        final double y1 = center.dy + node.radius * 1.5 * sin(angle);
        final double x2 = center.dx + node.radius * 1.6 * cos(angle);
        final double y2 = center.dy + node.radius * 1.6 * sin(angle);
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
          Rect.fromCircle(center: center, radius: node.radius),
        );

      canvas.drawCircle(center, node.radius, spherePaint);

      // 細胞核をリアルに描画（質感の追加）
      final double nucleusRadius = node.radius * 0.4; // 細胞核のサイズ

      // 2. 細胞核に立体感を持たせるためのグラデーション
      final nucleusGradient = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          node.color.withOpacity(0.9), // 中心が少し明るく
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.5), // 外側は少し暗く
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final Paint nucleusGlowPaint = Paint()
        ..shader = nucleusGradient.createShader(
          Rect.fromCircle(center: center, radius: nucleusRadius),
        );
      canvas.drawCircle(center, nucleusRadius, nucleusGlowPaint);

      // 3. 細胞核の表面にノイズを加える（質感）
      final Paint nucleusTexturePaint =
          Paint() // Renamed to 'nucleusTexturePaint'
            ..color = Colors.white.withOpacity(0.15)
            ..strokeWidth = 0.5;

      // 細胞核表面に細かなノイズを描画
      for (double i = 0; i < 360; i += 10) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + nucleusRadius * cos(angle);
        final double y1 = center.dy + nucleusRadius * sin(angle);
        final double x2 = center.dx + (nucleusRadius + 5) * cos(angle);
        final double y2 = center.dy + (nucleusRadius + 5) * sin(angle);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2),
            nucleusTexturePaint); // Use renamed variable
      }

      // 4. 光沢感の追加（反射効果）
      final Paint glossyPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      // 中央部分に反射を追加
      canvas.drawCircle(center, nucleusRadius * 0.3, glossyPaint);

      // 5. 陰影を追加（屈折感を表現）
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // 細胞核の下部に影を追加
      canvas.drawCircle(center, nucleusRadius * 0.4, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
