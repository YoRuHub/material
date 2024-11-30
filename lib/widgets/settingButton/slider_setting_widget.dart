// slider_setting_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/settings_provider.dart';

class SliderSettingWidget extends ConsumerWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onTap;

  const SliderSettingWidget({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
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
          ref
              .read(settingsNotifierProvider.notifier)
              .updateIdealNodeDistance(doubleValue);
        },
      ),
    );
  }
}
