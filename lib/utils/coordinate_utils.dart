import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import '../constants/node_constants.dart';

/// 座標変換に関するユーティリティクラス
class CoordinateUtils {
  /// スクリーン座標からワールド座標への変換
  ///
  /// [screenPos] スクリーン上の座標
  /// [offset] 現在のビューポートのオフセット
  /// [scale] 現在の拡大率
  static vector_math.Vector2 screenToWorld(
    Offset screenPos,
    Offset offset,
    double scale,
  ) {
    return vector_math.Vector2(
      (screenPos.dx - offset.dx) / scale,
      (screenPos.dy - offset.dy) / scale,
    );
  }

  /// ワールド座標からスクリーン座標への変換
  ///
  /// [worldPos] ワールド座標系での位置
  /// [offset] 現在のビューポートのオフセット
  /// [scale] 現在の拡大率
  static Offset worldToScreen(
    vector_math.Vector2 worldPos,
    Offset offset,
    double scale,
  ) {
    return Offset(
      worldPos.x * scale + offset.dx,
      worldPos.y * scale + offset.dy,
    );
  }

  /// ズーム処理の計算
  ///
  /// [currentScale] 現在の拡大率
  /// [scrollDelta] スクロールの変化量
  /// [screenCenter] 画面の中心座標
  /// [currentOffset] 現在のビューポートのオフセット
  ///
  /// 戻り値: (新しい拡大率, 新しいオフセット)のタプル
  static (double, Offset) calculateZoom({
    required double currentScale,
    required double scrollDelta,
    required Offset screenCenter,
    required Offset currentOffset,
  }) {
    // 現在のスケール値を保存
    final prevScale = currentScale;

    // 新しいスケール値を計算
    double newScale = currentScale;
    if (scrollDelta > 0) {
      newScale *= 0.95;
    } else {
      newScale *= 1.05;
    }

    // スケールを制限
    newScale = newScale.clamp(
      NodeConstants.minScale,
      NodeConstants.maxScale,
    );

    // スケールの変化率を計算
    final scaleChange = newScale / prevScale;

    // オフセットを調整して画面中心を基準に拡大縮小
    final newOffset =
        screenCenter + ((currentOffset - screenCenter) * scaleChange);

    return (newScale, newOffset);
  }

  /// 画面の中心座標を計算
  ///
  /// [size] 画面サイズ
  /// [appBarHeight] AppBarの高さ（指定がない場合は0）
  static Offset calculateScreenCenter(Size size, [double appBarHeight = 0]) {
    return Offset(
      size.width / 2,
      (size.height - appBarHeight) / 2,
    );
  }

  /// ビューポート内の座標かどうかをチェック
  ///
  /// [position] チェックする座標（ワールド座標）
  /// [viewportSize] ビューポートのサイズ
  /// [offset] 現在のビューポートのオフセット
  /// [scale] 現在の拡大率
  /// [padding] 余白（デフォルト値: 100.0）
  static bool isInViewport(vector_math.Vector2 position, Size viewportSize,
      Offset offset, double scale,
      [double padding = 100.0]) {
    Offset screenPos = worldToScreen(position, offset, scale);

    return screenPos.dx >= -padding &&
        screenPos.dx <= viewportSize.width + padding &&
        screenPos.dy >= -padding &&
        screenPos.dy <= viewportSize.height + padding;
  }

  /// 2点間の距離を計算
  static double calculateDistance(
      vector_math.Vector2 a, vector_math.Vector2 b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return vector_math.Vector2(dx, dy).length;
  }

  /// 座標のスナップ処理
  ///
  /// [position] スナップ対象の座標
  /// [gridSize] グリッドのサイズ
  static vector_math.Vector2 snapToGrid(
    vector_math.Vector2 position,
    double gridSize,
  ) {
    return vector_math.Vector2(
      (position.x / gridSize).round() * gridSize,
      (position.y / gridSize).round() * gridSize,
    );
  }
}
