// lib/widgets/dialogs/project_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/styles.dart';

Future<String?> showProjectDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);

  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter project name',
          ),
        ),
        actions: [
          DialogActionButtons(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () => Navigator.of(context).pop(controller.text),
            confirmText: initialValue == null ? 'Add' : 'Save',
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String projectTitle,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Project'),
      content: Text('Are you sure you want to delete "$projectTitle"?'),
      actions: [
        DialogActionButtons(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          confirmText: 'Delete',
          confirmButtonStyle: DialogButtonStyles.destructive,
        ),
      ],
    ),
  );
}

class DialogActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmText;
  final ButtonStyle? confirmButtonStyle;

  const DialogActionButtons({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmText,
    this.confirmButtonStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: DialogButtonStyles.cancel,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: ElevatedButton(
            style: confirmButtonStyle ?? DialogButtonStyles.confirm,
            onPressed: onConfirm,
            child: Text(confirmText),
          ),
        ),
      ],
    );
  }
}
