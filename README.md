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
├── constants/
│   ├── node_constants.dart         # ノード関連の定数
│   └── theme_constants.dart        # テーマ関連の定数
│
├── database/
│   ├── database_helper.dart        # データベースヘルパー
│   └── models/
│       ├── node_map_model.dart     # ノードマップモデル
│       └── node_model.dart         # ノードモデル
│
├── features/
│   └── mind_map/
│       ├── screens/
│       │   └── mind_map_screen.dart    # メインスクリーン
│       ├── controllers/
│       │   ├── node_controller.dart     # ノード操作のコントローラー
│       │   └── physics_controller.dart  # 物理演算のコントローラー
│       ├── widgets/
│       │   ├── add_node_button.dart    # ノード追加ボタン
│       │   ├── node_contents_modal.dart # ノードコンテンツモーダル
│       │   ├── positioned_text.dart     # 配置されたテキスト
│       │   └── tool_bar.dart           # ツールバー
│       └── services/
│           ├── node_service.dart        # ノード操作のサービス
│           └── layout_service.dart      # レイアウト調整サービス
│
├── models/
│   └── node.dart                   # ノードモデル
│
├── utils/
│   ├── coordinate_utils.dart       # 座標変換ユーティリティ
│   ├── node_alignment.dart         # ノード配置ユーティリティ
│   ├── node_operations.dart        # ノード操作ユーティリティ
│   └── node_physics.dart          # 物理演算ユーティリティ
│
└── painters/
    └── node_painter.dart           # ノード描画クラス


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