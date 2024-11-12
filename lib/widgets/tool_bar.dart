import 'package:flutter/material.dart';

class ToolBarWidget extends StatefulWidget {
  final Function alignNodesHorizontal;
  final Function alignNodesVertical;
  final bool isAligning;
  final Function detachChildren;
  final Function deleteActiveNode; // 削除用の関数

  const ToolBarWidget({
    super.key,
    required this.alignNodesHorizontal,
    required this.alignNodesVertical,
    required this.isAligning,
    required this.detachChildren,
    required this.deleteActiveNode, // 関数を受け取る
  });

  @override
  ToolBarWidgetState createState() => ToolBarWidgetState();
}

class ToolBarWidgetState extends State<ToolBarWidget> {
  // ホバー状態を管理するための変数
  bool isHoveredAlignHorizontal = false;
  bool isHoveredAlignVertical = false;
  bool isHoveredDetach = false;
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
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    isHoveredAlignHorizontal = true; // ホバー時に色を変更
                  });
                },
                onExit: (_) {
                  setState(() {
                    isHoveredAlignHorizontal = false; // ホバー解除時に元の色に戻す
                  });
                },
                child: IconButton(
                  icon: Icon(
                    Icons.share,
                    color: isHoveredAlignHorizontal || widget.isAligning
                        ? Colors.cyan
                        : Colors.cyan[900],
                    size: 24.0,
                  ),
                  onPressed: () {
                    widget.alignNodesHorizontal(context);
                  },
                ),
              ),
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    isHoveredAlignVertical = true; // ホバー時に色を変更
                  });
                },
                onExit: (_) {
                  setState(() {
                    isHoveredAlignVertical = false; // ホバー解除時に元の色に戻す
                  });
                },
                child: IconButton(
                  icon: RotatedBox(
                    quarterTurns: 1, // 90度回転
                    child: Icon(
                      Icons.share,
                      color: isHoveredAlignVertical || widget.isAligning
                          ? Colors.cyan
                          : Colors.cyan[900],
                      size: 24.0,
                    ),
                  ),
                  onPressed: () {
                    widget.alignNodesVertical(context);
                  },
                ),
              ),
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    isHoveredDetach = true; // ホバー時に色を変更
                  });
                },
                onExit: (_) {
                  setState(() {
                    isHoveredDetach = false; // ホバー解除時に元の色に戻す
                  });
                },
                child: IconButton(
                  icon: Icon(
                    Icons.scatter_plot,
                    color: isHoveredDetach ? Colors.cyan : Colors.cyan[900],
                    size: 24.0,
                  ),
                  onPressed: () {
                    widget.detachChildren(); // ボタンが押されたら削除関数を実行
                  },
                ),
              ),
              MouseRegion(
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
            ],
          ),
        ),
      ),
    );
  }
}
