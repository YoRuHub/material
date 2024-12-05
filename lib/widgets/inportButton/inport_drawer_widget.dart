import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/providers/node_provider.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/node_operations.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InportDrawerWidget extends ConsumerStatefulWidget {
  final VoidCallback onPhysicsToggle;
  final VoidCallback onTitleToggle;
  final int projectId;

  const InportDrawerWidget({
    super.key,
    required this.onPhysicsToggle,
    required this.onTitleToggle,
    required this.projectId,
  });

  @override
  InportDrawerWidgetState createState() => InportDrawerWidgetState();
}

class InportDrawerWidgetState extends ConsumerState<InportDrawerWidget> {
  late final TextEditingController _yamlController;

  @override
  void initState() {
    super.initState();
    _yamlController = TextEditingController(text: '');
  }

  Future<void> _importYaml() async {
    final yamlContent = _yamlController.text.trim();

    if (yamlContent.isEmpty) {
      SnackBarHelper.error(context, 'YAML content is empty.');
      return;
    }

    try {
      // YAMLデータをMapに変換
      final importedData = YamlConverter.importYamlToMap(yamlContent);

      // ノード情報とマッピングを取り出す
      final nodesList = importedData['nodes'] as List<Map<String, dynamic>>;
      final nodeMaps = importedData['node_maps'] as Map<int, List<int>>;

      // 古いノードIDと新しいNodeオブジェクトの対応を保存するマップ
      final Map<int, Node> idMapping = {};

      // 各ノードを追加し、新しいNodeオブジェクトをマップに登録
      for (var node in nodesList) {
        final oldNodeId = node['id'] as int; // 必要であれば、このキーを確認
        final title = node['title'] as String;
        final contents = node['contents'] as String;

        // 色を文字列からColorに変換
        final Color color = Color(node['color']);

        // 新しいノードを作成
        Node newNode = await NodeOperations.addNode(
          context: context,
          ref: ref,
          projectId: widget.projectId,
          nodeId: 0,
          title: title,
          contents: contents,
          color: color,
        );

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
          ref
              .read(nodesProvider.notifier)
              .addChildToNode(parentNode.id, childNode, widget.projectId);
        }
      }

      if (mounted) {
        SnackBarHelper.success(
          context,
          'YAML imported and processed successfully.',
        );
      }
    } catch (e) {
      Logger.error('Error importing YAML: $e');
      if (mounted) {
        SnackBarHelper.error(context, 'Failed to import YAML: $e');
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      if (!mounted) return;

      if (clipboardData?.text?.isNotEmpty ?? false) {
        setState(() {
          _yamlController.text = clipboardData!.text!;
        });
        SnackBarHelper.success(context, 'YAML pasted from clipboard.');
      } else {
        SnackBarHelper.error(context, 'Clipboard is empty.');
      }
    } catch (e) {
      Logger.error('Error pasting from clipboard: $e');
      if (mounted) {
        SnackBarHelper.error(context, 'Failed to paste from clipboard.');
      }
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
                onPressed: _importYaml, // 修正: 直接 _importYaml を呼び出す
                icon: const Icon(Icons.import_export),
                label: const Text('Import YAML'),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // テキストエリア
                    TextField(
                      controller: _yamlController,
                      maxLines: null,
                      expands: true,
                      readOnly: false, // 編集可能
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Center(
                          child: Text(
                            'Paste YAML Content (Ctrl+V)',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // 右下の丸いペーストボタン
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Tooltip(
                        message: 'Paste from clipboard',
                        child: Material(
                          color: Colors.transparent, // 背景を透明に設定
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _pasteFromClipboard,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: const Icon(Icons.paste, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
