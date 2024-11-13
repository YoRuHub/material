class NodeConstants {
  // 物理演算関連の定数
  static const double minDistance = 150.0;
  static const double repulsionStrength = 0.0001;
  static const double attractionStrength = 0.01;
  static const int totalSteps = 60;
  static const double initialDistanceThreshold = 150;
  static const double idealDistance = 150;
  static const double maxStrengthMultiplier = 0.1;

  // ノードの見た目関連の定数
  static const double saturation = 0.7;
  static const double lightness = 0.6;
  static const double nodeHorizontalSpacing = 150.0;
  static const double levelHeight = 150.0;
  static const double alpha = 1.0;
  static const double hueShift = 20.0;
  static const double maxHue = 360.0;
  static const double defaultNodeRadius = 20.0;

  // ズーム関連の定数
  static const double minScale = 0.1;
  static const double maxScale = 5.0;

  // ノードの配置関連の定数
  static const double defaultStartX = 100.0;
  static const double defaultStartY = 100.0;
  
  // ノードの相互作用関連の定数
  static const double nodeInteractionDistance = 30.0;
  static const double nodeSnapDistance = 10.0;
  static const double nodeMovementAmount = 2.0;

  // アニメーション関連の定数
  static const Duration animationFrameDuration = Duration(milliseconds: 16);
  static const double velocityDamping = 0.9;

  // ランダム配置関連の定数
  static const double randomOffsetRange = 50.0;
  static const double randomOffsetHalf = randomOffsetRange / 2;
}