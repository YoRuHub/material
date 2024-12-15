import 'package:flutter/material.dart';

enum NodeToolType {
  join,
  add,
  delete,
}

extension NodeToolTypeExtension on NodeToolType {
  // Toolに対応するアイコンを返す
  IconData get icon {
    switch (this) {
      case NodeToolType.add:
        return Icons.add;
      case NodeToolType.join:
        return Icons.open_in_new;
      case NodeToolType.delete:
        return Icons.delete;
      default:
        return Icons.help;
    }
  }

  // Toolの名前を返す
  String get name {
    switch (this) {
      case NodeToolType.add:
        return 'Add';
      case NodeToolType.join:
        return 'Join';
      case NodeToolType.delete:
        return 'Delete';
      default:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case NodeToolType.add:
        return Colors.grey;
      case NodeToolType.join:
        return Colors.grey;
      case NodeToolType.delete:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
