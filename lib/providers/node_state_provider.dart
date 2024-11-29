import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/models/node.dart';

// ノードの状態を管理するためのStateNotifier
class NodeStateNotifier extends StateNotifier<NodeState> {
  NodeStateNotifier() : super(NodeState()) {
    Logger.debug('NodeStateNotifier created with initial state');
  }

  void setDraggedNode(Node? node) {
    if (state.draggedNode != node) {
      state = state.copyWith(draggedNode: node);
    }
  }

  void setActiveNode(Node? node) {
    if (state.activeNode != node) {
      state = state.copyWith(activeNode: node);
    }
  }

  @override
  set state(NodeState newState) {
    super.state = newState;
  }
}

class NodeState {
  final Node? draggedNode;
  final Node? activeNode;

  NodeState({this.draggedNode, this.activeNode});

  NodeState copyWith({
    Node? draggedNode,
    Node? activeNode,
  }) {
    return NodeState(
      draggedNode: draggedNode,
      activeNode: activeNode ?? this.activeNode,
    );
  }
}

// Riverpodプロバイダーの定義
final nodeStateNotifierProvider =
    StateNotifierProvider<NodeStateNotifier, NodeState>(
        (ref) => NodeStateNotifier());
