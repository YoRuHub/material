import 'package:flutter/material.dart';

enum NodeToolType {
  add,
  edit,
  delete,
}

extension NodeToolTypeExtension on NodeToolType {
  // Toolに対応するアイコンを返す
  IconData get icon {
    switch (this) {
      case NodeToolType.add:
        return Icons.add;
      case NodeToolType.edit:
        return Icons.edit;
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
      case NodeToolType.edit:
        return 'Edit';
      case NodeToolType.delete:
        return 'Delete';
      default:
        return 'Unknown';
    }
  }

  // 初期状態の色（アクティブな状態かどうかで変わる）
  Color get color {
    switch (this) {
      case NodeToolType.add:
        return Colors.grey;
      case NodeToolType.edit:
        return Colors.grey;
      case NodeToolType.delete:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
