import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/database_helper.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/node_alignment.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/add_node_button.dart';
import 'package:flutter_app/widgets/node_contents_modal.dart';
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

  bool isPhysicsEnabled = true;

  Offset _offset = Offset.zero;
  Offset _offsetStart = Offset.zero;
  Offset _dragStart = Offset.zero;

  double _scale = 1.0;
  bool _isPanning = false;

  late NodeModel _nodeModel;
  late NodeMapModel _nodeMapModel;

  @override
  void initState() {
    super.initState();
    nodes = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _signalAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _nodeModel = NodeModel();
    _nodeMapModel = NodeMapModel();

    _initializeNodes();
  }

  Future<void> _initializeNodes() async {
    // ノードデータの取得と作成
    final nodesData = await _nodeModel.fetchAllNodes();
    for (var node in nodesData) {
      await _addNode(
        nodeId: node['id'],
        title: node['title'],
        contents: node['contents'],
      );
    }

    // ノードの関係性マップを取得
    final nodeMap = await _nodeMapModel.fetchAllNodeMap();
    for (var entry in nodeMap) {
      int parentId = entry.key;
      int childId = entry.value;
      Node? parentNode = nodes.cast<Node?>().firstWhere(
            (node) => node?.id == parentId,
            orElse: () => null,
          );

      Node? childNode = nodes.cast<Node?>().firstWhere(
            (node) => node?.id == childId,
            orElse: () => null,
          );

      if (parentNode != null && childNode != null) {
        setState(() {
          childNode.parent = parentNode;
          if (!parentNode.children.contains(childNode)) {
            parentNode.children.add(childNode);
            _updateNodeColor(childNode);
          }
        });
      }
    }
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
                    onTapDown: _onTapDown,
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
                          isPhysicsEnabled: isPhysicsEnabled,
                        );
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
                alignNodesVertical: _alignNodesVertical,
                isPhysicsEnabled: isPhysicsEnabled,
                detachChildren: _detachFromChildrenNode,
                detachParent: _detachFromParentNode,
                duplicateActiveNode: _duplicateActiveNode,
                stopPhysics: _stopPhysics,
                deleteActiveNode: _deleteActiveNode,
              ),
              AddNodeButton(onPressed: _addNode),
              //_resetTables button
            ],
          ),
          if (_activeNode != null)
            Builder(
              key: ValueKey(_activeNode!.id), // ここでキーを設定
              builder: (context) {
                return NodeContentsPanel(
                  node: _activeNode!,
                  nodeModel: _nodeModel,
                  onNodeUpdated: (updatedNode) {
                    setState(() {
                      _activeNode = updatedNode;
                    });
                  },
                );
              },
            )
        ],
      ),
    );
  }

  Future<void> _resetTables() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.resetTables();
  }

  // ノードとその子孫を再帰的にコピーするヘルパーメソッド
  Node _copyNodeWithChildren(Node originalNode, {Node? newParent}) {
    // 新しい位置を計算（少しずらす）
    vector_math.Vector2 newPosition = originalNode.position +
        vector_math.Vector2(
          NodeConstants.nodeSpacing,
          NodeConstants.levelHeight,
        );

    // 新しいノードを作成
    Node newNode = Node(
      id: originalNode.id,
      position: newPosition, // position
      velocity: vector_math.Vector2.zero(), // velocity（初期速度は0）
      color: originalNode.color, // color
      radius: originalNode.radius, // radius
      parent: newParent, title: '', contents: '', createdAt: '', // parent
    );

    // 子ノードを再帰的にコピー
    for (var child in originalNode.children) {
      Node newChild = _copyNodeWithChildren(child, newParent: newNode);
      newNode.children.add(newChild);
    }

    return newNode;
  }

  // アクティブノードとその子孫をコピーする関数
  void _duplicateActiveNode() {
    if (_activeNode != null) {
      setState(() {
        // アクティブノードとその子孫をコピー
        Node copiedNode = _copyNodeWithChildren(_activeNode!);

        // 新しいノードをノードリストに追加
        nodes.add(copiedNode);

        // 子ノードも追加
        _addChildrenToNodesList(copiedNode);

        // コピーしたノードの色を更新
        _updateNodeColor(copiedNode);
      });
    }
  }

  // 子ノードを再帰的にノードリストに追加するヘルパーメソッド
  void _addChildrenToNodesList(Node node) {
    for (var child in node.children) {
      nodes.add(child);
      _addChildrenToNodesList(child);
    }
  }

  void _detachFromChildrenNode() {
    if (_activeNode != null) {
      _nodeMapModel.deleteParentNodeMap(_activeNode!.id);
      setState(() {
        // 子ノードを切り離す
        for (var child in _activeNode!.children) {
          child.parent = null; // 親ノードをnullに設定

          // ランダムな方向と大きさを生成
          double angle = Random().nextDouble() * 2 * pi;

          // 極座標から直交座標に変換
          vector_math.Vector2 velocity = vector_math.Vector2(
            cos(angle) * NodeConstants.touchSpeedMultiplier,
            sin(angle) * NodeConstants.touchSpeedMultiplier,
          );

          // 切り離した子ノードにランダムな初速度を与える
          child.velocity = velocity;
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

  void _detachFromParentNode() {
    if (_activeNode != null && _activeNode!.parent != null) {
      setState(() {
        Node parentNode = _activeNode!.parent!;

        // 親ノードの子リストから削除
        _nodeMapModel.deleteChildNodeMap(_activeNode!.id);
        parentNode.children.remove(_activeNode);

        // ランダムな方向と大きさを生成
        double angle = Random().nextDouble() * 2 * pi;

        // 極座標から直交座標に変換
        vector_math.Vector2 velocity = vector_math.Vector2(
          cos(angle) * NodeConstants.touchSpeedMultiplier,
          sin(angle) * NodeConstants.touchSpeedMultiplier,
        );

        // アクティブノードと親ノードを反対方向に弾く
        _activeNode!.velocity = velocity;
        parentNode.velocity = -velocity; // 反対方向の速度を設定

        // 親ノードへの参照を解除
        _activeNode!.parent = null;

        // アクティブノードの色を更新（親がない状態の色に）
        _updateNodeColor(_activeNode!);

        // 元の親ノードの色も更新（子が減った状態の色に）
        for (var node in nodes) {
          if (node.parent == null) {
            _updateNodeColor(node);
          }
        }
      });
    }
  }

  void _deleteActiveNode() async {
    if (_activeNode != null) {
      // 子ノードも再帰的に削除
      await _deleteNodeAndChildren(_activeNode!);
    }
    //アクティブ状態を解除
    setState(() {
      _activeNode = null;
    });
  }

  Future<void> _deleteNodeAndChildren(Node node) async {
    // 子ノードを逆順に削除
    for (var i = node.children.length - 1; i >= 0; i--) {
      await _deleteNodeAndChildren(node.children[i]);
    }

    // 子ノードを削除
    node.parent?.children.remove(node);

    // ノードを削除
    nodes.remove(node);

    // dbから削除
    await _nodeModel.deleteNode(node.id);
    await _nodeMapModel.deleteParentNodeMap(node.id);
  }

  void _alignNodesVertical() async {
    if (nodes.isEmpty) return;

    await NodeAlignment.alignNodesVertical(
      nodes,
      MediaQuery.of(context).size,
      setState,
    );
  }

  void _alignNodesHorizontal() async {
    if (nodes.isEmpty) return;

    await NodeAlignment.alignNodesHorizontal(
      nodes,
      MediaQuery.of(context).size,
      setState,
    );
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

  Future<void> _addNode({
    int nodeId = 0,
    String title = '',
    String contents = '',
  }) async {
    // 基準位置を取得
    vector_math.Vector2 basePosition = CoordinateUtils.screenToWorld(
      MediaQuery.of(context).size.center(Offset.zero),
      _offset,
      _scale,
    );
    // 既存のノードがある場合は、少しずらしてランダム配置
    basePosition += vector_math.Vector2(
      (Random().nextDouble() * 2 - 1) * NodeConstants.nodeSpacing,
      (Random().nextDouble() * 2 - 1) * NodeConstants.nodeSpacing,
    );

    if (_activeNode != null) {
      // 非同期処理を先に完了させる
      int newNodeId = await _nodeModel.upsertNode(nodeId, title, contents);
      await _nodeMapModel.insertNodeMap(_activeNode!.id, newNodeId);

      final newNode = NodeOperations.addNode(
        position: basePosition,
        parentNode: _activeNode,
        generation: NodeOperations.calculateGeneration(_activeNode!) + 1,
        nodeId: newNodeId,
      );

      // 非同期処理完了後に setState で状態を更新
      setState(() {
        nodes.add(newNode);
      });
    } else {
      // 非同期処理を先に完了させる

      int newNodeId = await _nodeModel.upsertNode(nodeId, title, contents);

      final newNode = NodeOperations.addNode(
          position: basePosition,
          nodeId: newNodeId,
          title: title,
          contents: contents);

      // 非同期処理完了後に setState で状態を更新
      setState(() {
        nodes.add(newNode);
      });
    }
  }

  Future<void> _onUpdateNode(id, text, contents) async {
    await _nodeModel.upsertNode(id, text, contents);
    //nodeの内容を更新
    for (var node in nodes) {
      if (node.id == id) {
        node.title = text;
        node.contents = contents;
      }
    }
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
      setState(() {
        _checkAndUpdateParentChildRelationship(_draggedNode!);

        // ドラッグ終了時に速度をリセット
        _draggedNode!.velocity = vector_math.Vector2.zero();
        _draggedNode = null;
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

  void _onTapDown(TapDownDetails details) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      _offset,
      _scale,
    );
    // ノードの選択を確認
    bool isNodeSelected = _checkForNodeSelection(worldPos);

    setState(() {
      // ノードが選択されていない場合、アクティブ状態を解除
      if (!isNodeSelected) {
        if (_activeNode != null) {
          _activeNode!.isActive = false; // アクティブ状態を解除
          _activeNode = null;
        }
      }
    });
  }

  void _checkAndUpdateParentChildRelationship(Node draggedNode) {
    for (Node node in nodes) {
      if (node == draggedNode) continue;

      double distance = (draggedNode.position - node.position).length;

      if (distance < NodeConstants.snapDistance) {
        // 循環参照のチェック
        if (_wouldCreateCycle(draggedNode, node)) continue;

        if (node != draggedNode.parent) {
          // 現在の親ノードから子ノードを削除
          _nodeMapModel.deleteChildNodeMap(draggedNode.id);
          draggedNode.parent?.children.remove(draggedNode);

          // 新しい親子関係を設定
          draggedNode.parent = node;
          _nodeMapModel.insertNodeMap(node.id, draggedNode.id);
          node.children.add(draggedNode);

          // 色を更新
          _updateNodeColor(node);

          // 物理演算用のフラグをリセット
          draggedNode.isTemporarilyDetached = false;
          node.isTemporarilyDetached = false;
        }
      }
    }
  }

  // 循環参照が発生するかチェックするヘルパーメソッド
  bool _wouldCreateCycle(Node draggedNode, Node potentialParent) {
    // ドラッグされているノードが、新しい親の祖先になっているかチェック
    Node? current = potentialParent;
    while (current != null) {
      if (current == draggedNode) return true;
      current = current.parent;
    }
    return false;
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

  bool _checkForNodeSelection(vector_math.Vector2 worldPos) {
    // Check if the click hit any node
    for (var node in nodes) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      // Node was clicked
      if (distance < node.radius) {
        setState(() {
          // Activate the clicked node
          _activeNode?.isActive = false; // Deactivate the previous active node
          node.isActive = true; // Activate the clicked node
          _activeNode = node; // Set the active node
        });
        return true;
      }
    }

    // No node was clicked
    return false;
  }
}
