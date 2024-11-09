import 'package:flutter/material.dart';
import 'package:flutter_app/models/custom_icon.dart'; // CustomIconsのインポート
import 'package:flutter_app/widgets/custom_icon_button.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SvgPictureのインポート

class IconsScreen extends StatelessWidget {
  const IconsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // アイコンのリスト（非同期で取得）
    final List<Future<SvgPicture?>> iconList = [
      CustomIcons.appleColor,
      CustomIcons.bellPepperColor,
      CustomIcons.bookColor,
      CustomIcons.broccoliColor,
      CustomIcons.burdockColor,
      CustomIcons.cabbageColor,
      CustomIcons.carrotColor,
      CustomIcons.cloudColor,
      CustomIcons.cucumberColor,
      CustomIcons.driedFlourColor,
      CustomIcons.eggplantColor,
      CustomIcons.fertilizerColor,
      CustomIcons.fewClouds,
      CustomIcons.flourColor,
      CustomIcons.greenBeanColor,
      CustomIcons.greenOnionColor,
      CustomIcons.lettuceColor,
      CustomIcons.linghtingColor,
      CustomIcons.liquidFertilizerColor,
      CustomIcons.miniTomatoColor,
      CustomIcons.okraColor,
      CustomIcons.plantingColor,
      CustomIcons.pumpkinColor,
      CustomIcons.radishColor,
      CustomIcons.rainColor,
      CustomIcons.scatteredCloudsColor,
      CustomIcons.scissorsColor,
      CustomIcons.seedlingColor,
      CustomIcons.shisoColor,
      CustomIcons.snowManColor,
      CustomIcons.spinachColor,
      CustomIcons.sproutColor,
      CustomIcons.sunColor,
      CustomIcons.sweetPotatoColor,
      CustomIcons.taroColor,
      CustomIcons.tomatoColor,
      CustomIcons.wateringCanColor,
      CustomIcons.whiteRadishColor
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Icons Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 12, // 列数
            crossAxisSpacing: 8, // 列間のスペース
            mainAxisSpacing: 8, // 行間のスペース
          ),
          itemCount: iconList.length,
          itemBuilder: (context, index) {
            return FutureBuilder<SvgPicture?>(
              future: iconList[index], // アイコンを非同期で取得
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Icon(Icons.error);
                }
                // アイコンが取得できた場合
                return snapshot.data != null
                    ? CustomIconButton(
                        icon: snapshot.data!,
                        onPressed: () {},
                      )
                    : const Icon(Icons.error); // アイコンがnullの場合はエラーアイコンを表示
              },
            );
          },
        ),
      ),
    );
  }
}
