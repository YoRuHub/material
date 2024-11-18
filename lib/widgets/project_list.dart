import 'package:flutter/material.dart';
import 'package:flutter_app/models/project.dart';
import 'package:flutter_app/screens/mind_map_screen.dart'; // MindMapScreenのインポート

class ProjectList extends StatefulWidget {
  final List<Project> projects;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final dynamic onHover;

  const ProjectList({
    super.key,
    required this.projects,
    required this.onEdit,
    required this.onDelete,
    required this.onHover,
  });

  @override
  ProjectListState createState() => ProjectListState();
}

class ProjectListState extends State<ProjectList> {
  late List<bool> _isHovered;

  @override
  void initState() {
    super.initState();
    _initializeHoverStates();
  }

  @override
  void didUpdateWidget(ProjectList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // プロジェクトリストが変更された場合、ホバー状態を再初期化
    if (oldWidget.projects.length != widget.projects.length) {
      _initializeHoverStates();
    }
  }

  // ホバー状態リストを初期化
  void _initializeHoverStates() {
    _isHovered = List.generate(widget.projects.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: widget.projects.length,
        itemBuilder: (context, index) {
          final project = widget.projects[index];

          return MouseRegion(
            onEnter: (_) {
              setState(() {
                _isHovered[index] = true; // ホバー状態を更新
              });
            },
            onExit: (_) {
              setState(() {
                _isHovered[index] = false; // ホバー解除
              });
            },
            child: GestureDetector(
              onTap: () {
                // MindMapScreenに遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MindMapScreen(
                        projectId: project.id, projectTitle: project.title),
                  ),
                );
              },
              child: Container(
                width: double.infinity, // 横幅を最大化
                margin: const EdgeInsets.symmetric(vertical: 8.0), // 上下の間隔
                padding: const EdgeInsets.all(16.0), // 内側の余白
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _isHovered[index]
                        ? Theme.of(context).colorScheme.primary // ホバー時の枠線
                        : Colors.transparent,
                    width: 2.0,
                  ),
                  boxShadow: _isHovered[index]
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero, // ListTileの余白を無効化
                  title: Text(
                    project.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    'Last updated: ${project.updatedAt.toLocal().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => widget.onEdit(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => widget.onDelete(index),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
