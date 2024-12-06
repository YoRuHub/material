import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class ScreenState {
  final Offset offset;
  final double scale;
  final bool isPhysicsEnabled; // 追加

  ScreenState({
    required this.offset,
    required this.scale,
    required this.isPhysicsEnabled, // 初期化
  });

  ScreenState copyWith({
    Offset? offset,
    double? scale,
    bool? isPhysicsEnabled, // 追加
  }) {
    return ScreenState(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      isPhysicsEnabled: isPhysicsEnabled ?? this.isPhysicsEnabled, // 更新
    );
  }
}

final screenProvider =
    StateNotifierProvider<ScreenNotifier, ScreenState>((ref) {
  return ScreenNotifier();
});

class ScreenNotifier extends StateNotifier<ScreenState> {
  ScreenNotifier()
      : super(ScreenState(
            offset: Offset.zero, scale: 1.0, isPhysicsEnabled: true)); // 初期値設定

  void setOffset(Offset offset) {
    state = state.copyWith(offset: offset);
  }

  void setScale(double scale) {
    state = state.copyWith(scale: scale);
  }

  void resetScreen() {
    state =
        ScreenState(offset: Offset.zero, scale: 1.0, isPhysicsEnabled: true);
  }

  // 物理演算を切り替える
  void togglePhysics() {
    state = state.copyWith(isPhysicsEnabled: !state.isPhysicsEnabled);
  }

  /// 物理演算を無効化
  void disablePhysics() {
    state = state.copyWith(isPhysicsEnabled: false);
  }
}
