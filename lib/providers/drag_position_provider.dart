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

  /// x, y を Offset 型で返す
  Offset? toOffset() {
    if (_x != null && _y != null) {
      return Offset(_x!, _y!); // x と y が null でない場合のみ Offset を返す
    }
    return null; // x または y が null の場合は null を返す
  }
}

/// ドラッグ位置を管理するProvider
final dragPositionProvider =
    ChangeNotifierProvider<DragPosition>((ref) => DragPosition());
