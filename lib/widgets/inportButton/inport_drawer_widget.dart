import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node_map.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

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
      // YAML をパース
      final yamlMap = loadYaml(yamlContent);

      // `nodes` キーをリストとして取得
      if (yamlMap is Map && yamlMap.containsKey('nodes')) {
        final nodes = yamlMap['nodes'] as Map;

        // 各ノードをループ処理
        nodes.forEach((key, value) {
          if (value is Map) {
            final title = value['title'];
            final contents = value['contents'];
            final color = value['color'];

            Logger.info('Node $key:');
            Logger.info('  Title: $title');
            Logger.info('  Contents: $contents');
            Logger.info('  Color: $color');

            // 必要に応じてデータを保存や処理
            // ...
          }
        });

        SnackBarHelper.success(
            context, 'YAML imported and processed successfully.');
      } else {
        SnackBarHelper.error(
            context, 'Invalid YAML format: Missing "nodes" key.');
      }
    } catch (e) {
      Logger.error('Error importing YAML: $e');
      SnackBarHelper.error(context, 'Failed to import YAML: $e');
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
                onPressed: _importYaml,
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
