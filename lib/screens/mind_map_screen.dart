import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/providers/node_map_provider.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_physics.dart';
import 'package:flutter_app/widgets/node_canvas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/widgets/add_node_button.dart';
import 'package:flutter_app/widgets/node_contents_modal.dart';
import 'package:flutter_app/widgets/positioned_text.dart';
import 'package:flutter_app/widgets/tool_bar.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

// SingleTickerProviderStateMixinを追加
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
  // ここを追加
  late AnimationController _controller;
  late Animation<double> _signalAnimation;

  Node? _draggedNode;
  bool isPhysicsEnabled = true;
  bool isTitleVisible = true;
  bool isFocusMode = false;
  final Offset _offset = Offset.zero;
  final double _scale = 1.0;
  late NodeModel _nodeModel;

  @override
  void initState() {
    super.initState();
    // NodeModel を初期化
    _nodeModel = NodeModel();
    _controller = AnimationController(
      vsync: this, // TickerProviderを提供
      duration: const Duration(seconds: 3),
    )..repeat();
    _signalAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeNodes();
  }

  Future<void> _initializeNodes() async {
    try {
      final nodeNotifier = ref.read(nodeNotifierProvider.notifier);

      // ノードとノードマップをロード
      await nodeNotifier.loadNodes(widget.projectId);

      final nodeMapNotifier = ref.read(nodeMapNotifierProvider.notifier);
      await nodeMapNotifier.loadNodeMaps();

      // 親子関係を同期
      final nodeMap = ref.read(nodeMapNotifierProvider);
      await nodeNotifier.syncParentChildRelations(nodeMap);
    } catch (e) {
      Logger.error('Error initializing nodes: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodeNotifierProvider);
    final activeNode = ref.watch(nodeNotifierProvider.notifier).activeNode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
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
                    // Implement zoom handling if needed
                  },
                  child: GestureDetector(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        NodePhysics.updatePhysics(
                          nodes: nodes,
                          draggedNode: _draggedNode,
                          isPhysicsEnabled: isPhysicsEnabled,
                        );
                        return NodeCanvas(
                          signalAnimationValue: _signalAnimation.value,
                          initialScale: _scale,
                          initialOffset:
                              _offset, // 修正: offset ではなく initialOffset を渡す
                          isTitleVisible: isTitleVisible,
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
                alignNodesHorizontal: _alignNodesHorizontal,
                alignNodesVertical: _alignNodesVertical,
                isPhysicsEnabled: isPhysicsEnabled,
                detachChildren: _alignNodesVertical,
                detachParent: _alignNodesVertical,
                duplicateActiveNode: _alignNodesVertical,
                stopPhysics: _stopPhysics,
                deleteActiveNode: _alignNodesVertical,
                showNodeTitle: _showNodeTitle,
                isTitleVisible: isTitleVisible,
              ),
              AddNodeButton(onPressed: _onAddNodePressed),
            ],
          ),
          if (activeNode != null)
            NodeContentsPanel(
              key: ValueKey(activeNode.id),
              node: activeNode,
              nodeModel: _nodeModel,
              onNodeUpdated: (updatedNode) {
                ref
                    .read(nodeNotifierProvider.notifier)
                    .updateNodeState(updatedNode);
              },
            ),
        ],
      ),
    );
  }

  void _onAddNodePressed() async {
    try {
      final nodeNotifier = ref.read(nodeNotifierProvider.notifier);
      final nodeMapNotifier = ref.read(nodeMapNotifierProvider.notifier);

      // 新しいノードを作成（IDやプロパティは適宜設定）
      final newNode = Node(
        id: 0,
        position: vector_math.Vector2(100.0, 100.0),
        velocity: vector_math.Vector2.zero(),
        color: Colors.green,
        radius: 30.0,
        title: "New Node",
        contents: "This is a new node",
        projectId: widget.projectId,
        createdAt: DateTime.now().toIso8601String(),
      );

      // ノードを追加（アクティブノードが考慮される）
      await nodeNotifier.addNode(newNode, nodeMapNotifier);
    } catch (e) {
      Logger.error("Error adding node: $e");
    }
  }

  void _alignNodesHorizontal() {
    ref.read(nodeNotifierProvider); // ノードリストを取得
    // ノードを水平方向に整列するロジックを追加
  }

  void _alignNodesVertical() {
    ref.read(nodeNotifierProvider); // ノードリストを取得
    // ノードを垂直方向に整列するロジックを追加
  }

  void _stopPhysics() {
    setState(() {
      isPhysicsEnabled = !isPhysicsEnabled;
    });
  }

  void _showNodeTitle() {
    setState(() {
      isTitleVisible = !isTitleVisible;
    });
  }
}
