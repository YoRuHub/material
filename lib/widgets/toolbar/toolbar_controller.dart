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
    await NodeAlignment.alignNodesHorizontal(
        MediaQuery.of(context).size, (fn) => fn(), ref);
  }

  Future<void> detachChildren() async {
    final activeNode = ref.read(nodeStateProvider).activeNode;
    if (activeNode != null) {
      await NodeOperations.detachChildren(activeNode, ref);
    }
  }

  Future<void> detachParent() async {
    final activeNode = ref.read(nodeStateProvider).activeNode;
    if (activeNode != null) {
      await NodeOperations.detachParent(activeNode, ref);
    }
  }

  Future<void> duplicateActiveNode() async {
    final activeNode = ref.read(nodeStateProvider).activeNode;
    if (activeNode != null) {
      await NodeOperations.duplicateNode(
          context: context, ref: ref, targetNode: activeNode);
    }
  }

  Future<void> resetNodeColor() async {
    final nodeState = ref.read(nodeStateProvider);
    final activeNode = nodeState.activeNode;

    if (activeNode != null) {
      Node? rootAncestor = activeNode;
      while (rootAncestor?.parent != null) {
        rootAncestor = rootAncestor!.parent;
      }

      if (rootAncestor != null) {
        NodeColorUtils.forceUpdateNodeColor(ref, rootAncestor);
      }
    }
  }

  void togglePhysics() {
    ref.read(screenProvider.notifier).togglePhysics();
  }

  void toggleNodeTitles() {
    ref.read(screenProvider.notifier).toggleNodeTitles();
  }

  Future<void> deleteActiveNode() async {
    final nodeState = ref.read(nodeStateProvider);
    final activeNode = nodeState.activeNode;
    final nodeStateNotifier = ref.read(nodeStateProvider.notifier);

    if (activeNode != null) {
      await NodeOperations.deleteNode(activeNode, ref);
    }

    nodeStateNotifier.setActiveNode(null);
  }
}
