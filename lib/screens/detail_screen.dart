// detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/particle_button.dart';

class DetailScreen extends StatelessWidget {
  final int index;

  const DetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Screen ${index + 1}'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 追加: 最小限のサイズで表示
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'tap ${index + 1}!!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ParticleButton(
              text: '',
              icon: Icons.star,
              color: Colors.cyan,
              width: 200.0,
              height: 60.0,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Button ${index + 1} was tapped!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
