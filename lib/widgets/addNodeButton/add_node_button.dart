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
        bottom: 0.0,
        left: 0.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: FloatingActionButton(
              onPressed: () => widget.onPressed(),
              backgroundColor: Theme.of(context).colorScheme.onSurface,
              child: Icon(
                Icons.add, // ノード追加アイコン
                color: _isHovered
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                size: 30,
              ),
            ),
          ),
        ));
  }
}
