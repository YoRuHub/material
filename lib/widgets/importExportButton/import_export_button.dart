import 'package:flutter/material.dart';

class ImportExportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ImportExportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.import_export),
      tooltip: 'Inport/Export Project',
      onPressed: onPressed,
    );
  }
}
