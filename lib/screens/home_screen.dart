import 'package:flutter/material.dart';
import 'package:flutter_app/screens/mind_map_3d_screen.dart';
import 'package:flutter_app/screens/mind_map_screen.dart';
import 'package:flutter_app/screens/my_3d_view.dart';
import 'package:flutter_app/widgets/particle_button.dart';
import 'detail_screen.dart';
import 'icons_screen.dart'; // IconsScreenをインポート

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ボタンのデータを一括管理
    final List<Map<String, dynamic>> buttonData = [
      {
        'icon': Icons.apps,
        'title': 'Icons',
        'color': Colors.blue,
        'index': 0,
      },
      {
        'icon': Icons.language,
        'title': 'Mind Map',
        'color': Colors.cyan,
        'index': 1,
      },
      {
        'icon': Icons.quiz,
        'title': 'SpaceMap3D',
        'color': Colors.orange,
        'index': 2,
      },
      {
        'icon': Icons.quiz,
        'title': 'TEST',
        'color': Colors.pink,
        'index': 3,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmic Home'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2; // 画面幅に応じた列数

          // 中央に配置するためにAlignウィジェットで調整
          return Align(
            alignment: Alignment.center, // 画面中央に配置
            child: SizedBox(
              width: crossAxisCount * 240.0, // グリッドの幅調整
              child: GridView.builder(
                shrinkWrap: true, // グリッドの高さをコンテンツに合わせる
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1,
                ),
                padding: const EdgeInsets.all(16.0),
                itemCount: buttonData.length,
                itemBuilder: (context, index) {
                  return ParticleButton(
                    text: buttonData[index]['title'],
                    icon: buttonData[index]['icon'],
                    color: buttonData[index]['color'],
                    onPressed: () {
                      // Iconsボタンの場合はIconsScreen、それ以外はDetailScreenを表示
                      if (buttonData[index]['title'] == 'Icons') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IconsScreen(),
                          ),
                        );
                      } else if (buttonData[index]['title'] == 'Mind Map') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MindMapScreen(),
                            ));
                      } else if (buttonData[index]['title'] == 'Mind Map 3D') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MindMapScreens(),
                            ));
                      } else if (buttonData[index]['title'] == 'TEST') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NodeAnimation3D(),
                            ));
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailScreen(index: buttonData[index]['index']),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
