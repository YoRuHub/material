import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onPhysicsToggle;
  final VoidCallback onTitleToggle;

  const ExportButton({
    super.key,
    required this.onPhysicsToggle,
    required this.onTitleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download_outlined), // エクスポート用のアイコン
      tooltip: 'Export Project', // ツールチップ
      onPressed: () {
        Scaffold.of(context).openEndDrawer();
      },
    );
  }
}
