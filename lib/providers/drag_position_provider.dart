import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// ドラッグ中の位置を管理するクラス
class DragPosition extends ChangeNotifier {
  double? _x;
  double? _y;

  double? get x => _x;
  double? get y => _y;

  // タップ位置を直接設定
  void setPosition(double newX, double newY) {
    _x = newX;
    _y = newY;
    notifyListeners();
  }

  void reset() {
    _x = null;
    _y = null;
    notifyListeners();
  }
}

/// ドラッグ位置を管理するProvider
final dragPositionProvider =
    ChangeNotifierProvider<DragPosition>((ref) => DragPosition());
