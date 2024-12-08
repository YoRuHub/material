import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiSupportDrawerWidget extends ConsumerStatefulWidget {
  const AiSupportDrawerWidget({
    super.key,
  });

  @override
  AiSupportDrawerWidgetState createState() => AiSupportDrawerWidgetState();
}

class AiSupportDrawerWidgetState extends ConsumerState<AiSupportDrawerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  controller: null,
                  maxLines: null,
                  expands: true,
                  readOnly: true,
                  style: TextStyle(fontFamily: 'monospace', height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
