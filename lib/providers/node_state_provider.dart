import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/models/node.dart';

// ノードの状態を管理するためのStateNotifier
class NodeStateNotifier extends StateNotifier<NodeState> {
  NodeStateNotifier() : super(NodeState());

  // ドラッグノードを設定する
  void setDraggedNode(Node? node) {
    if (state.draggedNode != node) {
      state = state.copyWith(draggedNode: node);
    }
  }

  // アクティブノードを設定する
  void setActiveNode(Node? node) {
    state = state.resetActiveWith(activeNode: node);
  }

  // 状態をリセットする
  void resetState() {
    state = NodeState();
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

  NodeState resetActiveWith({
    Node? activeNode,
  }) {
    return NodeState(
      activeNode: activeNode,
    );
  }
}

// Riverpodプロバイダーの定義
final nodeStateNotifierProvider =
    StateNotifierProvider<NodeStateNotifier, NodeState>(
        (ref) => NodeStateNotifier());
