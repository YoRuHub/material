import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class SettingsModel extends BaseModel {
  static const String table = 'settings';
  static const String columnId = 'id';
  static const String columnParentChildDistance = 'parent_child_distance';
  static const String columnLinkDistance = 'link_distance';
  static const String columnParentChildAttraction = 'parent_child_attraction';
  static const String columnLinkAttraction = 'link_attraction';

  /// プロジェクト全件取得
  Future<List<Map<String, dynamic>>> fetchAllSettings() async {
    try {
      final result = await select(
        table,
        columns: [
          columnParentChildDistance,
          columnLinkDistance,
          columnParentChildAttraction,
          columnLinkAttraction
        ],
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

  Future<Map<String, dynamic>> upsertSettings(
    Map<String, dynamic> values,
  ) async {
    try {
      return await upsert(
        table,
        values,
        '$columnId = ?',
        [1],
      );
    } catch (e) {
      Logger.error('Error updating project: $e');
      return {};
    }
  }
}
