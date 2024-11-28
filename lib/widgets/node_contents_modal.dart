import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_app/widgets/color_picker_dialog.dart';
import 'package:flutter_app/widgets/snackbar/snackbar_helper.dart';
import 'package:flutter_app/widgets/spherical_color_widget.dart';

class NodeContentsPanel extends StatefulWidget {
  final Node node;
  final NodeModel nodeModel;
  final Function(Node) onNodeUpdated; // コールバック関数

  const NodeContentsPanel({
    super.key,
    required this.node,
    required this.nodeModel,
    required this.onNodeUpdated,
  });

  @override
  NodeContentsPanelState createState() => NodeContentsPanelState();
}

class NodeContentsPanelState extends State<NodeContentsPanel> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  bool _isHoveringTitle = false;
  bool _isHoveringContent = false;
  Color _selectedColor = Colors.blue; // 初期値として青を設定

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.node.title);
    contentController = TextEditingController(text: widget.node.contents);
    _selectedColor = widget.node.color; // ノードの色を初期値に設定
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    try {
      await widget.nodeModel.upsertNode(
        widget.node.id,
        titleController.text,
        contentController.text,
        _selectedColor, // 選択された色を保存
        widget.node.projectId,
      );

      widget.onNodeUpdated(
        widget.node
          ..title = titleController.text
          ..contents = contentController.text
          ..color = _selectedColor,
      );

      if (mounted) {
        SnackBarHelper.success(context, "Node saved successfully!");
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error(context, "Failed to save node: $e");
      }
    }
  }

  void _clearContent() {
    setState(() {
      titleController.clear();
      contentController.clear();
    });
  }

  Future<void> _pickColor() async {
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(
        availableColors: NodeColorUtils.generateColorsForGenerations(18),
        selectedColor: _selectedColor,
        onColorSelected: (color) {
          setState(() {
            if (color == null) {
              // nullが選ばれた場合、世代に基づいて色を再設定;
              _selectedColor =
                  NodeColorUtils.getColorForCurrentGeneration(widget.node);
            } else {
              // 色が選ばれた場合
              _selectedColor = color;
            }
          });
        },
      ),
    );

    if (pickedColor != null) {
      setState(() {
        // 透明色（色なし）を選んだ場合、世代に基づいて色を再設定
        if (pickedColor == Colors.transparent) {
          _selectedColor =
              NodeColorUtils.getColorForCurrentGeneration(widget.node);
        } else {
          _selectedColor = pickedColor;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      width: MediaQuery.of(context).size.width / 3,
      height: MediaQuery.of(context).size.height / 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringTitle = true),
                  onExit: (_) => setState(() => _isHoveringTitle = false),
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      fillColor: _isHoveringTitle
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.secondary,
                      filled: true,
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.edit),
                      labelText: 'Title',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringContent = true),
                    onExit: (_) => setState(() => _isHoveringContent = false),
                    child: TextField(
                      controller: contentController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 13,
                      decoration: InputDecoration(
                        fillColor: _isHoveringContent
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.secondary,
                        filled: true,
                        border: InputBorder.none,
                        hintText: "Content",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SphericalColorWidget(
                      color: _selectedColor,
                      isSelected: true,
                      checkIcon: Icons.palette,
                      onTap: _pickColor,
                    ),
                    const SizedBox(width: 8), // ボタン間のスペース
                    // Clearボタン
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 8), // ボタン間のスペース
                    // Saveボタン
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveContent();
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
