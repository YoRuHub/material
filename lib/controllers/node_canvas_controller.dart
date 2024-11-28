import 'package:flutter/material.dart';
import '../models/background.dart';

class NodeCanvasController {
  final Background background;

  // 背景をドラッグする際の開始位置を記録
  Offset? _lastPanPosition;

  NodeCanvasController(this.background);

  // 背景のドラッグ開始
  void handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition; // 最初の位置を記録
  }

  // 背景のドラッグ更新
  void handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;

    // ドラッグの変化量を計算して背景を移動
    final delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    // 背景を移動
    background.move(delta);
  }

  // ズーム操作
  void handleScaleUpdate(double scrollDelta, Size screenSize) {
    // スクロール量からズーム倍率を計算（1スクロール単位で±10%）
    final zoomFactor = scrollDelta > 0 ? 1.1 : 0.9;

    // ズーム基準点：画面の中心
    final focalPoint = screenSize.center(Offset.zero);

    // 背景をズーム
    background.zoom(zoomFactor, focalPoint);
  }

  // ドラッグ操作終了時のリセット
  void handlePanEnd() {
    _lastPanPosition = null;
  }
}
