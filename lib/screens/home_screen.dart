import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/add_project_button.dart';
import 'package:flutter_app/widgets/project_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/project_provider.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_app/models/project.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // プロジェクトの追加
  Future<void> _addProject(String name) async {
    if (name.isEmpty) {
      if (mounted) {
        SnackBarHelper.error('Project name cannot be empty');
      }
      return;
    }

    try {
      await ref.read(projectNotifierProvider.notifier).addProject(name);
      if (mounted) {
        SnackBarHelper.success('Project added successfully!');
      }
      _nameController.clear();
    } catch (e) {
      if (mounted) {
        SnackBarHelper.error('Failed to add project: $e');
      }
    }
  }

  // プロジェクトの編集
  Future<void> _editProject(Project project) async {
    final TextEditingController editController =
        TextEditingController(text: project.title);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Project'),
          content: TextField(
            controller: editController,
            decoration:
                const InputDecoration(hintText: 'Enter new project name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(projectNotifierProvider.notifier)
                      .editProject(project.id, editController.text);

                  if (mounted) {
                    SnackBarHelper.success('Project edited successfully!');
                  }
                  if (context.mounted) {
                    // Add this check
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarHelper.error('Failed to edit project: $e');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // プロジェクトの削除
  Future<void> _deleteProject(Project project) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text('Are you sure you want to delete "${project.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final navigator = Navigator.of(
                    this.context); // Store the navigator in a local variable
                ref
                    .read(projectNotifierProvider.notifier)
                    .deleteProject(project.id)
                    .then((_) {
                  if (mounted) {
                    SnackBarHelper.success('Project deleted successfully!');
                  }
                  navigator
                      .pop(); // Use the local variable instead of Navigator.of(this.context)
                }).catchError((e) {
                  if (mounted) {
                    SnackBarHelper.error('Failed to delete project: $e');
                  }
                });
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider);
    final filteredProjects = projects
        .where((project) =>
            project.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search projects...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16.0),
            AddProjectButton(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Add Project'),
                      content: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            hintText: 'Enter project name'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await _addProject(_nameController.text);
                            navigator.pop();
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ProjectList(
                projects: filteredProjects,
                onEdit: (index) => _editProject(filteredProjects[index]),
                onDelete: (index) => _deleteProject(filteredProjects[index]),
                onHover: (id, isHovered) => ref
                    .read(projectNotifierProvider.notifier)
                    .updateHoverState(id, isHovered),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
