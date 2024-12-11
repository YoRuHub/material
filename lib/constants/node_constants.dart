class NodeConstants {
  // --- 距離関連定数 ---
  /// ノード間の理想的な距離（引力と反発力が均衡する距離）
  static const double parentChildDistance = 100.0;

  /// リンク間の理想的な距離
  static const double linkDistance = 1000.0;

  /// ノードがスナップするための閾値距離（ユーザー操作で接近時に使用）
  static const double snapEffectRange = 50.0;

  // --- 力・物理演算関連定数 ---
  /// ノード同士の反発力を決定する係数（小さいほど反発力が弱い）
  static const double repulsionCoefficient = 0.001;

  /// 速度の減衰率（フレームごとに速度が減少する割合）
  static const double velocityDampingFactor = 0.9;

  /// 親子関係の引力パラメータ
  static const double parentChildAttraction = 10;

  // リンク関係の引力パラメータ
  static const double linkAttraction = 1;

  // --- アニメーション関連定数 ---
  /// アニメーション全体のフレーム数（動きが滑らかになるステップ数）
  static const int totalAnimationFrames = 60;

  /// アニメーションの各フレーム間隔（1フレームの描画にかかる時間）
  static const int frameInterval = 16;

  // --- 色関連定数 ---
  /// ノードの色の彩度（0.0 - 1.0 の範囲で色の鮮やかさを設定）
  static const double saturation = 0.7;

  /// ノードの色の明度（0.0 - 1.0 の範囲で色の明るさを設定）
  static const double lightness = 0.6;

  /// ノードの色の不透明度（0.0 - 1.0 の範囲で色の透明度を設定）
  static const double alpha = 1.0;

  /// 世代ごとの色相のシフト量（ツリー構造の階層ごとに色相を変更）
  static const double hueShift = 20.0;

  /// 色相の最大値（360度表記で色相の範囲を指定）
  static const double maxHue = 360.0;

  // --- ノード関連定数 ---
  /// ノードの標準的な半径（UI上での見た目のサイズ）
  static const double defaultNodeRadius = 30.0;

  /// ズームアウト時の最小拡大率（0.0 - 1.0 の範囲）
  static const double minScale = 0.01;

  /// ズームイン時の最大拡大率
  static const double maxScale = 5.0;

  /// ノードをランダム配置する際の最大オフセット範囲
  static const double randomOffsetRange = 200.0;

  // --- その他定数 ---
  /// ドラッグ中のノードの追従速度（ユーザー操作時の動きの速さ）
  static const double dragVelocityMultiplier = 10.0;

  /// ノードの移動量（操作時に1ステップで移動する距離）
  static const double nodeMovementAmount = 2.0;

  /// ランダムオフセット範囲の半分（中心からの距離）
  static const double randomOffsetHalf = randomOffsetRange / 2;

  /// デタッチするノードの速度
  static const double touchSpeedMultiplier = 30;

  ///　操作タイマーの間隔（5分間の間隔を指定）
  static const int inactiveDurationTime = 60 * 5;
}
