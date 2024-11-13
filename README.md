# flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

ノードの役割を考える
・ノード側に反発力を持たせる
・ノード側に摩擦力を持たせる
・ノード側にアクティブ・非アクティブを持たせる

lib/
├── models/
│ └── node.dart # Node クラスの定義
│
├── screens/
│ └── mind_map_screen.dart # メインの画面ウィジェット
│
├── painters/
│ └── node_painter.dart # カスタムペインター
│
├── utils/
│ ├── coordinate_utils.dart # 座標変換関連
│ ├── node_physics.dart # 物理演算関連
│ ├── node_alignment.dart # ノードの配置関連
│ └── node_operations.dart # ノードの操作関連（追加・削除など）
│
├── widgets/
│ ├── add_node_button.dart # 既存
│ ├── positioned_text.dart # 既存
│ └── tool_bar.dart # 既存
│
└── constants/
└── node_constants.dart # 定数の定義
