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
  Future<void> removeNode(Node node) async {
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
        node.targetNodes.add(targetNode);
        targetNode.sourceNodes.add(node);
      }
      return node;
    }).toList();
  }

  // Remove a target node from a source node
// すでに同じリンクが存在する場合、そのリンクを削除する
  Future<void> unlinkTargetNodeFromSource(
      int sourceNodeId, int targetNodeId) async {
    state = state.map((node) {
      // sourceNodeのtargetNodesリストからtargetNodeを削除
      if (node.id == sourceNodeId) {
        node.targetNodes
            .removeWhere((targetNode) => targetNode.id == targetNodeId);
        Logger.debug(
            'Removed targetNode $targetNodeId from sourceNode $sourceNodeId');
      }

      // targetNode側にsourceNodeがある場合も削除
      if (node.id == targetNodeId) {
        node.sourceNodes
            .removeWhere((sourceNode) => sourceNode.id == sourceNodeId);
        Logger.debug(
            'Removed sourceNode $sourceNodeId from targetNode $targetNodeId');
      }

      return node;
    }).toList();
  }

  Future<void> removeSourceNodeReferences(int removeNodeId) async {
    state = state.map((node) {
      if (node.sourceNodes.isNotEmpty) {
        // sourceNodesリストから削除対象のノードを除外
        node.sourceNodes
            .removeWhere((sourceNode) => sourceNode.id == removeNodeId);
        Logger.debug('Removed source node $removeNodeId from node ${node.id}');
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
