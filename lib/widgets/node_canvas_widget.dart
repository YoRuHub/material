import 'package:flutter/material.dart';
import '../models/background.dart';

class NodeCanvasController {
  final Background background;
  final Function() notifyUIUpdate; // UIの更新を通知するコールバック

  // 背景をドラッグする際の開始位置を記録
  Offset? _lastPanPosition;

  NodeCanvasController(this.background, this.notifyUIUpdate);

  /// 背景のドラッグ開始
  void handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.localPosition;
  }

  /// 背景のドラッグ更新
  void handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;

    // ドラッグの変化量を計算して背景を移動
    final delta = details.localPosition - _lastPanPosition!;
    _lastPanPosition = details.localPosition;

    // 背景を移動
    background.move(delta);

    // 状態更新を通知
    notifyUIUpdate(); // UIの更新を呼び出す
  }

  /// ホイールでのズーム操作
  void handleScaleUpdate(double scrollDelta, Size screenSize) {
    // スクロール量からズーム倍率を計算（1スクロール単位で±10%）
    final zoomFactor = scrollDelta > 0 ? 1.1 : 0.9;

    // 画面中心をズームの基準点とする
    final focalPoint = screenSize.center(Offset.zero);

    // 背景をズーム
    background.zoom(zoomFactor, focalPoint);

    // 状態更新を通知
    notifyUIUpdate(); // UIの更新を呼び出す
  }

  /// ドラッグ操作終了時のリセット
  void handlePanEnd() {
    _lastPanPosition = null;
  }
}
