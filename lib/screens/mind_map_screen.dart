import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_link_map_model.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/painters/screen_painter.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/providers/node_state_provider.dart';
import 'package:flutter_app/providers/screen_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_app/utils/node_interaction_handler.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/addNodeButton/add_node_button.dart';
import 'package:flutter_app/widgets/aiSupportButton/ai_support_button.dart';
import 'package:flutter_app/widgets/nodeContentsModal/node_contents_modal.dart';
import 'package:flutter_app/widgets/positionedText/positioned_text.dart';
import 'package:flutter_app/widgets/settingButton/setting_button.dart';
import 'package:flutter_app/widgets/settingButton/setting_drawer_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/aiSupportButton/ai_support_drawer_widget.dart';
import '../widgets/importExportButton/import_export_button.dart';
import '../widgets/importExportButton/import_export_drawer.dart';
import '../widgets/toolbar/tool_bar.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final Node? projectNode;

  const MindMapScreen({
    super.key,
    required this.projectNode,
  });

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
    _nodeInteractionHandler = NodeInteractionHandler(
        ref: ref, projectId: widget.projectNode?.id ?? 0);

    // 操作がない場合にアニメーションを停止するためのタイマー
    _startInactivityAnimationStopTimer();

    // 初期化処理をpost-frameで呼び出す
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepareInitialization();
    });
  }

  // 操作がない場合にアニメーションを停止する
  void _startInactivityAnimationStopTimer() {
    _inactiveTimer = Timer.periodic(_inactiveDuration, (timer) {
      if (_controller.isAnimating) {
        _controller.stop();
        Logger.debug('アニメーションが停止しました');
      }
    });
  }

  // アニメーションを再開する
  void _startAnimationTimer() {
    _inactiveTimer.cancel();
    _controller.repeat();
    _startInactivityAnimationStopTimer();
  }

  Future<void> _prepareInitialization() async {
    try {
      // ポストフレームコールバックを使用して初期化を確実に実行
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final projectId = widget.projectNode?.id ?? 0;
        _nodeStateNotifier.resetState();
        _nodesNotifirer.clearNodes();
        _screenNotifier.resetScreen();
        // 画面中央を設定
        final screenCenter = CoordinateUtils.calculateScreenCenter(
          MediaQuery.of(ref.context).size,
          AppBar().preferredSize.height,
        );
        ref.read(screenProvider.notifier).setCenterPosition(screenCenter);

        if (widget.projectNode != null) {
          _screenNotifier.setProjectNode(widget.projectNode as Node);
        }

        // ノードの初期化
        await _initializeNodes(projectId);
      });
    } catch (e) {
      Logger.error('スクリーンの初期化中にエラーが発生しました: $e');
    }
  }

  Future<void> _initializeNodes(int projectId) async {
    final nodesData = await _nodeModel.fetchProjectNodes(projectId);
    for (var node in nodesData) {
      if (mounted) {
        await NodeOperations.addNode(
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

  @override
  void dispose() {
    _controller.dispose();
    _inactiveTimer.cancel(); // タイマーを停止
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenNotifier = ref.read(screenProvider.notifier);
    _nodeStateNotifier = ref.read(nodeStateProvider.notifier);
    _nodesNotifirer = ref.read(nodesProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesProvider);
    final nodeState = ref.watch(nodeStateProvider);
    final screenState = ref.watch(screenProvider);
    final draggedNode = nodeState.draggedNode;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.projectNode?.title ?? ''),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        leading: screenState.nodeStack.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _screenNotifier.popNodeFromStack();
                  Node? previousNode;
                  if (screenState.nodeStack.length > 1) {
                    previousNode =
                        screenState.nodeStack[screenState.nodeStack.length - 2];
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MindMapScreen(projectNode: previousNode),
                    ),
                  );
                })
            : null,
        actions: [
          AiSupportButton(onPressed: () {
            _openAiSupportDrawer();
            _scaffoldKey.currentState?.openEndDrawer();
          }),
          ImportExportButton(onPressed: () {
            _openInportExportDrawer();
            _scaffoldKey.currentState?.openEndDrawer();
          }),
          SettingButton(
            onPressed: () {
              _openSettingDrawer();
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Builder(
        builder: (context) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 320,
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: currentDrawer,
            ),
          );
        },
      ),
      body: Builder(
        builder: (context) {
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
                        onTapUp: (details) {
                          _nodeInteractionHandler.onTapUp(
                              details, context); // contextを渡す
                        },
                        onTapDown: (details) {
                          // アニメーションを再開
                          _startAnimationTimer();
                        },
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            NodePhysics.updatePhysics(
                                nodes: nodes,
                                draggedNode: draggedNode,
                                ref: ref);
                            return CustomPaint(
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.height -
                                    AppBar().preferredSize.height,
                              ),
                              painter: ScreenPainter(ref), // 背景ペインターを追加
                              foregroundPainter: NodePainter(
                                  // ノード描画を前景に
                                  _signalAnimation.value,
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

  Future<void> _openAiSupportDrawer() async {
    setState(() {
      currentDrawer = const AiSupportDrawerWidget();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openEndDrawer();
      });
    });
  }

  Future<void> _openInportExportDrawer() async {
    setState(() {
      currentDrawer = const ImportExportDrawer();
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
