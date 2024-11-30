import 'package:flutter/material.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Corrected class definition
class SettingDrawerWidget extends ConsumerStatefulWidget {
  final VoidCallback onPhysicsToggle;
  final VoidCallback onTitleToggle;

  const SettingDrawerWidget({
    super.key,
    required this.onPhysicsToggle,
    required this.onTitleToggle,
  });

  @override
  SettingDrawerWidgetState createState() => SettingDrawerWidgetState();
}

// Corrected state class name
class SettingDrawerWidgetState extends ConsumerState<SettingDrawerWidget> {
  @override
  void initState() {
    super.initState();
    // 初期設定をロードすることを明示的に確認
    ref.read(settingsNotifierProvider.notifier).loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watchを使用してProviderから値を取得
    final settings = ref.watch(settingsNotifierProvider);
    final idealNodeDistance =
        settings.idealNodeDistance; // SettingsオブジェクトからidealNodeDistanceを取得

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 56.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
          ),

          // ノードの間隔設定
          _buildSliderSetting(
            title: 'ノードの間隔',
            value: idealNodeDistance,
            min: 50.0,
            max: 500.0,
            onChanged: (value) {
              // 値が変更されたときに更新
              ref
                  .read(settingsNotifierProvider.notifier)
                  .updateIdealNodeDistance(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: SfSlider(
              min: min,
              max: max,
              value: value, // 現在の値を表示
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
          ),
          Text(value.toStringAsFixed(2)), // 現在の値を表示
        ],
      ),
    );
  }
}
