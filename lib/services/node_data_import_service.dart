import 'package:flutter/material.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_app/utils/json_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../utils/node_operations.dart';

// ノードデータをインポートするサービス
class NodeDataImportService {
  // ノードをインポートする際に、既存のノードを更新するか、新たにIDを振り直すか選択できるようにする
  Future<void> importNodeDataFromFormat({
    required String content,
    required String format,
    required BuildContext context,
    required WidgetRef ref,
    required bool updateExisting, // 既存ノードを更新するかどうかのフラグ
  }) async {
    try {
      // フォーマットに応じた処理を実行
      final importedData = _convertToMap(content, format);

      // ノード情報、ノードマッピング、ノードリンク情報を取り出す
      final nodesList = importedData['nodes'] as List<Map<String, dynamic>>;
      final nodeMaps = importedData['node_maps'] as Map<int, List<int>>;
      final nodeLinkMaps =
          importedData['node_link_maps'] as Map<int, List<int>>;

      // 古いノードIDと新しいNodeオブジェクトの対応を保存するマップ
      final Map<int, Node> idMapping = {};

      // 各ノードを追加、新規作成または更新
      for (var node in nodesList) {
        final oldNodeId = node['id'] as int;
        final title = node['title'] as String;
        final contents = node['contents'] as String;
        final color = Color(node['color']); // 色を文字列からColorに変換

        Node newNode;

        if (updateExisting) {
          // 既存ノードのIDがある場合は更新、ない場合は新規作成
          newNode = await _updateOrCreateNode(
            oldNodeId: oldNodeId,
            title: title,
            contents: contents,
            color: color,
            context: context,
            ref: ref,
          );
        } else {
          // 新しいノードを作成（IDは新たに振り直し）
          newNode = await NodeOperations.addNode(
            context: context,
            ref: ref,
            nodeId: 0, // 新規ID
            title: title,
            contents: contents,
            color: color,
          );
        }

        // 古いノードIDと新しいNodeオブジェクトの対応を保存
        idMapping[oldNodeId] = newNode;
      }

      // ノードマッピングを再構築
      for (var oldParentId in nodeMaps.keys) {
        final oldChildIds = nodeMaps[oldParentId]!;

        // 古いIDを新しいNodeオブジェクトに変換
        final parentNode = idMapping[oldParentId];
        if (parentNode == null) continue;

        for (var oldChildId in oldChildIds) {
          final childNode = idMapping[oldChildId];
          if (childNode == null) continue;

          // 新しいNodeオブジェクトで親子関係を追加
          await NodeOperations.linkChildNode(ref, parentNode.id, childNode);
        }
      }

      // ノードリンクマッピングの処理
      for (var sourceId in nodeLinkMaps.keys) {
        final targetIds = nodeLinkMaps[sourceId]!;

        // ノード間のリンクを作成
        final sourceNode = idMapping[sourceId];
        if (sourceNode == null) continue;

        for (var targetId in targetIds) {
          final targetNode = idMapping[targetId];
          if (targetNode == null) continue;

          // 新しいNodeオブジェクトでリンクを追加
          NodeOperations.linkNode(
              ref: ref, activeNode: sourceNode, hoveredNode: targetNode);
        }
      }
    } catch (e) {
      throw Exception('Error importing node data from $format: $e');
    }
  }

  // 既存ノードを更新するか、新規作成する処理
  Future<Node> _updateOrCreateNode({
    required int oldNodeId,
    required String title,
    required String contents,
    required Color color,
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      final NodesNotifier nodesNotifier = ref.read(nodesProvider.notifier);
      // 既存ノードを検索
      final existingNode = nodesNotifier.findNodeById(oldNodeId);

      if (existingNode != null) {
        // 既存ノードが見つかれば更新
        await NodeOperations.addNode(
          context: context,
          ref: ref,
          nodeId: existingNode.id,
          title: title,
          contents: contents,
          color: color,
        );
        return existingNode;
      } else {
        // 既存ノードが見つからなければ新規作成
        return await NodeOperations.addNode(
          context: context,
          ref: ref,
          nodeId: 0, // 新しいID
          title: title,
          contents: contents,
          color: color,
        );
      }
    } catch (e) {
      throw Exception('Error updating or creating node: $e');
    }
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
