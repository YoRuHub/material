import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/background.dart';

/// Backgroundモデルのプロバイダー
final backgroundProvider = ChangeNotifierProvider<Background>((ref) {
  return Background(); // 初期状態でBackgroundインスタンスを返す
});
