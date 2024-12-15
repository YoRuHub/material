import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node_map.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/models/node_link_map_model.dart';
import '../../models/node_link_map.dart';
import '../../providers/screen_provider.dart';

class ExportDrawerWidget extends ConsumerStatefulWidget {
  const ExportDrawerWidget({
    super.key,
  });

  @override
  ExportDrawerWidgetState createState() => ExportDrawerWidgetState();
}

class ExportDrawerWidgetState extends ConsumerState<ExportDrawerWidget> {
  late final TextEditingController _yamlController;
  String _yamlContent = 'Loading nodes...';

  @override
  void initState() {
    super.initState();
    _yamlController = TextEditingController(text: _yamlContent);
    _initializeNodeYaml();
  }

  Future<void> _initializeNodeYaml() async {
    try {
      final projectId = ref.read(screenProvider).projectNode?.id ?? 0;
      final NodeModel nodeModel = NodeModel();
      final nodeList = await nodeModel.fetchAllNodes(projectId);

      final NodeMapModel nodeMapModel = NodeMapModel();
      final List<NodeMap> rawNodeMapList =
          await nodeMapModel.fetchAllNodeMap(projectId);

      final nodeLinkMapModel = NodeLinkMapModel();
      final List<NodeLinkMap> rawNodeLinkMapList =
          await nodeLinkMapModel.fetchAllNodeMap(projectId);

      // NodeMap を Map<String, dynamic> に変換
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

      // YamlConverterを使用して変換
      final yamlString = YamlConverter.convertNodesToYaml(
          nodeList, nodeMapList, nodeLinkMapList);

      setState(() {
        _yamlContent = yamlString;
        _yamlController.text = _yamlContent;
      });
    } catch (e) {
      Logger.error('Error converting nodes and maps to YAML: $e');
      setState(() {
        _yamlContent = 'Error loading YAML: $e';
        _yamlController.text = _yamlContent;
      });
    }
  }

  @override
  void dispose() {
    _yamlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _yamlController.text));
                  SnackBarHelper.success(context, 'YAML copied to clipboard');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy YAML'),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _yamlController,
                  maxLines: null,
                  expands: true,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Center(
                      child: Text(
                        'YAML Content',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
