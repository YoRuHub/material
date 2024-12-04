import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/models/node.dart'; // Adjust import path as needed

// Define a state notifier class for managing nodes
class NodesNotifier extends StateNotifier<List<Node>> {
  NodesNotifier() : super([]);

  // Add a single node
  void addNode(Node node) {
    // Check if a node with the same ID already exists
    if (state.any((existingNode) => existingNode.id == node.id)) {
      // If a node with the same ID exists, do not add
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
  void addChildToNode(int parentNodeId, Node childNode) {
    state = state.map((node) {
      if (node.id == parentNodeId) {
        node.children.add(childNode);
        childNode.parent = node;
      }
      return node;
    }).toList();
  }

  // Remove a child from a specific parent node
  void removeChildFromNode(int parentNodeId, Node childNode) {
    state = state.map((node) {
      if (node.id == parentNodeId) {
        node.children.remove(childNode);
        childNode.parent = null;
      }
      return node;
    }).toList();
  }
}

// Create the provider
final nodesProvider = StateNotifierProvider<NodesNotifier, List<Node>>((ref) {
  return NodesNotifier();
});
