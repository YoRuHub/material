// setting_drawer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'slider_setting_widget.dart'; // 新しく作成したファイルをインポート

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
            onTap: () {
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
