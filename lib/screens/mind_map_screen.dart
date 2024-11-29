import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_alignment.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/addNodeButton/add_node_button.dart';
import 'package:flutter_app/widgets/nodeContentsModal/node_contents_modal.dart';
import 'package:flutter_app/widgets/positionedText/positioned_text.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../widgets/toolbar/tool_bar.dart';

class MindMapScreen extends StatefulWidget {
  final int projectId; // プロジェクトIDを保持
  final String projectTitle;

  const MindMapScreen(
      {super.key, required this.projectId, required this.projectTitle});

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
  bool isTitleVisible = true;
  bool isFocusMode = false;

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
    final nodesData = await _nodeModel.fetchAllNodes(widget.projectId);
    for (var node in nodesData) {
      await _addNode(
        nodeId: node['id'] as int,
        title: node['title'] as String,
        contents: node['contents'] as String,
        color: node['color'] != null
            ? Color(node['color'] as int) // int を Color に変換
            : null, // null の場合はそのまま
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
            NodeColorUtils.updateNodeColor(childNode, widget.projectId);
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
        title: Text(
          widget.projectTitle,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                          painter: NodePainter(nodes, _signalAnimation.value,
                              _scale, _offset, isTitleVisible, context),
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
                  resetNodeColor: _resetNodeColor,
                  duplicateActiveNode: _duplicateActiveNode,
                  stopPhysics: _stopPhysics,
                  deleteActiveNode: _deleteActiveNode,
                  showNodeTitle: _showNodeTitle,
                  isTitleVisible: isTitleVisible),
              AddNodeButton(onPressed: _addNode),
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

  ///ノードのタイトルを表示するヘルパーメソッド

  void _showNodeTitle() {
    setState(() {
      isTitleVisible = !isTitleVisible;
    });
  }

  // focusモード

  // ノードとその子孫を再帰的にコピーするヘルパーメソッド
  Future<Node> _copyNodeWithChildren(Node originalNode,
      {Node? newParent}) async {
    // 新しい位置を計算（少しずらす）
    vector_math.Vector2 newPosition = originalNode.position +
        vector_math.Vector2(
          NodeConstants.nodeSpacing,
          NodeConstants.levelHeight,
        );

    final newNodeData = await _nodeModel.upsertNode(0, originalNode.title,
        originalNode.contents, originalNode.color, widget.projectId);
    // 新しいノードを作成
    Node newNode = Node(
      id: newNodeData['id'] as int,
      position: newPosition,
      velocity: vector_math.Vector2.zero(),
      color: originalNode.color,
      radius: originalNode.radius,
      parent: newParent,
      title: originalNode.title,
      contents: originalNode.contents,
      projectId: widget.projectId,
      createdAt: newNodeData['created_at'] as String,
    );

    // 子ノードを再帰的にコピー
    for (var child in originalNode.children) {
      Node newChild = await _copyNodeWithChildren(child, newParent: newNode);
      await _nodeMapModel.insertNodeMap(newNode.id, newChild.id);
      newNode.children.add(newChild);
    }

    return newNode;
  }

  // アクティブノードとその子孫をコピーする関数
  Future<void> _duplicateActiveNode() async {
    if (_activeNode != null) {
      // Perform the asynchronous work
      Node copiedNode = await _copyNodeWithChildren(_activeNode!);

      // Update the widget state
      setState(() {
        // Add the new node to the nodes list
        nodes.add(copiedNode);

        // Add the children to the nodes list
        _addChildrenToNodesList(copiedNode);

        // Update the node color
        NodeColorUtils.updateNodeColor(copiedNode, widget.projectId);
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
      // 1. アクティブノードから子ノードの関係を削除
      _nodeMapModel.deleteParentNodeMap(_activeNode!.id);

      setState(() {
        // 2. 子ノードを切り離す処理
        for (var child in _activeNode!.children) {
          child.parent = null; // 子ノードの親をリセット

          // 3. ランダムな方向に弾く
          double angle = Random().nextDouble() * 2 * pi;
          child.velocity = vector_math.Vector2(
            cos(angle) * NodeConstants.touchSpeedMultiplier,
            sin(angle) * NodeConstants.touchSpeedMultiplier,
          );

          // 4. 子ノードの色をリセット
          NodeColorUtils.updateNodeColor(child, widget.projectId);

          // 5. データモデルからも削除
          _nodeMapModel.deleteParentNodeMap(child.id);
        }

        // 6. アクティブノードの子リストをクリア
        _activeNode!.children.clear();
      });
    }
  }

  void _detachFromParentNode() {
    if (_activeNode != null && _activeNode!.parent != null) {
      setState(() {
        try {
          // 親ノードを取得
          Node parentNode = _activeNode!.parent!;

          // 子リストから削除
          if (parentNode.children.contains(_activeNode)) {
            _nodeMapModel.deleteChildNodeMap(_activeNode!.id);
            parentNode.children.remove(_activeNode);
          }

          // ランダムな方向に速度を設定
          double angle = Random().nextDouble() * 2 * pi;
          vector_math.Vector2 velocity = vector_math.Vector2(
            cos(angle) * NodeConstants.touchSpeedMultiplier,
            sin(angle) * NodeConstants.touchSpeedMultiplier,
          );

          // アクティブノードと親ノードに反対方向の速度を設定
          _activeNode!.velocity = velocity;
          parentNode.velocity = -velocity;

          // 親ノード参照を解除
          _activeNode!.parent = null;

          // アクティブノードの色を更新
          NodeColorUtils.updateNodeColor(_activeNode!, widget.projectId);

          // 元の親ノードの色を更新（影響範囲を限定）
          NodeColorUtils.updateNodeColor(parentNode, widget.projectId);
        } catch (e) {
          // エラーログを出力
          Logger.error('Error detaching node: $e');
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
    await _nodeModel.deleteNode(node.id, widget.projectId);
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
    Color? color,
  }) async {
    // 基準位置を取得（親ノードがある場合、親ノードの位置を基準にする）
    vector_math.Vector2 basePosition;

    if (_activeNode != null) {
      // 親ノードの位置を基準にする
      basePosition = _activeNode!.position;
      // colorがnullの場合はNodeColorUtilsで計算された階層の色を使用する
      color ??= NodeColorUtils.getColorForNextGeneration(_activeNode);
      // 親ノードの位置に少しオフセットを加えて配置（ランダムにずらす）
      basePosition += vector_math.Vector2(
        (Random().nextDouble() * 2 - 1) * NodeConstants.nodeSpacing,
        (Random().nextDouble() * 2 - 1) * NodeConstants.nodeSpacing,
      );
    } else {
      // 親ノードがない場合、画面の中心を基準にする
      basePosition = CoordinateUtils.screenToWorld(
        MediaQuery.of(context).size.center(Offset.zero),
        _offset,
        _scale,
      );

      // ランダムに少しずらして配置
      basePosition += vector_math.Vector2(
        (Random().nextDouble() * 2 - 1) * NodeConstants.nodeSpacing,
        (Random().nextDouble() * 2 - 1) * NodeConstants.nodeSpacing,
      );
    }

    // 非同期処理を先に完了させる
    final newNodeData = await _nodeModel.upsertNode(
        nodeId, title, contents, color, widget.projectId);
    int newNodeId = newNodeData['id'] as int;

    if (_activeNode != null) {
      // 親ノードがある場合、親ノード情報をセットしてノードを追加
      await _nodeMapModel.insertNodeMap(_activeNode!.id, newNodeId);

      final newNode = NodeOperations.addNode(
        position: basePosition,
        parentNode: _activeNode,
        nodeId: newNodeId,
        color: color,
        projectId: widget.projectId,
      );

      // 非同期処理完了後に setState で状態を更新
      setState(() {
        nodes.add(newNode);
      });
    } else {
      // 親ノードがない場合はそのまま新しいノードを追加
      final newNode = NodeOperations.addNode(
        position: basePosition,
        nodeId: newNodeId,
        title: title,
        contents: contents,
        color: color,
        projectId: widget.projectId,
      );

      // 非同期処理完了後に setState で状態を更新
      setState(() {
        nodes.add(newNode);
      });
    }
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

    for (var node in nodes) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        setState(() {
          _draggedNode = node;
          _isPanning = false;
        });
        return;
      }
    }

    setState(() {
      _isPanning = true;
      _offsetStart = _offset;
      _dragStart = details.localPosition;
      _draggedNode = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      // ノードの移動を相対位置で更新
      setState(() {
        vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
          details.localPosition,
          _offset,
          _scale,
        );
        _draggedNode!.position = worldPos;
      });
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

      // ドラッグされたノードと他のノードとの距離を計算
      double distance = (draggedNode.position - node.position).length;

      // 規定のスナップ距離内の場合のみ処理を実行
      if (distance < NodeConstants.snapDistance) {
        // 循環参照が発生するか確認
        if (_wouldCreateCycle(draggedNode, node)) continue;

        // 新しい親子関係を形成
        if (node != draggedNode.parent) {
          // 現在の親ノードからこのノードを削除
          if (draggedNode.parent != null) {
            _nodeMapModel.deleteChildNodeMap(draggedNode.id);
            draggedNode.parent!.children.remove(draggedNode);
          }

          // ノードを新しい親ノードに紐づける
          draggedNode.parent = node;
          _nodeMapModel.insertNodeMap(node.id, draggedNode.id);
          node.children.add(draggedNode);

          // 色を更新
          NodeColorUtils.updateNodeColor(node, widget.projectId);

          // **孫ノードを子ノードに正しく紐づける**
          for (Node child in draggedNode.children) {
            child.parent = draggedNode; // 子ノードとして再設定
            _nodeMapModel.insertNodeMap(draggedNode.id, child.id);
            NodeColorUtils.updateNodeColor(child, widget.projectId);
          }

          // 物理演算用のフラグをリセット
          draggedNode.isTemporarilyDetached = false;
          node.isTemporarilyDetached = false;
        }
      }
    }
  }

  void _resetNodeColor() {
    if (_activeNode == null) return;

    // 最上位の祖先を取得
    Node? rootAncestor = _activeNode;
    while (rootAncestor?.parent != null) {
      rootAncestor = rootAncestor!.parent;
    }

    // 最上位の祖先を基準に子孫ノードの色を更新
    if (rootAncestor != null) {
      NodeColorUtils.forceUpdateNodeColor(rootAncestor, widget.projectId);
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
