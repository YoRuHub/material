import 'package:flutter/material.dart';
import 'base_model.dart';

class ProjectModel extends BaseModel {
  static const String table = 'project';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

// project一覧取得
  Future<List<Map<String, dynamic>>> fetchAllProjects() async {
    try {
      final result = await select(
        table,
        columns: [columnId, columnTitle, columnCreatedAt, columnUpdatedAt],
      );
      return result.isNotEmpty ? result : [];
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      return [];
    }
  }

  // project追加
  Future<Map<String, dynamic>> upsertProject(int id, String title) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      if (id != 0) columnId: id,
      columnTitle: title,
      if (id != 0) columnUpdatedAt: now,
      if (id == 0) columnCreatedAt: now,
    };

    try {
      if (id != 0) {
        // 更新処理
        await upsert(table, data, '$columnId = ?', [id]);
        debugPrint('Project updated successfully');
        return data;
      } else {
        // 新規挿入処理
        final newId = await insert(table, data); // 挿入されたIDを取得
        data[columnId] = newId; // IDをdataに追加
        debugPrint('Project inserted successfully with ID: $newId');
        return data;
      }
    } catch (e) {
      debugPrint('Error upserting project: $e');
      return {}; // エラー時は空のMapを返す
    }
  }

// project削除
  Future<void> deleteProject(int id) async {
    try {
      await delete(table, '$columnId = ?', [id]);
      await resetAutoIncrement(table);
    } catch (e) {
      debugPrint('Error deleting project: $e');
    }
  }
}
