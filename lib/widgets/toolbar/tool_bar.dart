import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/toolbar/toolbar_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/screen_provider.dart';

class ToolBarWidget extends StatefulWidget {
  const ToolBarWidget({super.key});

  @override
  ToolBarWidgetState createState() => ToolBarWidgetState();
}

class ToolBarWidgetState extends State<ToolBarWidget> {
  // ホバー状態を管理するマップ
  final Map<String, bool> _isHovered = {
    'alignNodesHorizontal': false,
    'alignNodesVertical': false,
    'detachChildren': false,
    'detachParent': false,
    'duplicate': false,
    'linkMode': false,
    'resetNodeColor': false,
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
                  color: isHovered
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  size: 24.0,
                ),
              )
            : Icon(
                icon,
                color: isHovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                size: 24.0,
              ),
        onPressed: () => onPressed(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumerを使ってrefを受け取る
    return Consumer(
      builder: (context, ref, child) {
        final isPhysicsEnabled =
            ref.watch(screenProvider.select((state) => state.isPhysicsEnabled));
        final isTitleVisible =
            ref.watch(screenProvider.select((state) => state.isTitleVisible));
        final isLinkMode =
            ref.watch(screenProvider.select((state) => state.isLinkMode));
        final projectId =
            ref.watch(screenProvider.select((state) => state.projectId));
        final toolbarController = ref.watch(toolbarControllerProvider(
          ToolbarControllerParams(
            ref: ref,
            context: context,
            projectId: projectId,
          ),
        ));
        return Positioned(
          top: 40,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 横整列
                  buildIconButton(
                    icon: Icons.share,
                    onPressed: toolbarController.alignNodesHorizontal,
                    action: 'alignNodesHorizontal',
                    isHovered: _isHovered['alignNodesHorizontal'] ?? false,
                    rotated: false,
                  ),
                  // 縦整列
                  buildIconButton(
                    icon: Icons.share,
                    onPressed: toolbarController.alignNodesVertical,
                    action: 'alignNodesVertical',
                    isHovered: _isHovered['alignNodesVertical'] ?? false,
                    rotated: true,
                  ),
                  // 子ノード切り離し
                  buildIconButton(
                    icon: Icons.hdr_weak,
                    onPressed: toolbarController.detachChildren,
                    action: 'detachChildren',
                    isHovered: _isHovered['detachChildren'] ?? false,
                    rotated: true,
                  ),
                  // 親ノード切り離し
                  buildIconButton(
                    icon: Icons.hdr_strong,
                    onPressed: toolbarController.detachParent,
                    action: 'detachParent',
                    isHovered: _isHovered['detachParent'] ?? false,
                    rotated: true,
                  ),
                  // ノード複製
                  buildIconButton(
                    icon: Icons.control_point_duplicate,
                    onPressed: toolbarController.duplicateActiveNode,
                    action: 'duplicate',
                    isHovered: _isHovered['duplicate'] ?? false,
                    rotated: false,
                  ),
                  // リンクモード
                  buildIconButton(
                    icon: isLinkMode ? Icons.link : Icons.link_off,
                    onPressed: toolbarController.toggleLinkMode,
                    action: 'linkMode',
                    isHovered: _isHovered['linkMode']! || isLinkMode,
                    rotated: false,
                  ),
                  // ノードタイトル表示
                  buildIconButton(
                      icon: isTitleVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      onPressed: toolbarController.toggleNodeTitles,
                      action: 'showTitle',
                      isHovered: _isHovered['showTitle']! || isTitleVisible,
                      rotated: false),
                  // ノード色リセット
                  buildIconButton(
                    icon: Icons.color_lens,
                    onPressed: toolbarController.resetNodeColor,
                    action: 'resetNodeColor',
                    isHovered: _isHovered['resetNodeColor'] ?? false,
                    rotated: false,
                  ),
                  // ノード固定
                  buildIconButton(
                    icon: isPhysicsEnabled ? Icons.lock_open : Icons.lock,
                    onPressed: toolbarController.togglePhysics,
                    action: 'lock',
                    isHovered: _isHovered['lock']! || !isPhysicsEnabled,
                    rotated: false,
                  ),
                  // ノード削除
                  buildIconButton(
                    icon: Icons.delete,
                    onPressed: toolbarController.deleteActiveNode,
                    action: 'delete',
                    isHovered: _isHovered['delete'] ?? false,
                    rotated: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
