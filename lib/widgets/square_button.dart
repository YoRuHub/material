import 'package:flutter/material.dart';

class SquareButton extends StatefulWidget {
  final String title;
  final IconData icon; // アイコンプロパティを追加
  final Color color;
  final VoidCallback onPressed;

  const SquareButton({
    super.key,
    required this.title,
    required this.icon, // 必須のアイコン引数
    required this.color,
    required this.onPressed,
  });

  @override
  SquareButtonState createState() => SquareButtonState();
}

class SquareButtonState extends State<SquareButton> {
  bool isHovered = false; // ホバー状態を管理

  @override
  Widget build(BuildContext context) {
    Color primaryColor = widget.color; // アイコンに対応する色を使用

    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // ホバー時の変化にアニメーションを追加
          decoration: BoxDecoration(
            color: isHovered ? primaryColor.withOpacity(0.9) : primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.7),
                blurRadius: 24.0,
                spreadRadius: 2.0,
                offset: const Offset(0, 0),
              ),
              if (isHovered)
                BoxShadow(
                  color: primaryColor.withOpacity(0.5),
                  blurRadius: 30.0,
                  spreadRadius: 6.0,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 24, // アイコンサイズ
              ),
              const SizedBox(height: 8), // アイコンとテキストの間のスペース
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
