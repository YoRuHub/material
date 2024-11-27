import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/painters/node_painter.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/coordinate_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class NodeCanvas extends ConsumerStatefulWidget {
  final double signalAnimationValue;
  final double initialScale; // 初期スケール
  final Offset initialOffset; // 初期オフセット
  final bool isTitleVisible;

  const NodeCanvas({
    super.key,
    required this.signalAnimationValue,
    required this.initialScale,
    required this.initialOffset,
    required this.isTitleVisible,
  });

  @override
  NodeCanvasState createState() => NodeCanvasState();
}

class NodeCanvasState extends ConsumerState<NodeCanvas> {
  double _scale = 1.0; // スケール
  Offset _offset = Offset.zero; // オフセット
  Node? _draggedNode;
  bool _isPanning = false;
  Offset _offsetStart = Offset.zero;
  Offset _dragStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale; // 初期スケールを設定
    _offset = widget.initialOffset; // 初期オフセットを設定
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodeNotifierProvider);

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _onPointerScroll(event); // スクロールによるズーム処理
        }
      },
      child: GestureDetector(
        onPanStart: (details) => _onPanStart(details, nodes),
        onPanUpdate: (details) => _onPanUpdate(details),
        onPanEnd: (details) => _onPanEnd(details),
        onTapDown: (details) => _onTapDown(details),
        onTapUp: (details) => _onTapUp(details),
        child: CustomPaint(
          painter: NodePainter(
            nodes,
            widget.signalAnimationValue,
            _scale, // スケール
            _offset, // オフセット
            widget.isTitleVisible,
            context,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  // ドラッグ開始時の処理
  void _onPanStart(DragStartDetails details, List<Node> nodes) {
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

  // ドラッグ更新時の処理
  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedNode != null) {
      vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
        details.localPosition,
        _offset,
        _scale,
      );

      final updatedNode = _draggedNode!.copyWith(
        position: worldPos,
        isActive: _draggedNode!.isActive,
      );

      setState(() {
        _draggedNode = updatedNode;
      });

      ref.read(nodeNotifierProvider.notifier).updateNodeState(updatedNode);
    } else if (_isPanning) {
      Offset delta = details.localPosition - _dragStart;

      setState(() {
        _offset = _offsetStart + delta;
      });
    }
  }

  // ドラッグ終了時の処理
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

  // タップアップ時の処理
  void _onTapUp(TapUpDetails details) {
    final worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      _offset,
      _scale,
    );
    _checkForNodeSelection(worldPos);
  }

  // タップダウン時の処理
  void _onTapDown(TapDownDetails details) {
    vector_math.Vector2 worldPos = CoordinateUtils.screenToWorld(
      details.localPosition,
      _offset,
      _scale,
    );

    bool isNodeSelected = _checkForNodeSelection(worldPos);

    if (!isNodeSelected) {
      final activeNode = ref.read(nodeNotifierProvider.notifier).activeNode;
      if (activeNode != null) {
        ref.read(nodeNotifierProvider.notifier).updateNodeState(
              activeNode.copyWith(isActive: false),
            );
      }
    }
  }

  // ノード選択の確認
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

  // ズーム処理（スクロールによるズーム）
  void _onPointerScroll(PointerScrollEvent pointerSignal) {
    setState(() {
      final screenCenter = CoordinateUtils.calculateScreenCenter(
        MediaQuery.of(context).size,
        AppBar().preferredSize.height,
      );

      final (newScale, newOffset) = CoordinateUtils.calculateZoom(
        currentScale: _scale,
        scrollDelta: pointerSignal.scrollDelta.dy,
        screenCenter: screenCenter,
        currentOffset: _offset,
      );

      _scale = newScale;
      _offset = newOffset;
    });
  }
}
