import 'package:flutter/material.dart';

class InportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const InportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.upload_outlined), // エクスポート用のアイコン
      tooltip: 'Inport Project', // ツールチップ
      onPressed: onPressed,
    );
  }
}
