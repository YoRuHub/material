import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/node.dart';
import '../../providers/node_state_provider.dart';
import '../../providers/screen_provider.dart';
import '../../utils/node_alignment.dart';
import '../../utils/node_color_utils.dart';
import '../../utils/node_operations.dart';

final toolbarControllerProvider =
    Provider.family<ToolbarController, ToolbarControllerParams>((ref, params) {
  return ToolbarController(
      ref: params.ref, context: params.context, projectId: params.projectId);
});

class ToolbarControllerParams {
  final WidgetRef ref;
  final BuildContext context;
  final int projectId;

  ToolbarControllerParams(
      {required this.ref, required this.context, required this.projectId});
}

class ToolbarController {
  final WidgetRef ref;
  final BuildContext context;
  final int projectId;

  ToolbarController(
      {required this.ref, required this.context, required this.projectId});

  Future<void> alignNodesHorizontal() async {
    await NodeAlignment.alignNodesHorizontal(
        MediaQuery.of(context).size, (fn) => fn(), ref);
  }

  Future<void> alignNodesVertical() async {
    await NodeAlignment.alignNodesVertical(
        MediaQuery.of(context).size, (fn) => fn(), ref);
  }

  Future<void> detachChildren() async {
    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;
    if (activeNodes.isNotEmpty) {
      for (final activeNode in activeNodes) {
        await NodeOperations.detachChildren(activeNode, ref);
      }
    }
  }

  Future<void> detachParent() async {
    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;
    if (activeNodes.isNotEmpty) {
      for (final activeNode in activeNodes) {
        await NodeOperations.detachParent(activeNode, ref);
      }
    }
  }

  Future<void> duplicateActiveNode() async {
    List<Node> activeNodes = ref.read(nodeStateProvider).activeNodes;
    if (activeNodes.isNotEmpty) {
      for (final activeNode in activeNodes) {
        await NodeOperations.duplicateNode(
            context: context, ref: ref, targetNode: activeNode);
      }
    }
  }

  Future<void> resetNodeColor() async {
    final nodeState = ref.read(nodeStateProvider);
    List<Node> activeNodes = nodeState.activeNodes;
    if (activeNodes.isNotEmpty) {
      for (final activeNode in activeNodes) {
        Node? rootAncestor = activeNode;
        while (rootAncestor?.parent != null) {
          rootAncestor = rootAncestor!.parent;
        }

        if (rootAncestor != null) {
          NodeColorUtils.forceUpdateNodeColor(ref, rootAncestor);
        }
      }
    }
  }

  Future<void> deleteActiveNode() async {
    final nodeState = ref.read(nodeStateProvider);
    final nodeStateNotifier = ref.read(nodeStateProvider.notifier);
    List<Node> activeNodes = nodeState.activeNodes;
    if (activeNodes.isNotEmpty) {
      for (final activeNode in activeNodes) {
        await NodeOperations.deleteNode(activeNode, ref);
      }
    }

    nodeStateNotifier.clearActiveNodes();
    nodeStateNotifier.clearSelectedNode();
  }

  void togglePhysics() {
    ref.read(screenProvider.notifier).togglePhysics();
  }

  void toggleNodeTitles() {
    ref.read(screenProvider.notifier).toggleNodeTitles();
  }

  void toggleLinkMode() {
    ref.read(screenProvider.notifier).toggleLinkMode();
  }
}
