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

Todo
・focus（追跡機能
    アクティブ状態のノードが居るとき、カメラをノードに追従させ、ズームもする
・map(マップ機能)
    ノードの縮小図と座標、グループノードの次へ前へボタンもセット
・データ構造の作成
・yaml形式でインポート・エクスポート
・ノード削除時のマップ削除
・２つ以上の子ノードを初期描画できるように

・projectの編集
・projectの削除
・addボタンのデザイン修正&常にリストのうえに表示

lib/
├── screens/
│   ├── mind_map_screen.dart             # メインの画面UI
│   └── mind_map_screen/
│       ├── mind_map_gesture_handler.dart # ジェスチャー処理
│       └── mind_map_node_handler.dart    # ノード操作の処理
│
├── features/
│   ├── node_management/
│   │   ├── node_creator.dart            # ノード作成ロジック
│   │   ├── node_updater.dart            # ノード更新ロジック
│   │   └── node_deleter.dart            # ノード削除ロジック
│   │
│   ├── node_relationship/
│   │   ├── parent_child_handler.dart     # 親子関係の処理
│   │   └── node_alignment.dart          # ノードの配置処理
│   │
│   └── node_physics/
│       ├── physics_controller.dart       # 物理演算のコントローラー
│       └── physics_calculator.dart       # 物理計算ロジック
│
├── models/
│   ├── node.dart                        # ノードモデル (既存)
│   └── node_state.dart                  # ノードの状態管理
│
├── database/
│   ├── models/
│   │   ├── node_map_model.dart          # ノードマップモデル (既存)
│   │   └── node_model.dart              # ノードモデル (既存)
│   │
│   └── repositories/
│       ├── node_repository.dart         # ノードのデータ操作
│       └── node_map_repository.dart     # ノードマップのデータ操作
│
├── widgets/
│   ├── add_node_button.dart            # ノード追加ボタン (既存)
│   ├── node_contents_modal.dart         # ノードコンテンツモーダル (既存)
│   ├── positioned_text.dart             # 位置指定テキスト (既存)
│   ├── tool_bar.dart                    # ツールバー (既存)
│   └── node_display/
│       ├── node_renderer.dart           # ノード描画
│       └── node_painter.dart            # ノードペインター (既存)
│
├── utils/
│   ├── coordinate_utils.dart            # 座標変換 (既存)
│   ├── node_alignment.dart              # ノード配置 (既存)
│   ├── node_color_utils.dart            # ノード色管理 (既存)
│   ├── node_operations.dart             # ノード操作 (既存)
│   └── node_physics.dart                # ノード物理演算 (既存)
│
└── constants/
    └── node_constants.dart              # 定数定義 (既存)

    . 概要

本プロジェクトは、Flutterを用いたマインドマップアプリケーションです。Riverpodを用いた状態管理、カスタムペインターによる描画、データベースとの連携など、高度な機能を備えています。

2. アーキテクチャ

MVCアーキテクチャを採用しています。

Model (lib/models/): アプリケーションの状態を表すデータ構造を定義します。project.dart、node.dartなど、アプリケーションのデータモデルを定義するファイルが含まれています。
View (lib/screens/, lib/widgets/): ユーザーインターフェースを構成します。screens/フォルダには、各画面のウィジェットが配置され、widgets/フォルダには、再利用可能なウィジェットが配置されています。
Controller (lib/providers/, lib/utils/): アプリケーションの状態を管理し、ビジネスロジックを実装します。providers/フォルダには、Riverpodを用いた状態管理のProviderが定義され、utils/フォルダには、ユーティリティ関数やヘルパー関数が配置されています。
3. 主要機能

プロジェクト管理: プロジェクトの作成、編集、削除、検索機能。
マインドマップ作成: ノードの作成、編集、削除、移動機能。ノードにはテキスト、画像、アイコンなどを追加できます。
テーマ設定: アプリケーションのテーマをカスタマイズできます。
データベース連携: プロジェクトデータとノードデータをデータベースに保存します。
4. ディレクトリ構成

lib/constants/: アプリケーション全体で使用する定数を定義します。
lib/database/: データベース関連のコードを配置します。database_helper.dartはデータベースへのアクセスを処理し、database_schemas.dartはデータベーススキーマを定義します。models/にはデータベースモデルが定義されています。
lib/features/: アプリケーションの機能をモジュール化して配置します。現時点ではmind_map/のみ存在します。
lib/main.dart: アプリケーションのエントリポイントです。
lib/models/: アプリケーションのデータモデルを定義します。project.dart、node.dartなど、アプリケーションのデータモデルを定義するファイルが含まれています。
lib/painters/: カスタムペインターを定義します。node_painter.dartはノードを描画するペインター、dotted_border_painter.dartは点線を描画するペインターです。
lib/providers/: Riverpodを用いた状態管理のProviderを定義します。project_provider.dartはプロジェクトの状態を管理します。
lib/screens/: 各画面のウィジェットを配置します。splash_screen.dartはスプラッシュ画面、home_screen.dartはホーム画面、mind_map_screen.dartはマインドマップ画面です。
lib/theme/: アプリケーションのテーマを定義します。theme_data.dartはテーマデータを定義します。
lib/utils/: ユーティリティ関数やヘルパー関数を配置します。node_operations.dartはノード操作に関する関数、snackbar_helper.dartはSnackbar表示に関する関数を定義します。
lib/widgets/: 再利用可能なウィジェットを配置します。add_project_button.dart、project_list.dartなど、様々なウィジェットが含まれています。
5. 技術スタック

Flutter
Dart
Riverpod
SQLite (データベース)