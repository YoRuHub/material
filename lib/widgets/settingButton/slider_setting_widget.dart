import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SliderSettingWidget extends ConsumerWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd; // タップを離したときの処理を追加
  final VoidCallback onTap;

  const SliderSettingWidget({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Text(title),
          ),
          Text(value.toStringAsFixed(2)),
        ],
      ),
      subtitle: SfSlider(
        min: min,
        max: max,
        value: value,
        interval: (max - min) / 5,
        showTicks: true,
        showLabels: true,
        enableTooltip: true,
        minorTicksPerInterval: 1,
        onChanged: (dynamic newValue) {
          final doubleValue = newValue is double ? newValue : value;
          onChanged(doubleValue); // 値をリアルタイムで反映
        },
        onChangeEnd: (dynamic newValue) {
          final doubleValue = newValue is double ? newValue : value;
          onChangeEnd(doubleValue); // タップを離したときに保存
        },
      ),
    );
  }
}
