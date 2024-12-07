import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/models/node.dart';

// Define a state notifier class for managing nodes
class NodesNotifier extends StateNotifier<List<Node>> {
  NodesNotifier() : super([]);

  // Add a single node
  void addNode(Node node) {
    // 同じIDのノードが存在する場合は追加しない
    if (state.any((existingNode) => existingNode.id == node.id)) {
      return;
    }
    state = [...state, node];
    Logger.debug('Node added: $node');
  }

  // Remove a single node
  void removeNode(Node node) {
    state = state.where((n) => n.id != node.id).toList();
  }

  // Remove a node by its ID
  void removeNodeById(int nodeId) {
    state = state.where((node) => node.id != nodeId).toList();
  }

  // Replace the entire list of nodes
  void setNodes(List<Node> nodes) {
    state = nodes;
  }

  // Clear all nodes
  void clearNodes() {
    state = [];
  }

  // Update a specific node
  void updateNode(Node updatedNode) {
    state = state
        .map((node) => node.id == updatedNode.id ? updatedNode : node)
        .toList();
  }

  // Find a node by ID
  Node? findNodeById(int nodeId) {
    return state.firstWhere((node) => node.id == nodeId);
  }

  // Add a child to a specific parent node
  Future<void> linkChildNodeToParent(
      int parentNodeId, Node childNode, int projectId) async {
    state = state.map((node) {
      if (node.id == parentNodeId) {
        Logger.debug('Adding child node $childNode to parent node $node');
        node.children.add(childNode);
        childNode.parent = node;
      }
      return node;
    }).toList();
  }

  // Add a target node to a source node
  Future<void> linkTargetNodeToSource(int sourceNodeId, Node targetNode) async {
    state = state.map((node) {
      if (node.id == sourceNodeId) {
        Logger.debug('Adding target node $targetNode to source node $node');
        node.targetNodes.add(targetNode); // ここでターゲット先ノードを追加
        targetNode.sourceNodes.add(node); // 逆方向にも追加
      }
      return node;
    }).toList();
  }

  // Remove a target node from a source node
  Future<void> removeTargetNodeFromSource(
      int sourceNodeId, Node targetNode) async {
    state = state.map((node) {
      if (node.id == sourceNodeId) {
        Logger.debug('Removing target node $targetNode from source node $node');
        node.targetNodes.remove(targetNode); // ソースノードからターゲットノードを削除
        targetNode.sourceNodes.remove(node); // 逆方向にも削除
      }
      return node;
    }).toList();
  }

  // Remove a source node from a target node
  Future<void> removeSourceNodeFromTarget(
      int targetNodeId, Node sourceNode) async {
    state = state.map((node) {
      if (node.id == targetNodeId) {
        Logger.debug('Removing source node $sourceNode from target node $node');
        node.sourceNodes.remove(sourceNode); // ターゲットノードからソースノードを削除
        sourceNode.targetNodes.remove(node); // 逆方向にも削除
      }
      return node;
    }).toList();
  }

  // Remove a child from a specific parent node
  Future<void> removeChildFromNode(int parentNodeId, Node childNode) async {
    state = state.map((node) {
      if (node.id == parentNodeId) {
        node.children.remove(childNode);
        childNode.parent = null;
      }
      return node;
    }).toList();
  }

  // NodesNotifier に親ノードを切り離すメソッドを追加
  Future<void> removeParentFromNode(int childNodeId) async {
    state = state.map((node) {
      // Find the node that is the parent of the child node
      if (node.children.any((child) => child.id == childNodeId)) {
        // Remove the child from this node's children
        node.children.removeWhere((child) => child.id == childNodeId);
      }
      return node;
    }).toList();

    // Update the specific child node to remove its parent reference
    state = state.map((node) {
      if (node.id == childNodeId) {
        node.parent = null;
      }
      return node;
    }).toList();
  }
}

// Create the provider
final nodesProvider = StateNotifierProvider<NodesNotifier, List<Node>>((ref) {
  return NodesNotifier();
});
