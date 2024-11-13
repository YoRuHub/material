class NodeConstants {
  /// ノード間の最小距離
  static const double minDistance = 100.0;

  /// ノード同士の反発力の強さ
  static const double repulsionStrength = 0.0001;

  /// ノード間の引力の強さ
  static const double attractionStrength = 0.01;

  /// 物理演算の総ステップ数
  static const int totalSteps = 60;

  /// 初期配置時のノード間距離の閾値
  static const double initialDistanceThreshold = 100;

  /// ノード間の理想的な距離
  static const double idealDistance = 100;

  /// 力の最大倍率
  static const double maxStrengthMultiplier = 0.1;

  /// ノードの色の彩度（0.0 - 1.0）
  static const double saturation = 0.7;

  /// ノードの色の明度（0.0 - 1.0）
  static const double lightness = 0.6;

  /// ノード間の水平方向の間隔
  static const double nodeHorizontalSpacing = 100.0;

  /// 階層間の垂直方向の間隔
  static const double levelHeight = 100.0;

  /// ノードの色の不透明度（0.0 - 1.0）
  static const double alpha = 1.0;

  /// 世代ごとの色相のシフト量（度数）
  static const double hueShift = 20.0;

  /// 色相の最大値（360度）
  static const double maxHue = 360.0;

  /// ノードの標準半径
  static const double defaultNodeRadius = 20.0;

  /// 最小拡大率
  static const double minScale = 0.1;

  /// 最大拡大率
  static const double maxScale = 5.0;

  /// 新規ノードのデフォルトX座標
  static const double defaultStartX = 100.0;

  /// 新規ノードのデフォルトY座標
  static const double defaultStartY = 100.0;

  /// ノード間の相互作用が発生する距離
  static const double nodeInteractionDistance = 30.0;

  /// ノードがスナップする距離
  static const double nodeSnapDistance = 10.0;

  /// ノードの移動量
  static const double nodeMovementAmount = 2.0;

  /// アニメーションフレームの更新間隔
  static const Duration animationFrameDuration = Duration(milliseconds: 16);

  /// 速度の減衰率（0.0 - 1.0）
  static const double velocityDamping = 0.9;

  /// ランダム配置時の最大オフセット範囲
  static const double randomOffsetRange = 200.0;

  /// ランダムオフセット範囲の半分（中心からの距離）
  static const double randomOffsetHalf = randomOffsetRange / 2;

  /// ドラッグ中のノードへの追従速度
  static const double dragSpeed = 10.0;

  /// ノード同士がスナップする距離
  static const double snapDistance = 50.0;

  /// ノードの最小接近距離
  static const double minApproachDistance = 10.0;
}
