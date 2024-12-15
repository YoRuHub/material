import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/node.dart';

class ScreenState {
  final Node? projectNode;
  final Node? previousNode;
  final Offset offset;
  final double scale;
  final bool isPhysicsEnabled;
  final bool isTitleVisible;
  final bool isDrawerOpen;
  final bool isPanning;
  final bool isLinkMode;
  final bool isPositionVisible;
  final bool isAnimating;
  final List<Node> nodeStack; // ノードの履歴スタック

  // デフォルト値を定義して初期化
  static const defaultState = ScreenState(
    projectNode: null,
    previousNode: null,
    offset: Offset.zero,
    scale: 1.0,
    isPhysicsEnabled: true,
    isTitleVisible: true,
    isDrawerOpen: false,
    isPanning: false,
    isLinkMode: false,
    isPositionVisible: true,
    isAnimating: false,
    nodeStack: [],
  );

  // コンストラクタ
  const ScreenState({
    required this.projectNode,
    required this.previousNode,
    required this.offset,
    required this.scale,
    required this.isPhysicsEnabled,
    required this.isTitleVisible,
    required this.isDrawerOpen,
    required this.isPanning,
    required this.isLinkMode,
    required this.isPositionVisible,
    required this.isAnimating,
    required this.nodeStack,
  });

  // copyWith メソッド
  ScreenState copyWith({
    Node? projectNode,
    Node? previousNode,
    Offset? offset,
    double? scale,
    bool? isPhysicsEnabled,
    bool? isTitleVisible,
    bool? isDrawerOpen,
    bool? isPanning,
    bool? isLinkMode,
    bool? isPositionVisible,
    bool? isAnimating,
    List<Node>? nodeStack, // スタックをコピーするための追加
  }) {
    return ScreenState(
      projectNode: projectNode ?? this.projectNode,
      previousNode: previousNode ?? this.previousNode,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      isPhysicsEnabled: isPhysicsEnabled ?? this.isPhysicsEnabled,
      isTitleVisible: isTitleVisible ?? this.isTitleVisible,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      isPanning: isPanning ?? this.isPanning,
      isLinkMode: isLinkMode ?? this.isLinkMode,
      isPositionVisible: isPositionVisible ?? this.isPositionVisible,
      isAnimating: isAnimating ?? this.isAnimating,
      nodeStack: nodeStack ?? this.nodeStack, // スタックをコピー
    );
  }
}

final screenProvider =
    StateNotifierProvider<ScreenNotifier, ScreenState>((ref) {
  return ScreenNotifier();
});

class ScreenNotifier extends StateNotifier<ScreenState> {
  // 初期状態を defaultState に変更
  ScreenNotifier() : super(ScreenState.defaultState);

  Future<void> setProjectNode(Node projectNode) async {
    state = state.copyWith(projectNode: projectNode);
  }

  Future<void> setPreviousNode(Node previousNode) async {
    state = state.copyWith(previousNode: previousNode);
  }

  void setOffset(Offset offset) {
    state = state.copyWith(offset: offset);
  }

  void setScale(double scale) {
    state = state.copyWith(scale: scale);
  }

  // ノードをスタックに追加
  void pushNodeToStack(Node node) {
    List<Node> newStack = List.from(state.nodeStack)..add(node);
    state = state.copyWith(nodeStack: newStack);
  }

  // ノードをスタックから削除
  void popNodeFromStack() {
    if (state.nodeStack.isNotEmpty) {
      List<Node> newStack = List.from(state.nodeStack)..removeLast();
      state = state.copyWith(nodeStack: newStack);
    }
  }

  // 画面状態をリセットするメソッド
  void resetScreen() {
    // nodeStackは消さないように、その他の状態をリセット
    state = ScreenState(
      projectNode: null,
      previousNode: null,
      offset: Offset.zero,
      scale: 1.0,
      isPhysicsEnabled: true,
      isTitleVisible: true,
      isDrawerOpen: false,
      isPanning: false,
      isLinkMode: false,
      isPositionVisible: true,
      isAnimating: false,
      nodeStack: state.nodeStack, // nodeStackはそのまま保持
    );
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

  void toggleLinkMode() {
    state = state.copyWith(isLinkMode: !state.isLinkMode);
  }

  // スクリーン座標の表示状態をトグル
  void togglePositionVisibility() {
    state = state.copyWith(isPositionVisible: !state.isPositionVisible);
  }
}
