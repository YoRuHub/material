import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final List<Color> availableColors;
  final Color? selectedColor; // Color? に変更
  final ValueChanged<Color?> onColorSelected; // Color? に変更

  const ColorPickerDialog({
    super.key,
    required this.availableColors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  // アイコンの色を選択された色に基づいて計算するメソッド
  Color _getIconColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    // 明度が50%以上なら黒、50%未満なら白
    return hslColor.lightness > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Pick a color'),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              onColorSelected(null); // 色をnullに設定
              Navigator.of(context).pop(); // ダイアログを閉じる
            },
          ),
        ],
      ),
      content: SizedBox(
        height: 150, // 高さを固定して、スクロール可能にする
        width: 300, // 必要に応じて調整
        child: GridView.builder(
          shrinkWrap: true, // 必要なだけアイテムを表示する
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6, // 6列
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: availableColors.length,
          itemBuilder: (context, index) {
            final color = availableColors[index];

            // 色なし（透明色）の場合
            if (color == Colors.transparent) {
              return GestureDetector(
                onTap: () {
                  onColorSelected(color); // 色を選択
                  Navigator.of(context).pop(); // ダイアログを閉じる
                },
                child: CircleAvatar(
                  radius: 25.0,
                  backgroundColor: color,
                  child: const Icon(
                    Icons.clear, // 色なしのアイコン
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              );
            }

            // アイコンの色を計算
            Color iconColor = _getIconColor(color);

            return GestureDetector(
              onTap: () {
                onColorSelected(color); // 色を選択
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: CircleAvatar(
                radius: 25.0,
                backgroundColor: color,
                child: selectedColor == color
                    ? Icon(
                        Icons.check,
                        color: iconColor, // アイコンの色を動的に設定
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
