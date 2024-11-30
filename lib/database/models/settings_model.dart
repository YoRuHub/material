import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class SettingsModel extends BaseModel {
  static const String table = 'settings';
  static const String columnId = 'id';
  static const String columnIdealNodeDistance = 'ideal_node_distance';

  /// プロジェクト全件取得
  Future<List<Map<String, dynamic>>> fetchAllSettings() async {
    try {
      final result = await select(
        table,
        columns: [columnIdealNodeDistance],
      );
      if (result.isNotEmpty) {
        return result;
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error fetching projects: $e');
      return [];
    }
  }
  // update

  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> values) async {
    return await update(table, values, 'id = ?', [1]);
  }
}
