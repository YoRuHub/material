import 'package:flutter/material.dart';
import 'package:flutter_app/screens/mind_map_screen.dart';
import 'detail_screen.dart';
import 'icons_screen.dart'; // IconsScreenをインポート
import '../widgets/square_button.dart';

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
        'title': 'TEST2',
        'color': Colors.orange,
        'index': 2,
      },
      {
        'icon': Icons.quiz,
        'title': 'TEST3',
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
              width: crossAxisCount * 120.0, // グリッドの幅調整
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
                  return SquareButton(
                    title: buttonData[index]['title'],
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
                              builder: (context) => NodeAnimation(),
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
