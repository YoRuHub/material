import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class Node {
  vector_math.Vector2 position;
  vector_math.Vector2 velocity;
  Color color;
  double radius;
  bool isActive;
  Node? parent; // 親ノード
  List<Node> children; // 子ノードのリスト

  Node(this.position, this.velocity, this.color, this.radius,
      {this.isActive = false, this.parent, List<Node>? children})
      : children = children ?? []; // children が null の場合は空のリスト
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
  Node? _draggedNode; // 現在ドラッグされているノード
  Node? _activeNode; // 現在アクティブなノード
  late Offset _dragStartOffset; // ドラッグ開始位置
  final double minDistance = 100.0; // ノード間の最小距離
  final double repulsionStrength = 0.0001; // 反発力の強さ

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
      appBar: AppBar(
        title: Text("Node Animation"),
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
                onTapUp: _onTapUp, // クリック時のイベント
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
            ElevatedButton(
              onPressed: _addNode,
              child: Text("Add Node"),
            ),
          ],
        ),
      ),
    );
  }

  // ノードを追加する関数（アクティブノードがあるときに子ノードを追加）
  void _addNode() {
    setState(() {
      if (_activeNode != null) {
        // 親ノードがアクティブな場合、子ノードを追加
        Node childNode = Node(
          vector_math.Vector2(
              Random().nextDouble() * 200, Random().nextDouble() * 200),
          vector_math.Vector2(
            Random().nextDouble() * 2 - 1, // ランダムなX方向の速度
            Random().nextDouble() * 2 - 1, // ランダムなY方向の速度
          ),
          Colors.primaries[Random().nextInt(Colors.primaries.length)],
          10.0,
        );
        _activeNode!.children.add(childNode);
        childNode.parent = _activeNode;
        nodes.add(childNode);
      } else {
        // アクティブノードがない場合、通常のノードを追加
        nodes.add(Node(
          vector_math.Vector2(
              Random().nextDouble() * 200, Random().nextDouble() * 200),
          vector_math.Vector2(
            Random().nextDouble() * 2 - 1, // ランダムなX方向の速度
            Random().nextDouble() * 2 - 1, // ランダムなY方向の速度
          ),
          Colors.primaries[Random().nextInt(Colors.primaries.length)],
          10.0,
        ));
      }
    });
  }

  // ドラッグ開始時の処理
  void _onPanStart(DragStartDetails details) {
    _checkForNodeSelection(details.localPosition);
    if (_draggedNode != null) {
      _dragStartOffset = details.localPosition -
          Offset(_draggedNode!.position.x, _draggedNode!.position.y);
    }
  }

  // ドラッグ中の位置更新

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      setState(() {
        // 親ノードと子ノードを一緒に動かす
        _moveNodeAndChildren(
          _draggedNode!,
          details.localPosition,
          isParent: true, // 親ノードを動かすフラグを設定
        );
      });
    }
  }

  // ドラッグ終了時の処理
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggedNode = null; // ドラッグが終了したのでノードの選択を解除
    });
  }

  // クリック時の処理
  void _onTapUp(TapUpDetails details) {
    _checkForNodeSelection(details.localPosition);
    if (_activeNode == null) {
      setState(() {
        // ノード以外をクリックした場合、アクティブ状態を解除
        _activeNode?.isActive = false;
      });
    }
  }

  // ノード選択を判断して、選ばれているノードを記録する
  void _checkForNodeSelection(Offset localPosition) {
    bool clickedOnNode = false;

    for (var node in nodes) {
      double dx = node.position.x - localPosition.dx;
      double dy = node.position.y - localPosition.dy;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        setState(() {
          // すでにアクティブなノードがあれば非アクティブ化
          _activeNode?.isActive = false;
          // クリックしたノードをアクティブ化
          node.isActive = true;
          _activeNode = node; // アクティブなノードを設定
          _draggedNode = node; // クリックしたノードをドラッグ対象に設定
        });
        clickedOnNode = true;
        break;
      }
    }

    if (!clickedOnNode) {
      // ノード以外をクリックした場合、アクティブ状態を解除
      setState(() {
        _activeNode?.isActive = false;
        _activeNode = null;
      });
    }
  }

// ノードとその親子ノードを移動させる
// ノードとその子ノードを動かす関数
  void _moveNodeAndChildren(Node node, Offset localPosition,
      {bool isParent = false}) {
    final dx = localPosition.dx - _dragStartOffset.dx;
    final dy = localPosition.dy - _dragStartOffset.dy;

    // NaNチェック: NaNが含まれていないか確認
    if (dx.isNaN || dy.isNaN) {
      return; // NaNが含まれていた場合は処理を行わない
    }

    // 親ノードの場合は、位置を更新
    if (isParent) {
      node.position = vector_math.Vector2(dx, dy);
    }

    // 子ノードが親ノードに近づく処理（親が動いている場合）
    for (var child in node.children) {
      _moveNodeAndChildren(child, localPosition, isParent: false);

      // 子ノードが移動した場合、親ノードもそれに従って動かす
      if (child.position != localPosition) {
        _moveParentWithChild(child, node);
      }

      // 親ノードに近づく処理
      _attractChildToParent(child, node);
    }
  }

// 子ノードを移動させたときに親ノードを動かす処理
  void _moveParentWithChild(Node child, Node parent) {
    // 親ノードと子ノードの相対位置を計算
    vector_math.Vector2 direction = child.position - parent.position;

    // 親ノードが動くべき方向と距離を計算
    double moveDistance = direction.length;

    // 親ノードを子ノードの動きに従わせる（親ノードが動きます）
    if (moveDistance > 1) {
      vector_math.Vector2 moveDirection = direction.normalized();
      parent.position += moveDirection * moveDistance * 0.1; // 親ノードを少しずつ動かす
    }
  }

// 親ノードと子ノードがゆっくり近づくようにするための関数
  void _attractChildToParent(Node child, Node parent) {
    // 親ノードと子ノードの位置ベクトルを取得
    vector_math.Vector2 direction = parent.position - child.position;
    double distance = direction.length;

    // 親と子ノードがある程度近づいていない場合のみ調整
    if (distance > 20) {
      // 近づく距離の閾値
      // 親ノードに引き寄せられる力を加える
      vector_math.Vector2 attraction =
          direction.normalized() * 0.01; // 引き寄せ力を設定
      child.velocity += attraction;
    }
  }

  // 物理演算の更新
  void _updatePhysics(double screenWidth, double screenHeight) {
    for (int i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (_draggedNode != null && _draggedNode == node) {
        continue; // ドラッグ中のノードは物理演算を行わない
      }

      _checkBoundaryCollision(node, screenWidth, screenHeight);
      for (int j = i + 1; j < nodes.length; j++) {
        var otherNode = nodes[j];
        _checkNodeRepulsion(node, otherNode);
      }

      // 親子ノード間の距離をゆっくりと調整
      _adjustParentChildDistance(node);

      node.position += node.velocity;
      node.velocity *= 0.98; // 摩擦で減速
    }
  }

  // 画面の端との衝突
  void _checkBoundaryCollision(
      Node node, double screenWidth, double screenHeight) {
    if (node.position.x < node.radius ||
        node.position.x > screenWidth - node.radius) {
      node.velocity.x *= -1;
    }
    if (node.position.y < node.radius ||
        node.position.y > screenHeight - node.radius) {
      node.velocity.y *= -1;
    }
  }

  // ノード間の反発力
  void _checkNodeRepulsion(Node node, Node otherNode) {
    vector_math.Vector2 direction = node.position - otherNode.position;
    double distance = direction.length;
    if (distance < minDistance) {
      vector_math.Vector2 repulsion =
          direction.normalized() * (repulsionStrength / (distance * distance));
      node.velocity += repulsion;
      otherNode.velocity -= repulsion;
    }
  }

  // 親子ノード間の距離調整
  void _adjustParentChildDistance(Node node) {
    if (node.parent != null) {
      var parentPosition = node.parent!.position;
      var direction = node.position - parentPosition;
      var distance = direction.length;
      if (distance > 200) {
        // 距離が200以上になった場合に調整
        node.velocity -= direction.normalized() * 0.01;
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
    // 親子間のライン描画
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 1;

    for (var node in nodes) {
      if (node.parent != null) {
        final offset1 =
            Offset(node.parent!.position.x, node.parent!.position.y);
        final offset2 = Offset(node.position.x, node.position.y);

        // 信号として光が線上を移動
        Offset signalOffset = Offset(
          offset1.dx + (offset2.dx - offset1.dx) * signalProgress,
          offset1.dy + (offset2.dy - offset1.dy) * signalProgress,
        );

        // 線を描画
        canvas.drawLine(offset1, offset2, linePaint);
        // 信号の動きをオレンジの円で表現
        canvas.drawCircle(signalOffset, 3, linePaint..color = Colors.orange);
      }
    }

    // ノード（球体）を描画
    for (var node in nodes) {
      final Offset nodeCenter = Offset(node.position.x, node.position.y);

      // ノードの光沢を表現するためのグラデーション
      final RadialGradient gradient = RadialGradient(
        colors: [
          node.isActive ? Colors.white : node.color.withOpacity(0.7),
          node.color.withOpacity(0.9),
          node.color,
        ],
        stops: [0.1, 0.5, 1.0],
      );

      final Paint spherePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: nodeCenter, radius: node.radius),
        );

      // ノードの影を追加して立体感を表現
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3) // 影の色と透明度
        ..style = PaintingStyle.fill;

      // 影を球体の下に描画（立体感を強調）
      canvas.drawCircle(
        Offset(nodeCenter.dx, nodeCenter.dy + node.radius * 0.3), // 影の位置
        node.radius * 0.8, // 影の大きさ
        shadowPaint,
      );

      // 球体の本体を描画
      canvas.drawCircle(
        nodeCenter,
        node.radius,
        spherePaint,
      );

      // ハイライト部分を追加して、球体に光沢を与える
      final Paint highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.5) // ハイライトの色
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

      // 光源の位置を決めて、球体に反射するハイライトを描画
      canvas.drawCircle(
        Offset(nodeCenter.dx - node.radius * 0.3,
            nodeCenter.dy - node.radius * 0.3), // 光源位置
        node.radius * 0.3, // ハイライトの大きさ
        highlightPaint,
      );

      // アクティブなノードにはさらに輝きを追加
      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = Colors.white.withOpacity(0.7) // 光の色と透明度を調整
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 // 輪郭の太さ
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10); // ぼかし効果

        // アクティブノードの淵に輝きの円を描画
        canvas.drawCircle(nodeCenter, node.radius + 5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
