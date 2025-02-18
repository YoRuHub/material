import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/settings_model.dart';
import 'package:flutter_app/models/settings.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
      : super(Settings(
            parentChildDistance: NodeConstants.parentChildDistance,
            linkDistance: NodeConstants.linkDistance,
            parentChildAttraction: NodeConstants.parentChildAttraction,
            linkAttraction: NodeConstants.linkAttraction));

  final _settingsModel = SettingsModel();

  /// 初期設定をデータベースから取得
  Future<void> loadSettings() async {
    try {
      final settings = await _settingsModel.fetchAllSettings();
      final parentChildDistance = _getSettingValue(
        settings,
        'parent_child_distance',
        NodeConstants.parentChildDistance,
      );
      final linkDistance = _getSettingValue(
        settings,
        'link_distance',
        NodeConstants.linkDistance,
      );
      final parentChildAttraction = _getSettingValue(
        settings,
        'parent_child_attraction',
        NodeConstants.parentChildAttraction,
      );
      final linkAttraction = _getSettingValue(
        settings,
        'link_attraction',
        NodeConstants.linkAttraction,
      );

      state = state.copyWith(
        parentChildDistance: parentChildDistance,
        linkDistance: linkDistance,
        parentChildAttraction: parentChildAttraction,
        linkAttraction: linkAttraction,
      );
    } catch (e) {
      _handleError('Error loading settings', e);
    }
  }

  /// 設定値を更新
  Future<void> updateSetting(String settingKey, double value) async {
    await _updateOrResetSetting(settingKey, value);
  }

  /// 設定値をリセット
  Future<void> resetSetting(String settingKey) async {
    double defaultValue;
    if (settingKey == 'parent_child_distance') {
      defaultValue = NodeConstants.parentChildDistance;
    } else if (settingKey == 'link_distance') {
      defaultValue = NodeConstants.linkDistance;
    } else if (settingKey == 'parent_child_attraction') {
      defaultValue = NodeConstants.parentChildAttraction;
    } else if (settingKey == 'link_attraction') {
      defaultValue = NodeConstants.linkAttraction;
    } else {
      throw ArgumentError('Unknown setting key: $settingKey');
    }

    await _updateOrResetSetting(settingKey, defaultValue);
  }

  /// 設定値の更新・リセットを共通化
  Future<void> _updateOrResetSetting(String settingKey, double value) async {
    try {
      if (settingKey == 'parent_child_distance') {
        state = state.copyWith(parentChildDistance: value);
      } else if (settingKey == 'link_distance') {
        state = state.copyWith(linkDistance: value);
      } else if (settingKey == 'parent_child_attraction') {
        state = state.copyWith(parentChildAttraction: value);
      } else if (settingKey == 'link_attraction') {
        state = state.copyWith(linkAttraction: value);
      }

      await _settingsModel.upsertSettings({settingKey: value});
    } catch (e) {
      _handleError('Error updating $settingKey', e);
    }
  }

  /// データベースから設定値を取得するヘルパー関数
  double _getSettingValue(
      List<Map<String, dynamic>> settings, String key, double defaultValue) {
    return settings.isNotEmpty && settings.first[key] != null
        ? (settings.first[key] as num).toDouble()
        : defaultValue;
  }

  /// エラーハンドリングの共通処理
  void _handleError(String message, dynamic error) {
    Logger.error('$message: $error');
    // エラーハンドリングの処理が必要な場合ここで追加できます
  }
}

// プロバイダーの定義
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});
