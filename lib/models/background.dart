import 'package:flutter/material.dart';

class Background extends ChangeNotifier {
  Offset offset;
  double scale;

  final double minScale;
  final double maxScale;

  Background({
    this.offset = Offset.zero,
    this.scale = 1.0,
    this.minScale = 0.5,
    this.maxScale = 3.0,
  });

  // 背景を移動
  void move(Offset delta) {
    offset += delta; // 移動量を加算
    notifyListeners(); // 背景の位置が変わったことを通知
  }

  // ズーム倍率を更新
  void zoom(double zoomFactor, Offset focalPoint) {
    final newScale = (scale * zoomFactor).clamp(minScale, maxScale);

    // ズームの基準点に合わせて背景のオフセットを調整
    final scaleChange = newScale / scale;
    offset = (offset - focalPoint) * scaleChange + focalPoint;

    scale = newScale; // スケールを更新
    notifyListeners(); // 背景のズームが変わったことを通知
  }
}
