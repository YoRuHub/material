// lib/widgets/setting_drawer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_key_input_widget.dart';
import '../../database/models/settings_model.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settingButton/slider_setting_widget.dart';

class SettingDrawerWidget extends ConsumerStatefulWidget {
  const SettingDrawerWidget({super.key});

  @override
  SettingDrawerWidgetState createState() => SettingDrawerWidgetState();
}

class SettingDrawerWidgetState extends ConsumerState<SettingDrawerWidget> {
  late final SettingsModel _settingsModel;

  @override
  void initState() {
    super.initState();
    ref.read(settingsNotifierProvider.notifier).loadSettings();
    _settingsModel = SettingsModel();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ヘッダー
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ノード間隔設定セクション
          SliderSettingWidget(
            title: 'ノードの間隔',
            value: settings.idealNodeDistance,
            min: 50.0,
            max: 500.0,
            onChanged: (value) {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .updateIdealNodeDistance(value);
            },
            onChangeEnd: (value) async {
              await _settingsModel
                  .updateSettings({'ideal_node_distance': value});
            },
            onTap: () {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .resetIdealNodeDistance();
            },
          ),

          // 汎用APIキー入力ウィジェットの利用（Gemini）
          const ApiKeyInputWidget(apiType: 'Gemini'),
        ],
      ),
    );
  }
}
