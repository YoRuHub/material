import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ExportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download_outlined), // エクスポート用のアイコン
      tooltip: 'Export Project', // ツールチップ
      onPressed: onPressed,
    );
  }
}
