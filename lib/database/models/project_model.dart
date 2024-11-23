import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class ProjectModel extends BaseModel {
  static const String table = 'project';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// プロジェクト全件取得
  Future<List<Map<String, dynamic>>> fetchAllProjects() async {
    try {
      final result = await select(
        table,
        columns: [columnId, columnTitle, columnCreatedAt, columnUpdatedAt],
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

  /// プロジェクトを更新または挿入
  Future<Map<String, dynamic>> upsertProject(int id, String title) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      if (id != 0) columnId: id,
      columnTitle: title,
      if (id != 0) columnUpdatedAt: now,
      if (id == 0) columnCreatedAt: now,
    };

    try {
      // upsertを使ってデータを挿入または更新し、その結果を返す
      final result = await upsert(
        table,
        data,
        [columnId], // 条件カラムとしてidを指定
      );
      Logger.debug('Project upserted successfully: $result');
      return result; // 処理後のデータを返す
    } catch (e) {
      Logger.error('Error in upsertProject. Data: $data, Error: $e');
      rethrow;
    }
  }

  /// プロジェクトを削除
  Future<void> deleteProject(int id) async {
    try {
      await delete(table, '$columnId = ?', [id]);
      await resetAutoIncrement(table);
    } catch (e) {
      Logger.error('Error deleting project: $e');
      rethrow;
    }
  }
}
