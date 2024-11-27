import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectTitle;

  const MindMapScreen(
      {super.key, required this.projectId, required this.projectTitle});

  @override
  MindMapScreenState createState() => MindMapScreenState();
}

class MindMapScreenState extends ConsumerState<MindMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: const Center(
        child: Text('Mind Map Screen'),
      ),
    );
  }
}
