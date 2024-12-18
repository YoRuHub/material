import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/screen_provider.dart';

class PositionedText extends ConsumerWidget {
  const PositionedText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // screenProviderからオフセット、スケール、モード状態を取得
    final screenState = ref.watch(screenProvider);
    final isPositionVisible = ref.watch(screenProvider).isPositionVisible;
    final theme = Theme.of(context);

    // 表示用のテキストを作成
    final String positionText =
        'X: ${screenState.offset.dx.toStringAsFixed(1)}  '
        'Y: ${screenState.offset.dy.toStringAsFixed(1)}  '
        'Scale: ${screenState.scale.toStringAsFixed(2)}  '
        'Mode: ${_getModeText(screenState)}';

    return Positioned(
      top: 0,
      left: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                ref.read(screenProvider.notifier).togglePositionVisibility();
              },
              child: Icon(
                isPositionVisible ? Icons.visibility : Icons.visibility_off,
                color: theme.colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 8),
            if (isPositionVisible)
              Text(
                positionText,
                style: TextStyle(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// モードの状態をテキストとして返す
  String _getModeText(screenState) {
    String modeText = '';

    if (screenState.isLinkMode) {
      modeText += 'Link ';
    }

    if (!screenState.isPhysicsEnabled) {
      modeText += 'Stop ';
    }

    if (modeText.isEmpty) {
      modeText = 'None';
    }
    return modeText.trim(); // 余分な空白を削除
  }
}
