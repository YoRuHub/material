import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';

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

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.node.title);
    contentController = TextEditingController(text: widget.node.contents);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    await widget.nodeModel.upsertNode(
      widget.node.id,
      titleController.text,
      contentController.text,
    );

    // 呼び出し元に変更を通知
    widget.onNodeUpdated(
      widget.node
        ..title = titleController.text
        ..contents = contentController.text,
    );
  }

  void _clearContent() {
    setState(() {
      titleController.clear();
      contentController.clear();
    });
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
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    fillColor: Colors.black.withOpacity(0.2),
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
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: contentController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 13,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Content",
                      fillColor: Colors.black.withOpacity(0.2),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _clearContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.1),
                      ),
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _saveContent();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
