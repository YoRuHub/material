import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import 'package:flutter_app/utils/node_interaction_handler.dart';
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

  bool isFocusMode = false;

  late NodeModel _nodeModel;
  late NodeMapModel _nodeMapModel;
  Widget? currentDrawer;
  late NodeInteractionHandler _nodeInteractionHandler;

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

    // 必須の_nodeInteractionHandlerを初期化
    _nodeInteractionHandler =
        NodeInteractionHandler(ref: ref, projectId: widget.projectId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepareInitialization();
    });
  }

  Future<void> _prepareInitialization() async {
    try {
      // ポストフレームコールバックを使用して初期化を確実に実行
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ref.read(nodeStateProvider.notifier).resetState();
        ref.read(nodesProvider.notifier).clearNodes();
        ref.read(screenProvider.notifier).resetScreen();
        ref.read(screenProvider.notifier).setProjectId(widget.projectId);
        final projectId = ref.read(screenProvider).projectId;
        ref.read(projectNotifierProvider.notifier).setCurrentProject(projectId);

        // ノードの初期化
        await _initializeNodes(projectId);
      });
    } catch (e) {
      Logger.error('スクリーンの初期化中にエラーが発生しました: $e');
    }
  }

  Future<void> _initializeNodes(int projectId) async {
    final nodesData = await _nodeModel.fetchAllNodes(projectId);
    for (var node in nodesData) {
      if (mounted) {
        await NodeOperations.addNode(
          context: context,
          ref: ref,
          nodeId: node['id'] as int,
          title: node['title'] as String,
          contents: node['contents'] as String,
          color: node['color'] != null ? Color(node['color']) : null,
          createdAt: node['created_at'] as String,
        );
      }
    }

    final nodeMap = await _nodeMapModel.fetchAllNodeMap(projectId);
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
        NodeOperations.linkChildNode(ref, parentNode.id, childNode);
        NodeColorUtils.updateNodeColor(childNode, projectId);
      }
    }
  }

  // Drawerの状態を確認し、アニメーションを制御
  void _checkDrawerStatus(BuildContext context) {
    final isDrawerOpen = ref.watch(screenProvider).isDrawerOpen;

    if (isDrawerOpen) {
      if (!_controller.isAnimating) {
        _controller.stop();
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final nodeState = ref.watch(nodeStateProvider);
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
                        onPanStart: _nodeInteractionHandler.onPanStart,
                        onPanUpdate: _nodeInteractionHandler.onPanUpdate,
                        onPanEnd: _nodeInteractionHandler.onPanEnd,
                        onTapUp: _nodeInteractionHandler.onTapUp,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            NodePhysics.updatePhysics(
                                nodes: nodes,
                                draggedNode: nodeState.draggedNode,
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
                      detachChildren: _detachFromChildrenNode,
                      detachParent: _detachFromParentNode,
                      resetNodeColor: _resetNodeColor,
                      duplicateActiveNode: _duplicateActiveNode,
                      stopPhysics: _stopPhysics,
                      deleteActiveNode: _deleteActiveNode,
                      showNodeTitle: _showNodeTitle),
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
                            .read(nodeStateProvider.notifier)
                            .setActiveNode(updatedNode);
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSettingDrawer() async {
    setState(() {
      currentDrawer = const SettingDrawerWidget();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  Future<void> _openExportDrawer() async {
    setState(() {
      currentDrawer = const ExportDrawerWidget();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  Future<void> _openInportDrawer() async {
    setState(() {
      currentDrawer = const InportDrawerWidget();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openEndDrawer();
      });
    });
  }

  // アクティブノードを複製（子ノードを含む）
  Future<void> _duplicateActiveNode() async {
    NodeState nodeState = ref.read(nodeStateProvider);
    final activeNode = nodeState.activeNode;
    if (activeNode != null) {
      await NodeOperations.duplicateNode(
          context: context, ref: ref, targetNode: activeNode);
    }
  }

  //// 子ノードを切り離す
  Future<void> _detachFromChildrenNode() async {
    NodeState nodeState = ref.read(nodeStateProvider);
    final activeNode = nodeState.activeNode;
    if (activeNode != null) {
      await NodeOperations.detachChildren(activeNode, ref);
    }
  }

  /// 親ノードを切り離す
  Future<void> _detachFromParentNode() async {
    NodeState nodeState = ref.read(nodeStateProvider);
    final activeNode = nodeState.activeNode;
    if (activeNode != null) {
      await NodeOperations.detachParent(activeNode, ref);
    }
  }

  /// アクティブノードを削除（子ノードを含む）
  Future<void> _deleteActiveNode() async {
    NodeState nodeState = ref.read(nodeStateProvider);
    final nodeStateNotifier = ref.read(nodeStateProvider.notifier);

    final activeNode = nodeState.activeNode;
    if (activeNode != null) {
      // 子ノードも再帰的に削除
      await NodeOperations.deleteNode(activeNode, ref);
    }
    //アクティブ状態をリセット
    nodeStateNotifier.setActiveNode(null);
  }

  /// ノードを縦に並べ替え
  Future<void> _alignNodesVertical() async {
    await NodeAlignment.alignNodesVertical(
        MediaQuery.of(context).size, setState, ref);
  }

  /// ノードを横に並べ替え
  Future<void> _alignNodesHorizontal() async {
    await NodeAlignment.alignNodesHorizontal(
        MediaQuery.of(context).size, setState, ref);
  }

  Future<void> _resetNodeColor() async {
    NodeState nodeState = ref.read(nodeStateProvider);
    final activeNode = nodeState.activeNode;
    if (activeNode != null) {
      // 最上位の祖先を取得
      Node? rootAncestor = nodeState.activeNode;
      while (rootAncestor?.parent != null) {
        rootAncestor = rootAncestor!.parent;
      }

      // 最上位の祖先を基準に子孫ノードの色を更新
      if (rootAncestor != null) {
        NodeColorUtils.forceUpdateNodeColor(ref, rootAncestor);
      }
    }
  }

  /// 物理演算を停止
  Future<void> _stopPhysics() async {
    ref.read(screenProvider.notifier).togglePhysics();
  }

  /// ノードのタイトルを表示
  Future<void> _showNodeTitle() async {
    ref.read(screenProvider.notifier).toggleNodeTitles();
  }

  /// 新しいノードを追加
  Future<void> _addNode() async {
    await NodeOperations.addNode(
      context: context,
      ref: ref,
      nodeId: 0,
      title: '',
      contents: '',
      color: null,
      parentNode: ref.read(nodeStateProvider).activeNode,
    );
  }
}
