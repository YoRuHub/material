import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class ScreenState {
  final Offset offset;
  final double scale;
  final bool isPhysicsEnabled;
  final bool isTitleVisible;
  final bool isDrawerOpen;
  final bool isPanning;

  // デフォルト値を定義して初期化
  static const defaultState = ScreenState(
    offset: Offset.zero,
    scale: 1.0,
    isPhysicsEnabled: true,
    isTitleVisible: true,
    isDrawerOpen: false,
    isPanning: false,
  );

  // コンストラクタ
  const ScreenState(
      {required this.offset,
      required this.scale,
      required this.isPhysicsEnabled,
      required this.isTitleVisible,
      required this.isDrawerOpen,
      required this.isPanning});

  // copyWith メソッド
  ScreenState copyWith(
      {Offset? offset,
      double? scale,
      bool? isPhysicsEnabled,
      bool? isTitleVisible,
      bool? isDrawerOpen,
      bool? isPanning}) {
    return ScreenState(
        offset: offset ?? this.offset,
        scale: scale ?? this.scale,
        isPhysicsEnabled: isPhysicsEnabled ?? this.isPhysicsEnabled,
        isTitleVisible: isTitleVisible ?? this.isTitleVisible,
        isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
        isPanning: isPanning ?? this.isPanning);
  }
}

final screenProvider =
    StateNotifierProvider<ScreenNotifier, ScreenState>((ref) {
  return ScreenNotifier();
});

class ScreenNotifier extends StateNotifier<ScreenState> {
  // 初期状態を defaultState に変更
  ScreenNotifier() : super(ScreenState.defaultState);

  void setOffset(Offset offset) {
    state = state.copyWith(offset: offset);
  }

  void setScale(double scale) {
    state = state.copyWith(scale: scale);
  }

  // 画面状態をリセットするメソッド
  void resetScreen() {
    state = ScreenState.defaultState;
  }

  // 物理演算の状態をトグル
  void togglePhysics() {
    state = state.copyWith(isPhysicsEnabled: !state.isPhysicsEnabled);
  }

  // 物理演算を無効化するメソッド（明示的にオフ）
  void disablePhysics() {
    state = state.copyWith(isPhysicsEnabled: false);
  }

  // ノードタイトルの表示状態をトグル
  void toggleNodeTitles() {
    state = state.copyWith(isTitleVisible: !state.isTitleVisible);
  }

  // ドロワーの表示状態をトグル
  void toggleDrawer() {
    state = state.copyWith(isDrawerOpen: !state.isDrawerOpen);
  }

  // ドラッグ中の状態をトグル
  void disablePanning() {
    state = state.copyWith(isPanning: false);
  }

  void enablePanning() {
    state = state.copyWith(isPanning: true);
  }
}
