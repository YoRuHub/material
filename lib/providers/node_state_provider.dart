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

  // 選択されたノードを設定する
  void setSelectedNode(Node? node) {
    if (state.selectedNode != node) {
      state = state.copyWith(selectedNode: node);
    }
  }

  void setActiveNodes(List<Node> nodes) {
    state = state.copyWith(activeNodes: nodes);
  }

  // アクティブノードを追加する
  void addActiveNode(Node node) {
    if (!state.activeNodes.contains(node)) {
      state = state.copyWith(activeNodes: [...state.activeNodes, node]);
    }
  }

  // アクティブノードを削除する
  void removeActiveNode(Node node) {
    state = state.copyWith(
      activeNodes: state.activeNodes.where((n) => n != node).toList(),
    );
  }

  void clearActiveNodes() {
    state = state.resetActiveWith(activeNodes: []);
  }

  // 状態をリセットする
  void resetState() {
    state = NodeState();
  }
}

class NodeState {
  final Node? draggedNode;
  final List<Node> activeNodes;
  final Node? selectedNode;

  NodeState({
    this.draggedNode,
    List<Node>? activeNodes,
    this.selectedNode,
  }) : activeNodes = activeNodes ?? [];

  NodeState copyWith({
    Node? draggedNode,
    List<Node>? activeNodes,
    Node? selectedNode,
  }) {
    return NodeState(
      draggedNode: draggedNode,
      activeNodes: activeNodes ?? this.activeNodes,
      selectedNode: selectedNode ?? this.selectedNode,
    );
  }

  // アクティブノードのリストをリセットする
  NodeState resetActiveWith({List<Node>? activeNodes}) {
    return NodeState(
      activeNodes: activeNodes ?? [],
    );
  }
}

// Riverpodプロバイダーの定義
final nodeStateProvider = StateNotifierProvider<NodeStateNotifier, NodeState>(
  (ref) => NodeStateNotifier(),
);
