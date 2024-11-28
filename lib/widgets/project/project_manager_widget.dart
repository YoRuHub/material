import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/project/project_dialog.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/project_provider.dart';
import 'package:flutter_app/models/project.dart';
import 'package:flutter_app/widgets/project/add_project_button.dart';
import 'package:flutter_app/widgets/project/project_list.dart';
import 'package:flutter_app/widgets/project/project_search_field.dart';

class ProjectManagerWidget extends ConsumerStatefulWidget {
  const ProjectManagerWidget({super.key});

  @override
  ProjectManagerWidgetState createState() => ProjectManagerWidgetState();
}

class ProjectManagerWidgetState extends ConsumerState<ProjectManagerWidget> {
  final TextEditingController _nameController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addProject(String name) async {
    if (name.isEmpty) {
      _showWarning("Project name cannot be empty.");
      return;
    }

    await _handleProjectOperation(
      () => ref.read(projectNotifierProvider.notifier).addProject(name),
      'Project added successfully!',
    );
    if (mounted) _nameController.clear();
  }

  Future<void> _editProject(Project project) async {
    final String? newName = await showProjectDialog(
      context: context,
      title: 'Edit Project',
      initialValue: project.title,
    );

    if (newName != null && newName.isNotEmpty) {
      await _handleProjectOperation(
        () => ref
            .read(projectNotifierProvider.notifier)
            .editProject(project.id, newName),
        'Project edited successfully!',
      );
    } else if (newName?.isEmpty ?? false) {
      _showWarning("Project name cannot be empty.");
    }
  }

  Future<void> _deleteProject(Project project) async {
    final bool? confirmed = await showDeleteConfirmationDialog(
      context: context,
      projectTitle: project.title,
    );

    if (confirmed == true) {
      await _handleProjectOperation(
        () => ref
            .read(projectNotifierProvider.notifier)
            .deleteProject(project.id),
        'Project deleted successfully!',
      );
    }
  }

  Future<void> _handleProjectOperation(
    Future<void> Function() operation,
    String successMessage,
  ) async {
    try {
      await operation();
      if (mounted) SnackBarHelper.success(context, successMessage);
    } catch (e) {
      if (mounted) SnackBarHelper.error(context, "Operation failed: $e");
    }
  }

  void _showWarning(String message) {
    if (mounted) SnackBarHelper.warning(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider);
    final filteredProjects = projects
        .where((project) =>
            project.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        ProjectSearchField(
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 16.0),
        AddProjectButton(
          onTap: () async {
            final String? name = await showProjectDialog(
              context: context,
              title: 'Add Project',
            );
            if (name != null) {
              await _addProject(name);
            }
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
    );
  }
}
