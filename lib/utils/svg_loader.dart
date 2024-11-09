import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';

class SVGLoader {
  static Future<SvgPicture?> loadOrNull({
    required String path,
  }) async {
    try {
      // アセットの読み込み
      await rootBundle.load(path);

      // SVGファイルをそのまま表示（色変更なし）
      SvgPicture pic = SvgPicture.asset(
        path,
        fit: BoxFit.contain, // アイコンの比率を保ちながら収める
        clipBehavior: Clip.hardEdge, // 必要に応じて設定
      );

      return pic;
    } catch (e) {
      // エラー処理
      debugPrint('Error loading SVG: $e');
      return null;
    }
  }

  /// プリロード
  static Future preload(List<String> pathList) async {
    for (var path in pathList) {
      var loader = SvgAssetLoader(path);
      await svg.cache
          .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    }
  }
}
