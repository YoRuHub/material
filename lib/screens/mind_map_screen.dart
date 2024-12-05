import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/providers/node_state_provider.dart';
import 'package:flutter_app/providers/project_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_alignment.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/addNodeButton/add_node_button.dart';
import 'package:flutter_app/widgets/exportButton/export_button.dart';
import 'package:flutter_app/widgets/exportButton/export_drawer_widget.dart';
import 'package:flutter_app/widgets/inportButton/inport_button.dart';
import 'package:flutter_app/widgets/inportButton/inport_drawer_widget.dart';
import 'package:flutter_app/widgets/nodeContentsModal/node_contents_modal.dart';
import 'package:flutter_app/widgets/positionedText/positioned_text.dart';
import 'package:flutter_app/widgets/settingButton/setting_button.dart';
import 'package:flutter_app/widgets/settingButton/setting_drawer_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../widgets/toolbar/tool_bar.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectTitle;

  const MindMapScreen(
      {super.key, required this.projectId, required this.projectTitle});

  @override
  MindMapScreenState createState() => MindMapScreenState();
}

class MindMapScreenState extends ConsumerState<MindMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _signalAnimation;
  late List<Node> nodes;

  bool isPhysicsEnabled = true;
  bool isTitleVisible = true;
  bool isFocusMode = false;

  Offset _offsetStart = Offset.zero;
  Offset _dragStart = Offset.zero;

  bool _isPanning = false;

  late NodeModel _nodeModel;
  late NodeMapModel _nodeMapModel;
  bool _isDrawerOpen = false; // Drawer の状態を管理するフラグ
  Widget? currentDrawer;

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
    // ウィジェットツリーのビルドが完了した後にノードの状態をリセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nodeStateNotifierProvider.notifier).resetState();
      ref.read(nodesProvider.notifier).clearNodes();
      ref.read(screenProvider.notifier).resetScreen();
      ref
          .read(projectNotifierProvider.notifier)
          .setCurrentProject(widget.projectId);
    });
    _initializeNodes();
  }

  Future<void> _initializeNodes() async {
    final nodesData = await _nodeModel.fetchAllNodes(widget.projectId);
    for (var node in nodesData) {
      if (mounted) {
        await NodeOperations.addNode(
          context: context,
          ref: ref,
          projectId: widget.projectId,
          nodeId: node['id'] as int,
          title: node['title'] as String,
          contents: node['contents'] as String,
          color: node['color'] != null ? Color(node['color']) : null,
          createdAt: node['created_at'] as String,
        );
      }
    }

    final nodeMap = await _nodeMapModel.fetchAllNodeMap(widget.projectId);
    for (var entry in nodeMap) {
      int parentId = entry.parentId;
      int childId = entry.childId;
      Node? parentNode = ref.watch(nodesProvider).cast<Node?>().firstWhere(
            (node) => node?.id == parentId,
            orElse: () => null,
          );

      Node? childNode = ref.watch(nodesProvider).cast<Node?>().firstWhere(
            (node) => node?.id == childId,
            orElse: () => null,
          );

      if (parentNode != null && childNode != null) {
        ref
            .read(nodesProvider.notifier)
            .addChildToNode(parentNode.id, childNode, widget.projectId);

        NodeColorUtils.updateNodeColor(childNode, widget.projectId);
      }
    }
  }

  void _checkDrawerStatus(BuildContext context) {
    final scaffoldState = Scaffold.of(context);
    if (scaffoldState.isDrawerOpen) {
      if (!_isDrawerOpen) {
        if (mounted) {
          _controller.stop(); // Drawerが開いたらアニメーション停止
          setState(() {
            _isDrawerOpen = true;
          });
        }
      }
    } else {
      if (_isDrawerOpen) {
        if (mounted) {
          _controller.repeat(); // Drawerが閉じたらアニメーション再開
          setState(() {
            _isDrawerOpen = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePhysics() {
    setState(() {
      isPhysicsEnabled = !isPhysicsEnabled;
    });
  }

  void _toggleNodeTitles() {
    setState(() {
      isTitleVisible = !isTitleVisible;
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openSettingDrawer() {
    setState(() {
      currentDrawer = SettingDrawerWidget(
        onPhysicsToggle: _togglePhysics,
        onTitleToggle: _toggleNodeTitles,
      );
    });
    // 状態更新後にDrawerを開く処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  void _openExportDrawer() {
    setState(() {
      currentDrawer = ExportDrawerWidget(
        onPhysicsToggle: _togglePhysics,
        onTitleToggle: _toggleNodeTitles,
        projectId: widget.projectId,
      );
    });
    // 状態更新後にDrawerを開く処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  void _openInportDrawer() {
    setState(() {
      currentDrawer = InportDrawerWidget(
        onPhysicsToggle: _togglePhysics,
        onTitleToggle: _toggleNodeTitles,
        projectId: widget.projectId,
      );
    });
    // 状態更新後にDrawerを開く処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final nodeState = ref.watch(nodeStateNotifierProvider);
    final screenState = ref.watch(screenProvider);
    ref.read(nodesProvider.notifier);

    return Scaffold(
      key: _scaffoldKey, // グローバルキーを指定
      appBar: AppBar(
        title: Text(widget.projectTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          InportButton(onPressed: () {
            _openInportDrawer();
            _scaffoldKey.currentState?.openEndDrawer();
          }),
          ExportButton(
            onPressed: () {
              _openExportDrawer();
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          SettingButton(
            onPressed: () {
              _openSettingDrawer();
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: currentDrawer,
      body: Builder(
        builder: (context) {
          _checkDrawerStatus(context); // Drawerの状態をチェック
          return Stack(
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
                              currentScale: screenState.scale,
                              scrollDelta: pointerSignal.scrollDelta.dy,
                              screenCenter: screenCenter,
                              currentOffset: screenState.offset,
                            );

                            ref
                                .read(screenProvider.notifier)
                                .setScale(newScale);
                            ref
                                .read(screenProvider.notifier)
                                .setOffset(newOffset);
                          });
                        }
                      },
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapUp: _onTapUp,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            NodePhysics.updatePhysics(
                                nodes: nodes,
                                draggedNode: nodeState.draggedNode,
                                isPhysicsEnabled: isPhysicsEnabled,
                                ref: ref);
                            return CustomPaint(
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.height -
                                    AppBar().preferredSize.height,
                              ),
                              painter: NodePainter(
                                  ref.read(nodesProvider),
                                  _signalAnimation.value,
                                  screenState.scale,
                                  screenState.offset,
                                  isTitleVisible,
                                  context,
                                  ref),
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
                    offsetX: screenState.offset.dx,
                    offsetY: screenState.offset.dy,
                    scaleZ: screenState.scale,
                  ),
                  ToolBarWidget(
                      alignNodesHorizontal: _alignNodesHorizontal,
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
              if (nodeState.activeNode != null)
                Builder(
                  key: ValueKey(nodeState.activeNode!.id),
                  builder: (context) {
                    return NodeContentsPanel(
                      node: nodeState.activeNode!,
                      nodeModel: _nodeModel,
                      onNodeUpdated: (updatedNode) {
                        ref
                            .read(nodeStateNotifierProvider.notifier)
                            .setActiveNode(updatedNode);
                      },
                    );
                  },
                )
            ],
          );
        },
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
    final newNode = await NodeOperations.addNode(
      context: context,
      ref: ref,
      projectId: widget.projectId,
      nodeId: 0,
      title: originalNode.title,
      contents: originalNode.contents,
      color: originalNode.color,
      parentNode: newParent,
    );

    // 子ノードを再帰的にコピー
    for (var child in originalNode.children) {
      await _copyNodeWithChildren(child, newParent: newNode);
    }

    return newNode;
  }

  // アクティブノードとその子孫をコピーする関数
  Future<void> _duplicateActiveNode() async {
    NodeState nodeState = ref.read(nodeStateNotifierProvider);
    if (nodeState.activeNode != null) {
      // Perform the asynchronous work
      Node copiedNode = await _copyNodeWithChildren(nodeState.activeNode!);

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

  Future<void> _detachFromChildrenNode() async {
    NodeState nodeState = ref.read(nodeStateNotifierProvider);

    if (nodeState.activeNode != null) {
      final activeNode = nodeState.activeNode!;

      // 削除する子ノードを保持するリストを作成
      List<Node> childrenToRemove = [];

      // 2. 子ノードを切り離す処理
      for (var child in activeNode.children) {
        // 3. ランダムな方向に弾く
        double angle = Random().nextDouble() * 2 * pi;
        child.velocity = vector_math.Vector2(
          cos(angle) * NodeConstants.touchSpeedMultiplier,
          sin(angle) * NodeConstants.touchSpeedMultiplier,
        );

        // 4. 子ノードの色をリセット
        NodeColorUtils.updateNodeColor(child, widget.projectId);

        // 5. 削除する子ノードをリストに追加
        childrenToRemove.add(child);
      }

      // 6. ノードプロバイダーで子ノードの親を削除
      for (var child in childrenToRemove) {
        // 子ノードをプロバイダーから削除
        await ref
            .read(nodesProvider.notifier)
            .removeChildFromNode(activeNode.id, child);
      }
    }
  }

  Future<void> _detachFromParentNode() async {
    NodeState nodeState = ref.read(nodeStateNotifierProvider);

    if (nodeState.activeNode != null && nodeState.activeNode!.parent != null) {
      final activeNode = nodeState.activeNode!;
      final parentNode = activeNode.parent!;

      await ref
          .read(nodesProvider.notifier)
          .removeParentFromNode(activeNode.id);

      double angle = Random().nextDouble() * 2 * pi;
      vector_math.Vector2 velocity = vector_math.Vector2(
        cos(angle) * NodeConstants.touchSpeedMultiplier,
        sin(angle) * NodeConstants.touchSpeedMultiplier,
      );

      activeNode.velocity = velocity;
      parentNode.velocity = -velocity;
    }
  }

  /// アクティブノードを削除(子ノードを再帰的に削除)
  void _deleteActiveNode() async {
    NodeState nodeState = ref.read(nodeStateNotifierProvider);
    if (nodeState.activeNode != null) {
      // 子ノードも再帰的に削除
      await NodeOperations.deleteNode(
          nodeState.activeNode!, widget.projectId, ref);
    }
    //アクティブ状態を解除
    ref.read(nodeStateNotifierProvider.notifier).setActiveNode(null);
  }

  void _alignNodesVertical() async {
    await NodeAlignment.alignNodesVertical(
        MediaQuery.of(context).size, setState, ref);
  }

  void _alignNodesHorizontal() async {
    await NodeAlignment.alignNodesHorizontal(
        MediaQuery.of(context).size, setState, ref);
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

  Future<void> _addNode() async {
    await NodeOperations.addNode(
      context: context,
      ref: ref,
      projectId: widget.projectId,
      nodeId: 0,
      title: '',
      contents: '',
      color: null,
      parentNode: ref.read(nodeStateNotifierProvider).activeNode,
    );
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
    // スクリーン座標をワールド座標に変換
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      ref.read(screenProvider).offset, // ScreenProviderからオフセットを取得
      ref.read(screenProvider).scale, // ScreenProviderからスケールを取得
    );

    for (var node in ref.read(nodesProvider)) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        // ノードが選択された場合
        ref.read(nodeStateNotifierProvider.notifier).setDraggedNode(node);
        setState(() {
          _isPanning = false;
          _dragStart = details.localPosition;
        });
        return;
      }
    }

    // ノードが選択されなかった場合は、ビューのドラッグ
    setState(() {
      _isPanning = true;
      _offsetStart = ref.read(screenProvider).offset;
      _dragStart = details.localPosition;
      ref.read(nodeStateNotifierProvider.notifier).setDraggedNode(null);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final draggedNode = ref.read(nodeStateNotifierProvider).draggedNode;

    if (draggedNode != null) {
      // ノードがドラッグ中の場合
      setState(() {
        vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
          details.localPosition,
          ref.read(screenProvider).offset, // ScreenProviderからオフセットを取得
          ref.read(screenProvider).scale, // ScreenProviderからスケールを取得
        );
        draggedNode.position = worldPos;
      });
    } else if (_isPanning) {
      // ビューのドラッグ中
      setState(() {
        final dragDelta = details.localPosition - _dragStart;
        ref
            .read(screenProvider.notifier)
            .setOffset(_offsetStart + dragDelta); // オフセット更新
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final draggedNode = ref.read(nodeStateNotifierProvider).draggedNode;
    if (draggedNode != null) {
      setState(() {
        _checkAndUpdateParentChildRelationship(draggedNode);

        // ドラッグ終了時に速度をリセット
        draggedNode.velocity = vector_math.Vector2.zero();
        ref.read(nodeStateNotifierProvider.notifier).setDraggedNode(null);
      });
    }

    // ドラッグ終了後にpanningフラグをリセット
    setState(() {
      _isPanning = false;
    });
  }

  void _onTapUp(TapUpDetails details) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      ref.read(screenProvider).offset, // ScreenProviderからオフセットを取得
      ref.read(screenProvider).scale, // ScreenProviderからスケールを取得
    );
    _checkForNodeSelection(worldPos);
  }

  bool _checkForNodeSelection(vector_math.Vector2 worldPos) {
    bool isNodeSelected = false;

    // クリックで選択されるノードを探す
    for (var node in ref.read(nodesProvider)) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        setState(() {
          final currentActiveNode =
              ref.read(nodeStateNotifierProvider).activeNode;

          // タップされたノードがすでにアクティブなら、アクティブ状態を解除
          if (node == currentActiveNode) {
            Logger.debug('Deselecting Node: ${node.id}');
            node.isActive = false;
            ref.read(nodeStateNotifierProvider.notifier).setActiveNode(null);
          } else {
            // 新しいノードをアクティブにする
            _toggleActiveNode(node);
          }
        });
        isNodeSelected = true;
        break; // ノードが選択されたのでループを抜ける
      }
    }

    // ノードが選択されていない場合（背景をタップした場合）
    if (!isNodeSelected) {
      setState(() {
        final currentActiveNode =
            ref.read(nodeStateNotifierProvider).activeNode;
        if (currentActiveNode != null) {
          currentActiveNode.isActive = false;
          ref.read(nodeStateNotifierProvider.notifier).setActiveNode(null);
        }
      });
    }

    return isNodeSelected;
  }

  void _toggleActiveNode(Node newNode) {
    // 現在アクティブなノードを取得
    final currentActiveNode = ref.read(nodeStateNotifierProvider).activeNode;

    if (currentActiveNode != null) {
      // 現在アクティブなノードを非アクティブにする
      currentActiveNode.isActive = false;
      ref.read(nodeStateNotifierProvider.notifier).setActiveNode(null);
    }

    // 新しいノードをアクティブにする
    newNode.isActive = true;
    ref.read(nodeStateNotifierProvider.notifier).setActiveNode(newNode);
  }

  void _checkAndUpdateParentChildRelationship(Node draggedNode) {
    for (Node node in ref.read(nodesProvider)) {
      if (node == draggedNode) continue;

      // ドラッグされたノードと他のノードとの距離を計算
      double distance = (draggedNode.position - node.position).length;

      // 規定のスナップ距離内の場合のみ処理を実行
      if (distance < NodeConstants.snapEffectRange) {
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
          _nodeMapModel.insertNodeMap(
              node.id, draggedNode.id, widget.projectId);
          node.children.add(draggedNode);

          // 色を更新
          NodeColorUtils.updateNodeColor(node, widget.projectId);

          // **孫ノードを子ノードに正しく紐づける**
          for (Node child in draggedNode.children) {
            child.parent = draggedNode; // 子ノードとして再設定
            _nodeMapModel.insertNodeMap(
                draggedNode.id, child.id, widget.projectId);
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
    NodeState nodeState = ref.read(nodeStateNotifierProvider);
    if (nodeState.activeNode == null) return;

    // 最上位の祖先を取得
    Node? rootAncestor = nodeState.activeNode;
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
}
