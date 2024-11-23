import 'package:flutter/material.dart';
import 'package:flutter_app/constants/node_constants.dart';
import 'package:flutter_app/models/node.dart';

class NodeColorUtils {
  /// 次の世代の色を取得
  static Color getColorForNextGeneration(Node? node) {
    // nodeがnullの場合、世代に応じた色を返す
    int generation = node == null ? 0 : _calculateGeneration(node);
    int nextGeneration = generation + 1;

    // 次の世代に対応する色を計算
    return _getColorForGeneration(nextGeneration);
  }

  /// 現在の世代の色を取得
  static Color getColorForCurrentGeneration(Node? node) {
    // nodeがnullの場合、世代に応じた色を返す
    int generation = node == null ? 0 : _calculateGeneration(node);

    // 現在の世代に対応する色を計算
    return _getColorForGeneration(generation);
  }

  /// 再帰的にノードの色を更新
  static void updateNodeColor(Node node) {
    // ノードに色が設定されていない場合のみ更新
    if (node.color == Colors.transparent) {
      // ノードの世代を計算
      int generation = _calculateGeneration(node);

      // 世代に基づいて色を設定
      node.color = _getColorForGeneration(generation);
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
  static int _calculateGeneration(Node node) {
    int generation = 0;
    Node? current = node;
    while (current?.parent != null) {
      generation++;
      current = current?.parent;
    }
    return generation;
  }
}
