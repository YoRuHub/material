import 'package:flutter/material.dart';
import 'node_tool_type.dart';

class NodeToolWidget {
  final NodeTool tool;
  bool isActive;
  final int id; // ID（順番）を追加

  NodeToolWidget({required this.tool, required this.id, this.isActive = false});

  // ツールがアクティブかどうかを切り替える
  void toggleActive() {
    isActive = !isActive;
  }

  // 描画に使う色（アクティブ状態を反映）
  Color get toolColor {
    return isActive ? tool.color.withOpacity(0.6) : tool.color.withOpacity(0.3);
  }

  // 描画するアイコンを取得
  IconData get icon {
    return tool.icon;
  }

  // ツールの名前を取得
  String get toolName {
    return tool.name;
  }

  // ツールの状態を文字列として返す
  String get status {
    return isActive ? 'Active' : 'Inactive';
  }
}

// NodeToolTypeに基づいてNodeToolを取得するマップ
final Map<NodeToolType, NodeTool> nodeTools = {
  NodeToolType.add: NodeTool(
    type: NodeToolType.add,
    name: 'Add',
    icon: Icons.add,
    color: Colors.grey,
  ),
  NodeToolType.edit: NodeTool(
    type: NodeToolType.edit,
    name: 'Edit',
    icon: Icons.edit,
    color: Colors.grey,
  ),
  NodeToolType.delete: NodeTool(
    type: NodeToolType.delete,
    name: 'Delete',
    icon: Icons.delete,
    color: Colors.red,
  ),
};

// NodeToolTypeに拡張メソッドを追加
extension NodeToolTypeExtension on NodeToolType {
  // NodeToolを取得
  NodeTool get tool => nodeTools[this]!;
}

class NodeTool {
  final NodeToolType type;
  final String name;
  final IconData icon;
  final Color color;

  NodeTool({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
  });

  // アクティブ状態に応じて色を調整
  Color getActiveColor(bool isActive) {
    return isActive ? color.withOpacity(0.6) : color.withOpacity(0.3);
  }
}
