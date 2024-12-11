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
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

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
            title: '親子ノードの間隔',
            value: settings.parentChildDistance,
            min: 50.0,
            max: 500.0,
            onChanged: (value) {
              settingsNotifier.updateSetting('parent_child_distance', value);
            },
            onChangeEnd: (value) async {
              await _settingsModel
                  .upsertSettings({'parent_child_distance': value});
              (value);
            },
            onTap: () {
              settingsNotifier.resetSetting('parent_child_distance');
            },
          ),

          SliderSettingWidget(
            title: 'リンクノードの間隔',
            value: settings.linkDistance,
            min: 500.0,
            max: 5000.0,
            onChanged: (value) {
              settingsNotifier.updateSetting('link_distance', value);
            },
            onChangeEnd: (value) async {
              await _settingsModel.upsertSettings({'link_distance': value});
              (value);
            },
            onTap: () {
              settingsNotifier.resetSetting('link_distance');
            },
          ),
          SliderSettingWidget(
            title: '親子ノードの引力',
            value: settings.parentChildAttraction,
            min: 0.000,
            max: 100,
            onChanged: (value) {
              settingsNotifier.updateSetting('parent_child_attraction', value);
            },
            onChangeEnd: (value) async {
              await _settingsModel
                  .upsertSettings({'parent_child_attraction': value});
              (value);
            },
            onTap: () {
              settingsNotifier.resetSetting('parent_child_attraction');
            },
          ),
          SliderSettingWidget(
            title: 'リンクノードの引力',
            value: settings.linkAttraction,
            min: 0.000,
            max: 100,
            onChanged: (value) {
              settingsNotifier.updateSetting('link_attraction', value);
            },
            onChangeEnd: (value) async {
              await _settingsModel.upsertSettings({'link_attraction': value});
              (value);
            },
            onTap: () {
              settingsNotifier.resetSetting('link_attraction');
            },
          ),

          // 汎用APIキー入力ウィジェットの利用（Gemini）
          const ApiKeyInputWidget(apiType: 'gemini'),
        ],
      ),
    );
  }
}
