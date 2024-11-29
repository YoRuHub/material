import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';

class NodeColorUtils {
  /// 次の世代の色を取得
  static Color getColorForNextGeneration(Node? node) {
    if (node == null) return _getColorForGeneration(0);
    return _getColorForGeneration(_calculateGeneration(node) + 1);
  }

  /// 現在の世代の色を取得
  static Color getColorForCurrentGeneration(Node? node) {
    return _getColorForGeneration(_calculateGeneration(node));
  }

  /// 再帰的にノードの色を更新（非同期対応）
  static Future<void> updateNodeColor(Node node, int projectId) async {
    if (node.color == Colors.transparent) {
      node.color = _getColorForGeneration(_calculateGeneration(node));
      final nodeModel = NodeModel();
      await nodeModel.upsertNode(
          node.id, node.title, node.contents, node.color, projectId);
    }

    for (Node child in node.children) {
      await updateNodeColor(child, projectId);
    }
  }

  /// 再帰的にノードの色を更新（強制更新バージョン・非同期対応）
  static Future<void> forceUpdateNodeColor(Node node, int projectId) async {
    node.color = _getColorForGeneration(_calculateGeneration(node));
    final nodeModel = NodeModel();
    await nodeModel.upsertNode(
        node.id, node.title, node.contents, node.color, projectId);

    for (Node child in node.children) {
      await forceUpdateNodeColor(child, projectId);
    }
  }

  /// 世代に応じた色を取得
  static Color _getColorForGeneration(int generation) {
    double hue = (generation * NodeConstants.hueShift) % NodeConstants.maxHue;
    return HSLColor.fromAHSL(
      NodeConstants.alpha,
      hue,
      NodeConstants.saturation,
      NodeConstants.lightness,
    ).toColor();
  }

  /// ノードの世代を計算
  static int _calculateGeneration(Node? node) {
    if (node == null) return 0;
    int generation = 0;
    Node? current = node;
    while (current?.parent != null) {
      generation++;
      current = current?.parent;
    }
    return generation;
  }

  /// 指定された世代数に対して色のリストを生成
  static List<Color> generateColorsForGenerations(int count) {
    return List<Color>.generate(
      count,
      (generation) => _getColorForGeneration(generation),
    );
  }
}
