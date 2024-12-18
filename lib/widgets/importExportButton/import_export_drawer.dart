import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node_map.dart';
import 'package:flutter_app/utils/yaml_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/yaml.dart';
import '../../database/models/node_link_map_model.dart';
import '../../models/node_link_map.dart';
import '../../providers/screen_provider.dart';
import '../../theme/editor_theme.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/node_data_import_service.dart';

class ImportExportDrawer extends ConsumerStatefulWidget {
  const ImportExportDrawer({super.key});

  @override
  ImportExportDrawerState createState() => ImportExportDrawerState();
}

class ImportExportDrawerState extends ConsumerState<ImportExportDrawer>
    with TickerProviderStateMixin {
  late CodeController _codeController;
  late final AnimationController _animationController;
  late final Animation<double> _rotation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // アニメーションコントローラの初期化
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _initializeNodeYaml();
  }

  Future<void> _initializeNodeYaml() async {
    try {
      final projectId = ref.read(screenProvider).projectNode?.id ?? 0;
      final NodeModel nodeModel = NodeModel();
      final nodeList = await nodeModel.fetchProjectNodes(projectId);

      final NodeMapModel nodeMapModel = NodeMapModel();
      final List<NodeMap> rawNodeMapList =
          await nodeMapModel.fetchAllNodeMap(projectId);

      final nodeLinkMapModel = NodeLinkMapModel();
      final List<NodeLinkMap> rawNodeLinkMapList =
          await nodeLinkMapModel.fetchAllNodeMap(projectId);

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

      final yamlString = YamlConverter.convertNodesToYaml(
          nodeList, nodeMapList, nodeLinkMapList);

      setState(() {
        _codeController = CodeController(
          text: yamlString,
          language: yaml,
        );
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error initializing node YAML: $e');
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // コードをクリップボードにコピーするメソッド
  void _copyCodeToClipboard() {
    final text = _codeController.text;
    Clipboard.setData(ClipboardData(text: text));
    SnackBarHelper.success(context, 'YAML copied to clipboard.');
  }

  // インポート処理を実行する
  Future<void> _importData() async {
    final content = _codeController.text.trim();
    if (content.isEmpty) {
      SnackBarHelper.error(context, 'Content is empty.');
      return;
    }

    try {
      final service = NodeDataImportService();
      await service.importNodeDataFromFormat(
        content: content,
        format: 'yaml',
        context: context,
        ref: ref,
        updateExisting: true,
      );
      if (!mounted) return;
      SnackBarHelper.success(context, 'Data imported successfully.');
    } catch (e) {
      Logger.error('Error importing data: $e');
      SnackBarHelper.error(context, 'Failed to import data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            height: 56.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('YAML Import/Export',
                      style: Theme.of(context).textTheme.labelMedium),
                  InkWell(
                    onTap: _copyCodeToClipboard,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text('Copy',
                            style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).colorScheme.onSurface),
          // エディタ部分
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: themes[EditorTheme.githubDarkDimmed]),
              child: SingleChildScrollView(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CodeField(
                        controller: _codeController,
                        textStyle: const TextStyle(fontSize: 16, height: 1.4),
                        minLines: 39,
                      ),
              ),
            ),
          ),
          // アクションボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _importData, // ローディング中は無効化
                    icon: _isLoading
                        ? AnimatedBuilder(
                            key: const ValueKey('refreshIcon'),
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value * 6.3,
                                child: const Icon(Icons.refresh,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : const Icon(Icons.download),
                    label: const Text('Import'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
