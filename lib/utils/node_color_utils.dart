import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/models/node.dart';

class NodeColorUtils {
  /// 次の世代の色を取得
  static Color getColorForNextGeneration(Node? node) {
    // nodeがnullの場合、世代0の色を返す
    return _getColorForGeneration(_calculateGeneration(node) + 1);
  }

  /// 現在の世代の色を取得
  static Color getColorForCurrentGeneration(Node? node) {
    // nodeがnullの場合、世代0の色を返す
    return _getColorForGeneration(_calculateGeneration(node));
  }

  /// 再帰的にノードの色を更新
  static void updateNodeColor(Node node) {
    // ノードに色が設定されていない場合のみ更新
    if (node.color == Colors.transparent) {
      // 世代に基づいて色を設定
      node.color = _getColorForGeneration(_calculateGeneration(node));
    }

    // 子ノードに対しても再帰的に色を更新
    for (Node child in node.children) {
      updateNodeColor(child); // 子ノードの色も更新
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
    if (node == null) return 0; // nodeがnullの場合、世代0
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
