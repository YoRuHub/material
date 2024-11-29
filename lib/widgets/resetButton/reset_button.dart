import 'package:flutter/material.dart';

class ResetButton extends StatefulWidget {
  final Function onPressed;

  const ResetButton({super.key, required this.onPressed});

  @override
  ResetButtonState createState() => ResetButtonState();
}

class ResetButtonState extends State<ResetButton> {
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
          onPressed: () => widget.onPressed(),
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Icon(
            Icons.restore_from_trash_outlined,
            color: _isHovered ? Colors.cyan : Colors.cyan[900],
            size: 30,
          ),
        ),
      ),
    );
  }
}
