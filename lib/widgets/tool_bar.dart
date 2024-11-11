import 'package:flutter/material.dart';

class ToolBarWidget extends StatefulWidget {
  final Function alignNodes;
  final bool isAligning;
  final Function deleteActiveNode; // 削除用の関数

  const ToolBarWidget({
    super.key,
    required this.alignNodes,
    required this.isAligning,
    required this.deleteActiveNode, // 関数を受け取る
  });

  @override
  _ToolBarWidgetState createState() => _ToolBarWidgetState();
}

class _ToolBarWidgetState extends State<ToolBarWidget> {
  // ホバー状態を管理するための変数
  bool isHoveredAlign = false;
  bool isHoveredDelete = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
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
              Tooltip(
                message: '整列',
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      isHoveredAlign = true; // ホバー時に色を変更
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      isHoveredAlign = false; // ホバー解除時に元の色に戻す
                    });
                  },
                  child: IconButton(
                    icon: Icon(
                      Icons.share,
                      color: isHoveredAlign || widget.isAligning
                          ? Colors.cyan
                          : Colors.cyan[900],
                      size: 24.0,
                    ),
                    onPressed: () {
                      widget.alignNodes(context);
                    },
                  ),
                ),
              ),
              Tooltip(
                message: 'ノード削除',
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      isHoveredDelete = true; // ホバー時に色を変更
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      isHoveredDelete = false; // ホバー解除時に元の色に戻す
                    });
                  },
                  child: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: isHoveredDelete ? Colors.cyan : Colors.cyan[900],
                      size: 24.0,
                    ),
                    onPressed: () {
                      widget.deleteActiveNode(); // ボタンが押されたら削除関数を実行
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
