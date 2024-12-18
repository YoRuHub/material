import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/database/models/node_link_map_model.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_app/models/node_map.dart';
import 'package:flutter_app/models/node_link_map.dart';

class NodeDataConversionService {
  // ノードデータをYAML形式に変換する
  Future<String> convertNodeDataToYaml(int projectId) async {
    try {
      // ノード情報の取得
      final NodeModel nodeModel = NodeModel();
      final nodeList = await nodeModel.fetchProjectNodes(projectId);

      // ノードマップ情報の取得
      final NodeMapModel nodeMapModel = NodeMapModel();
      final List<NodeMap> rawNodeMapList =
          await nodeMapModel.fetchAllNodeMap(projectId);

      // ノードリンクマップ情報の取得
      final NodeLinkMapModel nodeLinkMapModel = NodeLinkMapModel();
      final List<NodeLinkMap> rawNodeLinkMapList =
          await nodeLinkMapModel.fetchAllNodeMap(projectId);

      // ノードマップとノードリンクマップの整形
      final nodeMapList = rawNodeMapList.map((nodeMap) {
        return {
          'parent_id': nodeMap.parentId,
          'child_id': nodeMap.childId,
        };
      }).toList();

      final nodeLinkMapList = rawNodeLinkMapList.map((nodeMap) {
        return {
          'source_id': nodeMap.sourceId,
          'target_id': nodeMap.targetId,
        };
      }).toList();

      // YAML形式に変換
      return YamlConverter.convertNodesToYaml(
        nodeList,
        nodeMapList,
        nodeLinkMapList,
      );
    } catch (e) {
      throw Exception('Error converting node data to YAML: $e');
    }
  }
}
