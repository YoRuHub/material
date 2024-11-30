import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/settings_model.dart';
import 'package:flutter_app/models/settings.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
      : super(Settings(idealNodeDistance: NodeConstants.nodePreferredDistance));

  final _settingsModel = SettingsModel();

  // 初期設定をデータベースから取得
  Future<void> loadSettings() async {
    try {
      final settings = await _settingsModel.fetchAllSettings();
      final idealNodeDistance =
          settings.isNotEmpty && settings.first['ideal_node_distance'] != null
              ? (settings.first['ideal_node_distance'] as num).toDouble()
              : NodeConstants.nodePreferredDistance;

      // 状態を更新
      state = Settings(idealNodeDistance: idealNodeDistance);
    } catch (e) {
      Logger.error('Error loading settings: $e');

      // 初期値に戻す
      state = Settings(idealNodeDistance: NodeConstants.nodePreferredDistance);
    }
  }

  // 設定を更新するメソッド
  Future<void> updateIdealNodeDistance(double newDistance) async {
    try {
      await _settingsModel.updateSettings({'ideal_node_distance': newDistance});

      // 状態を更新
      state = Settings(idealNodeDistance: newDistance);
    } catch (e) {
      Logger.error('Error updating ideal node distance: $e');
    }
  }
}

// プロバイダーの定義
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});
