import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/settings_model.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/widgets/settingButton/slider_setting_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class SettingDrawerWidgetState extends ConsumerState<SettingDrawerWidget> {
  late final SettingsModel _settingsModel; // SettingsModelを1回だけ初期化

  @override
  void initState() {
    super.initState();
    ref.read(settingsNotifierProvider.notifier).loadSettings();
    _settingsModel = SettingsModel(); // 初期化
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

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
          SliderSettingWidget(
            title: 'ノードの間隔',
            value: settings.idealNodeDistance,
            min: 50.0,
            max: 500.0,
            onChanged: (value) {
              // ドラッグ中の値をリアルタイム更新
              ref
                  .read(settingsNotifierProvider.notifier)
                  .updateIdealNodeDistance(value);
            },
            onChangeEnd: (value) async {
              // ドラッグ終了時にデータベース更新
              await _settingsModel
                  .updateSettings({'ideal_node_distance': value});
            },
            onTap: () {
              // タイトルタップでリセット
              ref
                  .read(settingsNotifierProvider.notifier)
                  .resetIdealNodeDistance();
            },
          ),
        ],
      ),
    );
  }
}
