import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/node_map_model.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/database/models/project_model.dart';
import 'package:flutter_app/models/project.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectNotifier extends StateNotifier<List<Project>> {
  ProjectNotifier() : super([]);
  final _projectModel = ProjectModel();
  final _nodeModel = NodeModel();
  final _nodeMapModel = NodeMapModel();

  Future<void> loadProjects() async {
    try {
      final projects = await _projectModel
          .fetchAllProjects(); // getProjects メソッドを使ってプロジェクトを取得
      state = projects.map((project) {
        return Project(
          id: project['id'] as int,
          title: project['title'] as String,
          updatedAt: _parseDateTime(project['updated_at']),
          createdAt: _parseDateTime(project['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading projects: $e');
    }
  }

  // プロジェクトを追加
  Future<void> addProject(String title) async {
    try {
      final newProject = await _projectModel.upsertProject(0, title);

      // フィールドの存在確認
      if (newProject['id'] == null ||
          newProject['title'] == null ||
          newProject['updated_at'] == null ||
          newProject['created_at'] == null) {
        throw Exception(
            'Unexpected data returned from upsertProject: $newProject');
      }

      final project = Project(
        id: newProject['id'] as int,
        title: newProject['title'] as String,
        updatedAt: _parseDateTime(newProject['updated_at']),
        createdAt: _parseDateTime(newProject['created_at']),
      );

      state = [...state, project];
      Logger.debug(
          'Project added successfully: ID: ${project.id}, Title: ${project.title}');
    } catch (e) {
      Logger.error('Error adding project with title "$title": $e');
      rethrow;
    }
  }

  // プロジェクトを編集
  Future<void> editProject(int id, String title) async {
    try {
      final updatedProject = await _projectModel.upsertProject(id, title);

      final project = Project(
        id: updatedProject['id'] as int,
        title: updatedProject['title'] as String,
        updatedAt: _parseDateTime(updatedProject['updated_at']),
        createdAt: _parseDateTime(updatedProject['created_at']),
      );

      state = state.map((p) => p.id == id ? project : p).toList();

      Logger.debug(
        'Project edited successfully: ID: ${project.id}, Title: ${project.title}',
      );
    } catch (e) {
      Logger.error('Error editing project with ID $id: $e');
      rethrow;
    }
  }

  // プロジェクトを削除
  Future<void> deleteProject(int id) async {
    try {
      // Future<void> を返すように変更
      await _projectModel.deleteProject(id);
      // ノード一覧
      final nodeList = await _nodeModel.fetchAllNodes(id);
      //　ノードマップ削除
      for (var node in nodeList) {
        // ノードテーブルから削除
        await _nodeModel.deleteNode(node['id'], id);
        // ノードマップテーブルから削除
        await _nodeMapModel.deleteChildNodeMap(node['id']);
        await _nodeMapModel.deleteParentNodeMap(node['id']);
      }
      state = state.where((p) => p.id != id).toList();
    } catch (e) {
      Logger.error('Error deleting project: $e');
    }
  }

  // Hover状態を更新
  void updateHoverState(int id, bool isHovered) {
    state = state.map((p) {
      if (p.id == id) {
        p.isHovered = isHovered; // ホバー状態を直接更新
      }
      return p;
    }).toList();
  }

  // DateTime を適切にパースするヘルパー関数
  DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now(); // null の場合は現在の日時をデフォルト値として使用
    }
    return DateTime.parse(dateTime.toString()); // 日時の文字列を DateTime に変換
  }
}

final projectNotifierProvider =
    StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
  return ProjectNotifier();
});
