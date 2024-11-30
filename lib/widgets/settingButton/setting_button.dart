import 'package:flutter/material.dart';

class SettingIcon extends StatelessWidget {
  final VoidCallback onPhysicsToggle;
  final VoidCallback onTitleToggle;

  const SettingIcon({
    super.key,
    required this.onPhysicsToggle,
    required this.onTitleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        // Drawerを開く
        Scaffold.of(context).openEndDrawer();
      },
    );
  }
}
