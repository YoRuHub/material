import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/node_alignment.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/add_node_button.dart';
import 'package:flutter_app/widgets/positioned_text.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../widgets/tool_bar.dart';

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  MindMapScreenState createState() => MindMapScreenState();
}

class MindMapScreenState extends State<MindMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _signalAnimation;
  late List<Node> nodes;
  Node? _draggedNode;
  Node? _activeNode;

  bool isAligningHorizontal = false;
  bool isAligningVertical = false;
  bool isPhysicsEnabled = false;

  Offset _offset = Offset.zero;
  Offset _offsetStart = Offset.zero;
  Offset _dragStart = Offset.zero;

  double _scale = 1.0;
  bool _isPanning = false;

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
      appBar: AppBar(
        title: const Text("Mind Map"),
        backgroundColor: Colors.black45,
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      setState(() {
                        final screenCenter =
                            CoordinateUtils.calculateScreenCenter(
                          MediaQuery.of(context).size,
                          AppBar().preferredSize.height,
                        );

                        final (newScale, newOffset) =
                            CoordinateUtils.calculateZoom(
                          currentScale: _scale,
                          scrollDelta: pointerSignal.scrollDelta.dy,
                          screenCenter: screenCenter,
                          currentOffset: _offset,
                        );

                        _scale = newScale;
                        _offset = newOffset;
                      });
                    }
                  },
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTapUp: _onTapUp,
                    onSecondaryTapDown: (details) =>
                        setState(() => _isPanning = true),
                    onSecondaryTapUp: (details) =>
                        setState(() => _isPanning = false),
                    onSecondaryTapCancel: () =>
                        setState(() => _isPanning = false),
                    onSecondaryLongPressMoveUpdate: (details) {
                      if (_isPanning) {
                        setState(() => _offset += details.offsetFromOrigin);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        NodePhysics.updatePhysics(
                            nodes: nodes,
                            draggedNode: _draggedNode,
                            isPhysicsEnabled: isPhysicsEnabled);
                        return CustomPaint(
                          size: Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height -
                                AppBar().preferredSize.height,
                          ),
                          painter: NodePainter(
                            nodes,
                            _signalAnimation.value,
                            _scale,
                            _offset,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              PositionedText(
                offsetX: _offset.dx,
                offsetY: _offset.dy,
                scaleZ: _scale,
              ),
              ToolBarWidget(
                alignNodesHorizontal:
                    _alignNodesHorizontal, // contextを渡さないように修正
                alignNodesVertical: _alignNodesVertical, // contextを渡さないように修正
                isAligningHorizontal: isAligningHorizontal,
                isAligningVertical: isAligningVertical,
                isPhysicsEnabled: isPhysicsEnabled,
                detachChildren: _detachChildrenFromActiveNode,
                stopPhysics: _stopPhysics,
                deleteActiveNode: _deleteActiveNode,
              ),
              AddNodeButton(onPressed: _addNode),
            ],
          ),
        ],
      ),
    );
  }

  void _detachChildrenFromActiveNode() {
    if (_activeNode != null) {
      setState(() {
        // 子ノードを切り離す
        for (var child in _activeNode!.children) {
          child.parent = null; // 親ノードをnullに設定

          // 切り離した子ノードにランダムな初速度を与える
          child.velocity = vector_math.Vector2(
            Random().nextDouble() * 100 - 50,
            Random().nextDouble() * 100 - 50,
          );
        }
        _activeNode!.children.clear(); // 子ノードリストを空にする

        // アクティブノードの色を更新
        _updateNodeColor(_activeNode!);

        // 切り離した後、ノードの色を再計算
        for (var node in nodes) {
          if (node.parent == null) {
            // 親がないノード（独立したノード）の色をリセット
            _updateNodeColor(node);
          }
        }
      });
    }
  }

  void _deleteActiveNode() {
    if (_activeNode != null) {
      // 子ノードも再帰的に削除
      _deleteNodeAndChildren(_activeNode!);
    }
    //アクティブ状態を解除
    setState(() {
      _activeNode = null;
    });
  }

  void _deleteNodeAndChildren(Node node) {
    // 子ノードを逆順に削除
    for (var i = node.children.length - 1; i >= 0; i--) {
      _deleteNodeAndChildren(node.children[i]);
    }

    // 子ノードを削除
    node.parent?.children.remove(node);

    // ノードを削除
    nodes.remove(node);
  }

  void _alignNodesVertical() async {
    if (nodes.isEmpty) return;

    setState(() {
      isAligningVertical = true;
    });

    await NodeAlignment.alignNodesVertical(
      nodes,
      MediaQuery.of(context).size,
      setState,
    );

    setState(() {
      isAligningVertical = false;
    });
  }

  void _alignNodesHorizontal() async {
    if (nodes.isEmpty) return;

    setState(() {
      isAligningHorizontal = true;
    });

    await NodeAlignment.alignNodesHorizontal(
      nodes,
      MediaQuery.of(context).size,
      setState,
    );

    setState(() {
      isAligningHorizontal = false;
    });
  }

  void _stopPhysics() {
    if (isPhysicsEnabled) {
      setState(() {
        isPhysicsEnabled = false;
      });
      return;
    }

    setState(() {
      isPhysicsEnabled = true;
    });
  }

  void _addNode() {
    setState(() {
      if (_activeNode != null) {
        final newNode = NodeOperations.addNode(
          position:
              _activeNode!.position + NodeOperations.generateRandomOffset(),
          parentNode: _activeNode,
          generation: NodeOperations.calculateGeneration(_activeNode!) + 1,
        );
        nodes.add(newNode);
      } else {
        final newNode = NodeOperations.addNode(
          position: CoordinateUtils.screenToWorld(
            MediaQuery.of(context).size.center(Offset.zero),
            _offset,
            _scale,
          ),
        );
        nodes.add(newNode);
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

  static Color getColorForGeneration(int generation) {
    double hue = (generation * NodeConstants.hueShift) % NodeConstants.maxHue;
    return HSLColor.fromAHSL(
      NodeConstants.alpha,
      hue,
      NodeConstants.saturation,
      NodeConstants.lightness,
    ).toColor();
  }

  void _onPanStart(DragStartDetails details) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      _offset,
      _scale,
    );

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
          vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
            details.localPosition,
            _offset,
            _scale,
          );
          _draggedNode!.position = worldPos;
        });
      }
    } else if (_isPanning) {
      setState(() {
        final dragDelta = details.localPosition - _dragStart;
        _offset = _offsetStart + dragDelta;
      });
    }
  }

// ドラッグ終了時に親子関係をチェックして更新する
  void _onPanEnd(DragEndDetails details) {
    if (_draggedNode != null) {
      // ノードが選択されている場合、親子関係を更新
      setState(() {
        _checkAndUpdateParentChildRelationship(
            _draggedNode!); // ノードが近づいたときに親子関係を更新
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      _offset,
      _scale,
    );
    _checkForNodeSelection(worldPos);
  }

  void _checkAndUpdateParentChildRelationship(Node draggedNode) {
    for (Node node in nodes) {
      // 自分自身はスキップ
      if (node == draggedNode) continue;

      // 他のノードとの距離を計算
      double distance = (draggedNode.position - node.position).length;

      // 近距離の場合、親子関係を設定
      if (distance < 10.0) {
        if (node != draggedNode.parent) {
          setState(() {
            // 現在の親ノードから子ノードを削除（必要に応じて）
            if (draggedNode.parent != null) {
              draggedNode.parent!.children.remove(draggedNode);
            }

            // 新しい親ノードを設定
            draggedNode.parent = node;
            node.children.add(draggedNode); // 新しい親ノードの子に追加

            // 親子関係に基づいて色を更新
            _updateNodeColor(node); // 親ノードを基点に、親子関係すべてを更新
          });
        }
      }
    }
  }

// 親子関係に基づいてノードの色を更新するメソッド
  void _updateNodeColor(Node node) {
    // ノードの世代を計算
    int generation = _calculateGeneration(node);

    // 世代に基づいて色を設定
    node.color = getColorForGeneration(generation);

    // 子ノードに対しても再帰的に色を更新
    for (Node child in node.children) {
      _updateNodeColor(child); // 子ノードの色も更新
    }
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

  void resetAlignmentState() {
    setState(() {
      isAligningVertical = false;
      isAligningHorizontal = false;
    });
  }
}
