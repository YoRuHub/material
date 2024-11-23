import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class NodeCanvas extends ConsumerStatefulWidget {
  final double signalAnimationValue;
  final double scale;
  final Offset offset;
  final bool isTitleVisible;

  const NodeCanvas({
    Key? key,
    required this.signalAnimationValue,
    required this.scale,
    required this.offset,
    required this.isTitleVisible,
  }) : super(key: key);

  @override
  NodeCanvasState createState() => NodeCanvasState();
}

class NodeCanvasState extends ConsumerState<NodeCanvas> {
  Node? _draggedNode;
  bool _isPanning = false;
  Offset _offsetStart = Offset.zero;
  Offset _dragStart = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodeNotifierProvider);

    return GestureDetector(
      onPanStart: (details) => _onPanStart(details, nodes),
      onPanUpdate: (details) => _onPanUpdate(details),
      onPanEnd: (details) => _onPanEnd(details),
      onTapDown: (details) => _onTapDown(details),
      onTapUp: (details) => _onTapUp(details),
      child: CustomPaint(
        painter: NodePainter(
          nodes,
          widget.signalAnimationValue,
          widget.scale,
          widget.offset,
          widget.isTitleVisible,
          context,
        ),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details, List<Node> nodes) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      widget.offset,
      widget.scale,
    );

    // ノードのドラッグ開始判定
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

    // ノードが選択されなかった場合はパンニング開始
    setState(() {
      _isPanning = true;
      _offsetStart = widget.offset;
      _dragStart = details.localPosition;
      _draggedNode = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
        details.localPosition,
        widget.offset,
        widget.scale,
      );

      final updatedNode = _draggedNode!.copyWith(
        position: worldPos,
        isActive: _draggedNode!.isActive,
      );

      setState(() {
        _draggedNode = updatedNode;
      });

      ref.read(nodeNotifierProvider.notifier).updateNodeState(updatedNode);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_draggedNode != null) {
      final nodeNotifier = ref.read(nodeNotifierProvider.notifier);
      nodeNotifier.updateNodeState(_draggedNode!);

      setState(() {
        _draggedNode = null;
      });
    }
    _isPanning = false;
  }

  void _onTapUp(TapUpDetails details) {
    final worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      widget.offset,
      widget.scale,
    );
    _checkForNodeSelection(worldPos);
  }

  void _onTapDown(TapDownDetails details) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      widget.offset,
      widget.scale,
    );

    bool isNodeSelected = _checkForNodeSelection(worldPos);

    if (!isNodeSelected) {
      // アクティブなノードの選択解除
      final activeNode = ref.read(nodeNotifierProvider.notifier).activeNode;
      if (activeNode != null) {
        ref.read(nodeNotifierProvider.notifier).updateNodeState(
              activeNode.copyWith(isActive: false),
            );
      }
    }
  }

  bool _checkForNodeSelection(vector_math.Vector2 worldPos) {
    final nodes = ref.read(nodeNotifierProvider);
    final nodeNotifier = ref.read(nodeNotifierProvider.notifier);

    for (var node in nodes) {
      double dx = node.position.x - worldPos.x;
      double dy = node.position.y - worldPos.y;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < node.radius) {
        nodeNotifier.setActiveNode(node);
        return true;
      }
    }
    return false;
  }
}
