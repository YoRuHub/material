import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/project/project_manager_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: Row(
        children: [
          // 左半分にProjectManagerWidgetを配置
          const Expanded(
            flex: 1, // 左半分を占める
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: ProjectManagerWidget(),
            ),
          ),
          // 右半分を空白として残す
          Expanded(
            flex: 1, // 右半分を占める
            child: Container(), // 必要に応じて別のウィジェットを配置可能
          ),
        ],
      ),
    );
  }
}
