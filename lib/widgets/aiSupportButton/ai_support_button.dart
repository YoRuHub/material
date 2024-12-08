import 'package:flutter/material.dart';

class AiSupportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AiSupportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_awesome), // エクスポート用のアイコン
      tooltip: 'AI Support', // ツールチップ
      onPressed: onPressed,
    );
  }
}
