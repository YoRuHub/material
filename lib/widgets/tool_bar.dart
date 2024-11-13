import 'package:flutter/material.dart';

class ToolBarWidget extends StatefulWidget {
  final VoidCallback alignNodesHorizontal;
  final VoidCallback alignNodesVertical;
  final VoidCallback detachChildren;
  final VoidCallback stopPhysics;
  final VoidCallback deleteActiveNode;
  final bool isAligningHorizontal;
  final bool isAligningVertical;
  final bool isPhysicsEnabled;

  const ToolBarWidget({
    super.key,
    required this.alignNodesHorizontal,
    required this.alignNodesVertical,
    required this.detachChildren,
    required this.stopPhysics,
    required this.deleteActiveNode,
    required this.isAligningHorizontal,
    required this.isAligningVertical,
    required this.isPhysicsEnabled,
  });

  @override
  ToolBarWidgetState createState() => ToolBarWidgetState();
}

class ToolBarWidgetState extends State<ToolBarWidget> {
  // ホバー状態を管理するマップ
  final Map<String, bool> _isHovered = {
    'alignHorizontal': false,
    'alignVertical': false,
    'detach': false,
    'delete': false,
    'lock': false,
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
              buildIconButton(
                icon: Icons.share,
                onPressed: widget.alignNodesHorizontal,
                action: 'alignHorizontal',
                isHovered: _isHovered['alignHorizontal']! ||
                    widget.isAligningHorizontal,
                rotated: false,
              ),
              buildIconButton(
                icon: Icons.share,
                onPressed: widget.alignNodesVertical,
                action: 'alignVertical',
                isHovered:
                    _isHovered['alignVertical']! || widget.isAligningVertical,
                rotated: true,
              ),
              buildIconButton(
                icon: Icons.scatter_plot,
                onPressed: widget.detachChildren,
                action: 'detach',
                isHovered: _isHovered['detach'] ?? false,
                rotated: false,
              ),
              buildIconButton(
                icon: widget.isPhysicsEnabled ? Icons.lock : Icons.lock_open,
                onPressed: widget.stopPhysics,
                action: 'lock',
                isHovered: _isHovered['lock']! || widget.isPhysicsEnabled,
                rotated: false,
              ),
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
