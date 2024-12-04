import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class ScreenState {
  final Offset offset;
  final double scale;

  ScreenState({required this.offset, required this.scale});

  ScreenState copyWith({Offset? offset, double? scale}) {
    return ScreenState(
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
    );
  }
}

final screenProvider =
    StateNotifierProvider<ScreenNotifier, ScreenState>((ref) {
  return ScreenNotifier();
});

class ScreenNotifier extends StateNotifier<ScreenState> {
  ScreenNotifier() : super(ScreenState(offset: Offset.zero, scale: 1.0));

  void setOffset(Offset offset) {
    state = state.copyWith(offset: offset);
  }

  void setScale(double scale) {
    state = state.copyWith(scale: scale);
  }

  void resetScreen() {
    state = ScreenState(offset: Offset.zero, scale: 1.0);
  }
}
