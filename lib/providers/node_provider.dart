import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/models/node.dart';

// Define a state notifier class for managing nodes
class NodesNotifier extends StateNotifier<List<Node>> {
  NodesNotifier() : super([]);
  final nodeMapModel = NodeMapModel();

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
  Future<void> addChildToNode(
      int parentNodeId, Node childNode, int projectId) async {
    state = state.map((node) {
      if (node.id == parentNodeId) {
        Logger.debug('Adding child node $childNode to parent node $node');
        node.children.add(childNode);
        childNode.parent = node;
      }
      return node;
    }).toList();
    await nodeMapModel.insertNodeMap(parentNodeId, childNode.id, projectId);
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

    nodeMapModel.deleteParentNodeMap(parentNodeId);
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

    nodeMapModel.deleteChildNodeMap(childNodeId);
  }
}

// Create the provider
final nodesProvider = StateNotifierProvider<NodesNotifier, List<Node>>((ref) {
  return NodesNotifier();
});
