import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/utils/svg_loader.dart'; // SVGLoaderのインポート

// -a----        2024/11/08     16:54           5805 apple_color.svg
// -a----        2024/11/08     17:04           4642 bell_pepper_color.svg
// -a----        2024/11/08     16:55           3077 book_color.svg
// -a----        2024/11/08     17:05           2370 broccoli_color.svg
// -a----        2024/11/08     17:18           4972 burdock_color.svg
// -a----        2024/11/08     17:19           9775 cabbage_color.svg
// -a----        2024/11/08     17:44           8325 carrot_color.svg
// -a----        2024/11/08     17:46           2567 cloud_color.svg
// -a----        2024/11/08     18:22           5933 cucumber_color.svg
// -a----        2024/11/08     18:21           2353 dried_flour_color.svg
// -a----        2024/11/08     18:20           3928 eggplant_color.svg
// -a----        2024/11/08     18:18           5535 fertilizer_color.svg
// -a----        2024/11/08     18:11           5804 few_clouds.svg
// -a----        2024/11/08     18:09           3346 flour_color.svg
// -a----        2024/11/08     18:08           5428 green_bean_color.svg
// -a----        2024/11/08     18:58           4151 green_onion_color.svg
// -a----        2024/11/08     18:57           8372 lettuce_color.svg
// -a----        2024/11/08     18:56           4783 linghting_color.svg
// -a----        2024/11/08     18:55           3666 liquid_fertilizer_color.svg
// -a----        2024/11/08     18:54           7865 mini_tomato_color.svg
// -a----        2024/11/08     18:53           2804 okra_color.svg
// -a----        2024/11/08     18:30           2853 planting_color.svg
// -a----        2024/11/08     18:29           4023 pumpkin_color.svg
// -a----        2024/11/08     18:28          10872 radish_color.svg
// -a----        2024/11/08     19:25           2758 rain_color.svg
// -a----        2024/11/08     19:33           5891 scattered_clouds_color.svg
// -a----        2024/11/08     19:32           3856 scissors_color.svg
// -a----        2024/11/08     19:31           2708 seedling_color.svg
// -a----        2024/11/08     19:30           2146 shiso_color.svg
// -a----        2024/11/08     19:29           3862 snow_man_color.svg
// -a----        2024/11/08     19:28           7194 spinach_color.svg
// -a----        2024/11/08     19:27           2039 sprout_color.svg
// -a----        2024/11/08     19:24           3365 sun_color.svg
// -a----        2024/11/09     14:32           5839 sweet_potato_color.svg
// -a----        2024/11/09     14:32           9015 taro_color.svg
// -a----        2024/11/08     16:59           5687 tomato_color.svg
// -a----        2024/11/09     14:31           3030 watering_can_color.svg
class CustomIcons {
  CustomIcons._(); // インスタンス化を防ぐためのプライベートコンストラクタ

  // SVGファイルのパスを保持
  static const assetPath = 'assets/svgs';

  // 各アイコンを静的プロパティとして定義（Futureを返す）
  static Future<SvgPicture?> get appleColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/apple_color.svg');

  static Future<SvgPicture?> get bellPepperColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/bell_pepper_color.svg');

  static Future<SvgPicture?> get bookColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/book_color.svg');

  static Future<SvgPicture?> get broccoliColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/broccoli_color.svg');

  static Future<SvgPicture?> get burdockColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/burdock_color.svg');

  static Future<SvgPicture?> get cabbageColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/cabbage_color.svg');

  static Future<SvgPicture?> get carrotColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/carrot_color.svg');

  static Future<SvgPicture?> get cloudColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/cloud_color.svg');

  static Future<SvgPicture?> get cucumberColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/cucumber_color.svg');

  static Future<SvgPicture?> get driedFlourColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/dried_flour_color.svg');

  static Future<SvgPicture?> get eggplantColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/eggplant_color.svg');

  static Future<SvgPicture?> get fertilizerColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/fertilizer_color.svg');

  static Future<SvgPicture?> get fewClouds async =>
      await SVGLoader.loadOrNull(path: '$assetPath/few_clouds.svg');

  static Future<SvgPicture?> get flourColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/flour_color.svg');

  static Future<SvgPicture?> get greenBeanColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/green_bean_color.svg');

  static Future<SvgPicture?> get greenOnionColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/green_onion_color.svg');

  static Future<SvgPicture?> get lettuceColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/lettuce_color.svg');

  static Future<SvgPicture?> get linghtingColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/linghting_color.svg');

  static Future<SvgPicture?> get liquidFertilizerColor async =>
      await SVGLoader.loadOrNull(
          path: '$assetPath/liquid_fertilizer_color.svg');

  static Future<SvgPicture?> get miniTomatoColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/mini_tomato_color.svg');

  static Future<SvgPicture?> get okraColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/okra_color.svg');

  static Future<SvgPicture?> get plantingColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/planting_color.svg');

  static Future<SvgPicture?> get pumpkinColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/pumpkin_color.svg');

  static Future<SvgPicture?> get radishColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/radish_color.svg');

  static Future<SvgPicture?> get rainColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/rain_color.svg');

  static Future<SvgPicture?> get scatteredCloudsColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/scattered_clouds_color.svg');

  static Future<SvgPicture?> get scissorsColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/scissors_color.svg');

  static Future<SvgPicture?> get seedlingColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/seedling_color.svg');

  static Future<SvgPicture?> get shisoColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/shiso_color.svg');

  static Future<SvgPicture?> get snowManColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/snow_man_color.svg');

  static Future<SvgPicture?> get spinachColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/spinach_color.svg');

  static Future<SvgPicture?> get sproutColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/sprout_color.svg');

  static Future<SvgPicture?> get sunColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/sun_color.svg');

  static Future<SvgPicture?> get sweetPotatoColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/sweet_potato_color.svg');

  static Future<SvgPicture?> get taroColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/taro_color.svg');

  static Future<SvgPicture?> get tomatoColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/tomato_color.svg');

  static Future<SvgPicture?> get wateringCanColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/watering_can_color.svg');

  static Future<SvgPicture?> get whiteRadishColor async =>
      await SVGLoader.loadOrNull(path: '$assetPath/white_radish_color.svg');

  // アイコンのプリロードを行うメソッド
  static Future preloadIcons() async {
    try {
      // アセットファイルを全て読み込む
      final assetFiles = await _getAssetFiles(assetPath);
      if (assetFiles.isEmpty) {
        throw Exception("No SVG files found in assets. path: $assetPath");
      }
      // プリロードするSVGファイルのリスト
      await SVGLoader.preload(assetFiles);
    } catch (e) {
      debugPrint("Error preloading icons: $e");
    }
  }

  // アセットディレクトリ内のファイル一覧を取得

  static Future<List<String>> _getAssetFiles(String path) async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestJson);

    // 指定したパスに含まれるファイルのパスをフィルタリング
    return manifestMap.keys
        .where((String key) => key.startsWith(path) && key.endsWith('.svg'))
        .toList();
  }
}
