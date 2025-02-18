import 'package:flutter/material.dart';

class SettingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SettingButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: onPressed,
    );
  }
}
