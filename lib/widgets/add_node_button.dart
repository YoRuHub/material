import 'package:flutter/material.dart';

class AddNodeButton extends StatefulWidget {
  final Function onPressed;

  const AddNodeButton({super.key, required this.onPressed});

  @override
  AddNodeButtonState createState() => AddNodeButtonState();
}

class AddNodeButtonState extends State<AddNodeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8.0,
      right: 8.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: FloatingActionButton(
          onPressed: () => widget.onPressed(), // onPressedを外部から渡す
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Icon(
            Icons.add, // ノード追加アイコン
            color: _isHovered ? Colors.cyan : Colors.cyan[900],
            size: 30,
          ),
        ),
      ),
    );
  }
}
