import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/utils/node_color_utils.dart';
import 'package:flutter_app/widgets/nodeContentsModal/colorPickerDialog/color_picker_dialog.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_app/widgets/nodeContentsModal/colorPickerDialog/spherical_color_widget.dart';

class NodeContentsPanel extends StatefulWidget {
  final Node node;
  final NodeModel nodeModel;
  final Function(Node) onNodeUpdated;

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

  Color _selectedColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.node.title);
    contentController = TextEditingController(text: widget.node.contents);
    _selectedColor = widget.node.color ?? Colors.blue;
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
        _selectedColor,
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
              _selectedColor =
                  NodeColorUtils.getColorForCurrentGeneration(widget.node);
            } else {
              _selectedColor = color;
            }
          });
        },
      ),
    );

    if (pickedColor != null) {
      setState(() {
        _selectedColor = pickedColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面サイズを取得
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // widthとheightに条件を加えて500より下回らないように設定
    double panelWidth = screenWidth / 3;
    double panelHeight = screenHeight / 2;

    panelWidth = panelWidth < 300 ? 300 : panelWidth;
    panelHeight = panelHeight < 500 ? 500 : panelHeight;

    return Positioned(
      top: 0,
      right: 0,
      width: panelWidth,
      height: panelHeight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.edit,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.5)),
                      labelText: 'Title',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: MouseRegion(
                    child: TextField(
                      style: Theme.of(context).textTheme.bodyLarge,
                      controller: contentController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 13,
                      decoration: InputDecoration(
                        fillColor: Theme.of(context).colorScheme.surface,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
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
                    const SizedBox(width: 8),
                    // Clearボタン
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Saveボタン
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveContent();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
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
