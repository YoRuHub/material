import 'package:flutter/material.dart';

class CustomIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;

  const CustomIconButton({super.key, required this.icon, this.onPressed});

  @override
  CustomIconButtonState createState() => CustomIconButtonState();
}

class CustomIconButtonState extends State<CustomIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.2),
                offset: Offset(8, _isHovered ? 12 : 8),
                blurRadius: _isHovered ? 20 : 15,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(_isHovered ? 0.2 : 0.1),
                offset: const Offset(-4, -4),
                blurRadius: _isHovered ? 15 : 10,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: widget.icon, // 引数として受け取ったアイコンを表示
              ),
            ),
          ),
        ),
      ),
    );
  }
}
