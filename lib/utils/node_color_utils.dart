import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/database/models/node_model.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/utils/logger.dart';

class NodeColorUtils {
  /// 次の世代の色を取得
  static Color getColorForNextGeneration(Node? node) {
    if (node == null) return _getColorForGeneration(0);
    return _getColorForGeneration(_calculateGeneration(node) + 1);
  }

  /// 現在の世代の色を取得
  static Color getColorForCurrentGeneration(Node? node) {
    if (node == null) return _getColorForGeneration(0);
    return _getColorForGeneration(_calculateGeneration(node));
  }

  static Future<void> updateNodeColor(Node node, int projectId) async {
    // もし色がnullまたは透明なら色を設定
    if (node.color == null || node.color == Colors.transparent) {
      node.color = _getColorForGeneration(_calculateGeneration(node));
      Logger.debug('Node ${node.id} color updated to ${node.color}');
      final nodeModel = NodeModel();
      await nodeModel.upsertNode(
          node.id, node.title, node.contents, node.color!, projectId);
    }

    // 子ノードをバッチ処理
    final children = List<Node>.from(node.children); // 元のリストをコピー
    const batchSize = 10; // 一度に処理する子ノードの数
    for (int i = 0; i < children.length; i += batchSize) {
      // バッチサイズ分ずつ処理
      final batch = children.sublist(
          i,
          (i + batchSize) < children.length
              ? (i + batchSize)
              : children.length);
      await Future.wait(batch.map((child) async {
        await updateNodeColor(child, projectId);
      }));
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
