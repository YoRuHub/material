import 'package:flutter/material.dart';
import 'package:flutter_app/constants/dialog_button_styles.dart';

Future<String?> showProjectDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  final focusNode = FocusNode(); // FocusNodeを作成

  return await showDialog<String>(
    context: context,
    builder: (context) {
      // ダイアログがビルドされた後にフォーカスを設定
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(focusNode); // 自動でフォーカスを設定
      });

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          focusNode: focusNode, // FocusNodeをTextFieldに関連付け
          decoration: const InputDecoration(
            hintText: 'Enter project name',
          ),
        ),
        actions: [
          DialogActionButtons(
            onCancel: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
            },
            onConfirm: () {
              Navigator.of(context).pop(controller.text); // 入力されたテキストを返す
            },
            confirmText: initialValue == null ? 'Add' : 'Save',
          ),
        ],
      );
    },
  );
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
          onCancel: () {
            Navigator.of(context).pop(false); // キャンセル時にfalseを返す
          },
          onConfirm: () {
            Navigator.of(context).pop(true); // 確認時にtrueを返す
          },
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
