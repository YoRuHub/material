import 'package:flutter/material.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_app/utils/json_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../providers/screen_provider.dart';
import '../utils/node_operations.dart';

// ノードデータをインポートするサービス
class NodeDataImportService {
  // ノードをインポートする際の処理
  Future<void> importNodeDataFromFormat({
    required String content,
    required String format,
    required BuildContext context,
    required WidgetRef ref,
    required bool updateExisting, // 既存ノードを更新するかどうかのフラグ
  }) async {
    try {
      // フォーマットに応じたデータ変換
      final importedData = _convertToMap(content, format);

      // 必要なデータを抽出
      final nodesList = importedData['nodes'] as List<Map<String, dynamic>>;
      final nodeMaps = importedData['node_maps'] as Map<int, List<int>>;
      final nodeLinkMaps =
          importedData['node_link_maps'] as Map<int, List<int>>;

      final Map<int, Node> idMapping = {}; // 古いノードIDと新しいノードIDのマッピング

      if (updateExisting) {
        await _updateExistingNodes(ref);
      }

      // ノードのインポート処理
      await _importNodes(nodesList, ref, idMapping, updateExisting);

      // 親子関係の再構築
      await _rebuildNodeParentChildRelations(nodeMaps, idMapping, ref);

      // ノードリンクの設定
      await _setNodeLinks(nodeLinkMaps, idMapping, ref);
    } catch (e) {
      throw Exception('Error importing node data from $format: $e');
    }
  }

  // 既存ノードを削除する処理
  Future<void> _updateExistingNodes(WidgetRef ref) async {
    final projectId = ref.read(screenProvider).projectNode?.id ?? 0;
    final currentNodeList = ref
        .read(nodesProvider.notifier)
        .findNodeByProjectId(projectId: projectId);
    for (var currentNode in currentNodeList) {
      await NodeOperations.deleteNode(
          targetNodeId: currentNode.id, ref: ref, projectId: projectId);
    }
  }

  // ノードをインポートしてマッピングする処理
  Future<void> _importNodes(
    List<Map<String, dynamic>> nodesList,
    WidgetRef ref,
    Map<int, Node> idMapping,
    bool updateExisting,
  ) async {
    for (var node in nodesList) {
      final oldNodeId = node['id'] as int;
      final title = node['title'] as String;
      final contents = node['contents'] as String;
      final color = Color(node['color']); // 色を文字列からColorに変換

      Node? parentNode;
      if (node.containsKey('parent_id') && node['parent_id'] != null) {
        final parentId = node['parent_id'] as int;
        parentNode = idMapping[parentId]; // idMappingから親ノードを取得
      }

      final newNode = updateExisting
          ? await _updateOrCreateNode(
              oldNodeId: oldNodeId,
              title: title,
              contents: contents,
              color: color,
              ref: ref,
              parentNode: parentNode)
          : await _createNewNode(
              title: title,
              contents: contents,
              color: color,
              ref: ref,
              parentNode: parentNode);

      idMapping[oldNodeId] = newNode;
    }
  }

  // 親子関係を再構築する処理
  Future<void> _rebuildNodeParentChildRelations(
    Map<int, List<int>> nodeMaps,
    Map<int, Node> idMapping,
    WidgetRef ref,
  ) async {
    for (var oldParentId in nodeMaps.keys) {
      final oldChildIds = nodeMaps[oldParentId]!;
      final parentNode = idMapping[oldParentId];
      if (parentNode == null) continue;

      for (var oldChildId in oldChildIds) {
        final childNode = idMapping[oldChildId];
        if (childNode == null) continue;

        await NodeOperations.linkChildNode(ref, parentNode.id, childNode);
      }
    }
  }

  // ノード間リンクを設定する処理
  Future<void> _setNodeLinks(
    Map<int, List<int>> nodeLinkMaps,
    Map<int, Node> idMapping,
    WidgetRef ref,
  ) async {
    for (var sourceId in nodeLinkMaps.keys) {
      final targetIds = nodeLinkMaps[sourceId]!;
      final sourceNode = idMapping[sourceId];
      if (sourceNode == null) continue;

      for (var targetId in targetIds) {
        final targetNode = idMapping[targetId];
        if (targetNode == null) continue;

        await NodeOperations.linkNode(
            ref: ref, activeNode: sourceNode, hoveredNode: targetNode);
      }
    }
  }

  // ノードを新規作成する処理
  Future<Node> _createNewNode({
    required String title,
    required String contents,
    required Color color,
    required WidgetRef ref,
    Node? parentNode,
  }) async {
    return await NodeOperations.addNode(
      ref: ref,
      nodeId: 0, // 新規ID
      title: title,
      contents: contents,
      color: color,
      parentNode: parentNode,
    );
  }

  // 既存ノードを更新または新規作成する処理
  Future<Node> _updateOrCreateNode({
    required int oldNodeId,
    required String title,
    required String contents,
    required Color color,
    required WidgetRef ref,
    Node? parentNode,
  }) async {
    final NodesNotifier nodesNotifier = ref.read(nodesProvider.notifier);
    final existingNode = nodesNotifier.findNodeById(oldNodeId);

    return await NodeOperations.addNode(
      ref: ref,
      nodeId: existingNode?.id ?? 0, // 既存ノードがあればそのIDを使用、なければ新規作成
      title: title,
      contents: contents,
      color: color,
      parentNode: parentNode,
    );
  }

  // フォーマットに応じた変換処理
  Map<String, dynamic> _convertToMap(String content, String format) {
    switch (format.toLowerCase()) {
      case 'yaml':
        return YamlConverter.importYamlToMap(content);
      case 'json':
        return JsonConverter.importJsonToMap(content);
      default:
        throw Exception('Unsupported format: $format');
    }
  }
}
