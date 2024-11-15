import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';

class NodeContentsPanel extends StatelessWidget {
  final Node node;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final NodeModel nodeModel; // Define the nodeModel variable here

  NodeContentsPanel({
    super.key,
    required this.node,
    required this.nodeModel,
  })  : titleController = TextEditingController(text: node.title),
        contentController = TextEditingController(text: node.contents) {}

  // Saveボタンの機能を定義
  Future<void> _saveContent() async {
    await nodeModel.upsertNode(
        node.id, titleController.text, contentController.text);
  }

  // Clearボタンの機能を定義
  void _clearContent() {
    titleController.clear();
    contentController.clear();
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
            borderRadius: BorderRadius.circular(12), // 角を丸くする
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル入力欄の追加
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                      fillColor: Colors.black.withOpacity(0.2),
                      filled: true,
                      border: InputBorder.none,
                      hoverColor: Colors.black.withOpacity(0.2),
                      prefixIcon: const Icon(Icons.edit),
                      labelText: 'Title'),
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
                      hoverColor: Colors.black.withOpacity(0.2),
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
                        // Do something after saving is complete
                      },
                      child: const Text('Save'),
                    )
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
