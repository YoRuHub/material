import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_link_map_model.dart';
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
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_app/utils/node_interaction_handler.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/addNodeButton/add_node_button.dart';
import 'package:flutter_app/widgets/aiSupportButton/ai_support_button.dart';
import 'package:flutter_app/widgets/exportButton/export_button.dart';
import 'package:flutter_app/widgets/exportButton/export_drawer_widget.dart';
import 'package:flutter_app/widgets/inportButton/inport_button.dart';
import 'package:flutter_app/widgets/inportButton/inport_drawer_widget.dart';
import 'package:flutter_app/widgets/nodeContentsModal/node_contents_modal.dart';
import 'package:flutter_app/widgets/positionedText/positioned_text.dart';
import 'package:flutter_app/widgets/settingButton/setting_button.dart';
import 'package:flutter_app/widgets/settingButton/setting_drawer_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/aiSupportButton/ai_support_drawer_widget.dart';
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
  // animation
  late AnimationController _controller;
  late Animation<double> _signalAnimation;
  // database
  late NodeModel _nodeModel;
  late NodeMapModel _nodeMapModel;
  late NodeLinkMapModel _nodeLinkMapModel;
  // provider
  late ScreenNotifier _screenNotifier;
  late NodeStateNotifier _nodeStateNotifier;
  late NodesNotifier _nodesNotifirer;
  late ProjectNotifier _projectNotifier;
  late ScreenState _screenState;
  late NodeState _nodeState;
  // node
  late List<Node> nodes;

  Widget? currentDrawer;
  late NodeInteractionHandler _nodeInteractionHandler;

  late Timer _inactiveTimer; // タイマーを追加
  final Duration _inactiveDuration = const Duration(
      seconds: NodeConstants.inactiveDurationTime); // 操作がない時間（5秒）

  @override
  void initState() {
    super.initState();
    nodes = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _signalAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    // databaseの初期化などはそのまま
    _nodeModel = NodeModel();
    _nodeMapModel = NodeMapModel();
    _nodeLinkMapModel = NodeLinkMapModel();

    // 必須の_nodeInteractionHandlerを初期化
    _nodeInteractionHandler =
        NodeInteractionHandler(ref: ref, projectId: widget.projectId);

    // 操作がない場合にアニメーションを停止するためのタイマー
    _startInactiveTimer();

    // 初期化処理をpost-frameで呼び出す
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepareInitialization();
    });
  }

  void _startInactiveTimer() {
    _inactiveTimer = Timer.periodic(_inactiveDuration, (timer) {
      _screenNotifier.enableAnimating();
      Logger.debug('アニメーションを開始しました');
      if (_controller.isAnimating) {
        _controller.stop();
        _screenNotifier.disableAnimating();
        Logger.debug('アニメーションを停止しました');
      }
    });
  }

  Future<void> _prepareInitialization() async {
    try {
      // ポストフレームコールバックを使用して初期化を確実に実行
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final projectId = widget.projectId;
        _nodeStateNotifier.resetState();
        _nodesNotifirer.clearNodes();
        _screenNotifier.resetScreen();
        _screenNotifier.setProjectId(projectId);
        _projectNotifier.setCurrentProject(projectId);

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

    // ターゲットリンクを設定
    final nodeLinkMap = await _nodeLinkMapModel.fetchAllNodeMap(projectId);

    for (var entry in nodeLinkMap) {
      int sourceId = entry.sourceId;
      int targetId = entry.targetId;

      // ノード検索
      Node? sourceNode = ref.watch(nodesProvider).cast<Node?>().firstWhere(
            (node) => node?.id == sourceId,
            orElse: () => null,
          );

      Node? targetNode = ref.watch(nodesProvider).cast<Node?>().firstWhere(
            (node) => node?.id == targetId,
            orElse: () => null,
          );

      // リンクの設定
      if (sourceNode != null && targetNode != null) {
        await _nodesNotifirer.linkTargetNodeToSource(sourceId, targetNode);
        Logger.debug('Linking source node $sourceId to target node $targetId');
      }
    }
  }

  // Drawerの状態を確認し、アニメーションを制御
  void _checkDrawerStatus(BuildContext context) {
    final isDrawerOpen = _screenState.isDrawerOpen;
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
    _inactiveTimer.cancel();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenNotifier = ref.read(screenProvider.notifier);
    _nodeStateNotifier = ref.read(nodeStateProvider.notifier);
    _nodesNotifirer = ref.read(nodesProvider.notifier);
    _projectNotifier = ref.read(projectProvider.notifier);
    _screenState = ref.read(screenProvider);
    _nodeState = ref.read(nodeStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final nodeState = ref.watch(nodeStateProvider);
    final screenState = ref.watch(screenProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.projectTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          AiSupportButton(onPressed: () {
            _openAiSupportDrawer();
            _scaffoldKey.currentState?.openEndDrawer();
          }),
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

                            _screenNotifier.setScale(newScale);
                            _screenNotifier.setOffset(newOffset);
                          });
                        }
                      },
                      child: GestureDetector(
                        onPanStart: _nodeInteractionHandler.onPanStart,
                        onPanUpdate: _nodeInteractionHandler.onPanUpdate,
                        onPanEnd: _nodeInteractionHandler.onPanEnd,
                        onTapUp: _nodeInteractionHandler.onTapUp,
                        onPanDown: (details) {
                          _inactiveTimer.cancel();
                          _controller.repeat();
                          // 新しいタイマーを開始
                          _startInactiveTimer();
                        },
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
                                  _signalAnimation.value, context, ref),
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
                  const PositionedText(),
                  const ToolBarWidget(),
                  AddNodeButton(onPressed: _addNode),
                ],
              ),
              if (nodeState.selectedNode != null)
                Builder(
                  key: ValueKey(nodeState.selectedNode!.id),
                  builder: (context) {
                    return NodeContentsPanel(
                      node: nodeState.selectedNode!,
                      nodeModel: _nodeModel,
                      onNodeUpdated: (updatedNode) {
                        _nodeStateNotifier.setSelectedNode(updatedNode);
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

  Future<void> _openAiSupportDrawer() async {
    setState(() {
      currentDrawer = const AiSupportDrawerWidget();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openEndDrawer();
      });
    });
  }

  /// 新しいノードを追加
  Future<void> _addNode() async {
    final activeNodes = ref.watch(nodeStateProvider).activeNodes;

    if (activeNodes.isNotEmpty) {
      // アクティブノードのリストをループして処理
      for (final activeNode in activeNodes) {
        await NodeOperations.addNode(
          context: context,
          ref: ref,
          nodeId: 0,
          title: '',
          contents: '',
          color: null,
          parentNode: activeNode,
        );
      }
    } else {
      await NodeOperations.addNode(
        context: context,
        ref: ref,
        nodeId: 0,
        title: '',
        contents: '',
        color: null,
        parentNode: null,
      );
    }
  }
}
