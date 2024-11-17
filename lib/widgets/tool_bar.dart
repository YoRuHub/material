import 'package:flutter/material.dart';

class ToolBarWidget extends StatefulWidget {
  final VoidCallback alignNodesHorizontal;
  final VoidCallback alignNodesVertical;
  final VoidCallback detachChildren;
  final VoidCallback detachParent;
  final VoidCallback stopPhysics;
  final VoidCallback showNodeTitle;
  final VoidCallback deleteActiveNode;
  final Function duplicateActiveNode;
  final bool isPhysicsEnabled;

  final bool isTitleVisible;

  const ToolBarWidget({
    super.key,
    required this.alignNodesHorizontal,
    required this.alignNodesVertical,
    required this.detachChildren,
    required this.detachParent,
    required this.stopPhysics,
    required this.showNodeTitle,
    required this.deleteActiveNode,
    required this.duplicateActiveNode,
    required this.isPhysicsEnabled,
    required this.isTitleVisible,
  });

  @override
  ToolBarWidgetState createState() => ToolBarWidgetState();
}

class ToolBarWidgetState extends State<ToolBarWidget> {
  // ホバー状態を管理するマップ
  final Map<String, bool> _isHovered = {
    'alignHorizontal': false,
    'alignVertical': false,
    'detachChildren': false,
    'detachParent': false,
    'duplicate': false,
    'lock': false,
    'showTitle': false,
    'delete': false,
  };

  // アイコンボタンを作成する関数
  Widget buildIconButton({
    required IconData icon,
    required Function onPressed,
    required String action,
    required bool isHovered,
    required bool rotated,
  }) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered[action] = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered[action] = false;
        });
      },
      child: IconButton(
        icon: rotated
            ? RotatedBox(
                quarterTurns: 1, // 90度回転
                child: Icon(
                  icon,
                  color: isHovered ? Colors.cyan : Colors.cyan[900],
                  size: 24.0,
                ),
              )
            : Icon(
                icon,
                color: isHovered ? Colors.cyan : Colors.cyan[900],
                size: 24.0,
              ),
        onPressed: () => onPressed(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 横整列
              buildIconButton(
                icon: Icons.share,
                onPressed: widget.alignNodesHorizontal,
                action: 'alignHorizontal',
                isHovered: _isHovered['alignHorizontal'] ?? false,
                rotated: false,
              ),
              // 縦整列
              buildIconButton(
                icon: Icons.share,
                onPressed: widget.alignNodesVertical,
                action: 'alignVertical',
                isHovered: _isHovered['alignVertical'] ?? false,
                rotated: true,
              ),
              // 子ノード切り離し
              buildIconButton(
                icon: Icons.hdr_weak,
                onPressed: widget.detachChildren,
                action: 'detachChildren',
                isHovered: _isHovered['detachChildren'] ?? false,
                rotated: true,
              ),
              // 親ノード切り離し
              buildIconButton(
                icon: Icons.hdr_strong,
                onPressed: widget.detachParent,
                action: 'detachParent',
                isHovered: _isHovered['detachParent'] ?? false,
                rotated: true,
              ),
              // ノード複製
              buildIconButton(
                icon: Icons.control_point_duplicate,
                onPressed: widget.duplicateActiveNode,
                action: 'duplicate',
                isHovered: _isHovered['duplicate'] ?? false,
                rotated: false,
              ),
              buildIconButton(
                  icon: widget.isTitleVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onPressed: widget.showNodeTitle,
                  action: 'showTitle',
                  isHovered: _isHovered['showTitle']! || widget.isTitleVisible,
                  rotated: false),
              // ノード固定
              buildIconButton(
                icon: widget.isPhysicsEnabled ? Icons.lock_open : Icons.lock,
                onPressed: widget.stopPhysics,
                action: 'lock',
                isHovered: _isHovered['lock']! || !widget.isPhysicsEnabled,
                rotated: false,
              ),
              // ノード削除
              buildIconButton(
                icon: Icons.delete,
                onPressed: widget.deleteActiveNode,
                action: 'delete',
                isHovered: _isHovered['delete'] ?? false,
                rotated: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
