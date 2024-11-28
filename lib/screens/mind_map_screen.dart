import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/background_provider.dart';
import '../controllers/node_canvas_controller.dart';
import '../widgets/position_indicator.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectTitle;

  const MindMapScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  MindMapScreenState createState() => MindMapScreenState();
}

class MindMapScreenState extends ConsumerState<MindMapScreen> {
  late NodeCanvasController _controller;

  @override
  void initState() {
    super.initState();
    final background = ref.read(backgroundProvider);
    _controller = NodeCanvasController(background);
  }

  @override
  Widget build(BuildContext context) {
    final background = ref.watch(backgroundProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: GestureDetector(
        onPanStart: _controller.handlePanStart,
        onPanUpdate: _controller.handlePanUpdate,
        onPanEnd: (_) => _controller.handlePanEnd(),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _controller.handleScaleUpdate(
                event.scrollDelta.dy,
                MediaQuery.of(context).size,
              );
            }
          },
          child: Stack(
            children: [
              // Your mind map canvas would go here
              Positioned.fill(
                child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor),
              ),
              PositionIndicator(background: background),
            ],
          ),
        ),
      ),
    );
  }
}
