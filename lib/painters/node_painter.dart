import 'dart:math';
import 'package:flutter/material.dart';
import '../models/node.dart';

/// ノードの描画を行うクラス
class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final double signalProgress;
  final double scale;
  final Offset offset;

  /// コンストラクタ
  ///
  /// [nodes] 描画対象のノード
  /// [signalProgress] 信号の進行割合
  /// [scale] スケールの倍率
  /// [offset] オフセット位置
  NodePainter(this.nodes, this.signalProgress, this.scale, this.offset);

  /// 座標をスケールとオフセットで変換する
  ///
  /// [x] X座標
  /// [y] Y座標
  Offset transformPoint(double x, double y) {
    return Offset(
      x * scale + offset.dx,
      y * scale + offset.dy,
    );
  }

  /// ノードがアクティブノードの系統に含まれるかを確認する
  ///
  /// [node] 判定対象のノード
  /// [activeNode] アクティブなノード
  bool isNodeInActiveLineage(Node node, Node? activeNode) {
    if (activeNode == null) return false;

    // 自分がアクティブノードかチェック
    if (node == activeNode) return true;

    // 親方向へのチェック（直系の親をすべてチェック）
    Node? current = activeNode.parent;
    while (current != null) {
      if (current == node) return true;
      current = current.parent;
    }

    // 子方向へのチェック（直系の子孫をすべてチェック）
    return isDescendantOfNode(node, activeNode);
  }

  /// 指定したノードが特定の祖先ノードの子孫かどうかを再帰的にチェックする
  ///
  /// [node] 判定対象のノード
  /// [ancestor] 祖先とするノード
  bool isDescendantOfNode(Node node, Node ancestor) {
    for (var child in ancestor.children) {
      if (child == node) return true;
      if (isDescendantOfNode(node, child)) return true;
    }
    return false;
  }

  /// ノードの描画を行う。
  ///
  /// [canvas] 描画するキャンバス
  /// [size]  キャンバスのサイズ
  @override
  void paint(Canvas canvas, Size size) {
    // アクティブノードを探す
    Node? activeNode;
    try {
      activeNode = nodes.firstWhere((node) => node.isActive);
    } catch (e) {
      activeNode = null;
    }

    // ノード間の接続線の描画
    for (var node in nodes) {
      if (node.parent != null) {
        // アクティブノードの系統かどうかをチェック
        bool isActiveLineage = isNodeInActiveLineage(node, activeNode) ||
            isNodeInActiveLineage(node.parent!, activeNode);

        // 線の設定
        final Paint linePaint = Paint()
          ..color = isActiveLineage
              ? Colors.yellow // アクティブ系統の線は黄色
              : Colors.white.withOpacity(0.5) // 通常の線は白
          ..strokeWidth = scale // 線の太さをスケールに基づいて設定
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

        // 開始点と終了点の座標を取得
        final Offset start = transformPoint(
          node.parent!.position.x,
          node.parent!.position.y,
        );
        final Offset end = transformPoint(
          node.position.x,
          node.position.y,
        );

        canvas.drawLine(start, end, linePaint);

        // 信号エフェクト
        double opacity = 1 * (0.5 + 0.5 * sin(signalProgress * 3.14159 * 5));
        final Paint signalPaint = Paint()
          ..color = isActiveLineage
              ? Colors.yellow.withOpacity(opacity) // アクティブ系統の信号は黄色
              : Colors.white.withOpacity(opacity) // 通常の信号は白
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, isActiveLineage ? scale * 1.5 : scale);

        // 信号位置を計算
        final double signalX = start.dx + (end.dx - start.dx) * signalProgress;
        final double signalY = start.dy + (end.dy - start.dy) * signalProgress;
        canvas.drawCircle(
            Offset(signalX, signalY),
            isActiveLineage ? 3 * scale : 2 * scale, // アクティブ系統の信号は大きく
            signalPaint);
      }
    }

    // ノードの描画
    for (var node in nodes) {
      final Offset center = transformPoint(node.position.x, node.position.y);
      final double scaledRadius = node.radius * scale;

      // 細胞膜のグロー効果
      if (node.isActive) {
        final Paint glowPaint = Paint()
          ..color = node.color.withOpacity(0.9)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
        canvas.drawCircle(center, scaledRadius * 1.8, glowPaint);
      }

      // 細胞膜のテクスチャ
      final Paint texturePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 0.5 * scale;

      // 細胞膜に配置する円形テクスチャ
      for (double i = 0; i < 360; i += 15) {
        final double angle = i * 3.14159 / 180;
        final double x1 = center.dx + scaledRadius * 1.5 * cos(angle);
        final double y1 = center.dy + scaledRadius * 1.5 * sin(angle);
        canvas.drawCircle(Offset(x1, y1), scale * 0.5, texturePaint);
      }

      // 細胞質のグラデーション表現
      final gradient = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.2),
          node.color.withOpacity(0.7),
          node.color.withOpacity(0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final Paint spherePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: scaledRadius),
        );

      canvas.drawCircle(center, scaledRadius, spherePaint);

      // 核の描画
      final double nucleusRadius = scaledRadius * 0.6;

      // 核膜の二重構造表現
      final Paint nuclearEnvelopePaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: nucleusRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * 0.1;

      // 核膜の内側の構造を描画
      canvas.drawCircle(
          center, nucleusRadius - scale * 2, nuclearEnvelopePaint);

      // 核小体の表現
      final Paint nucleolusPaint = Paint()
        ..color = node.color.withOpacity(1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

      for (int i = 0; i < 3; i++) {
        final double angle = Random().nextDouble() * 2 * pi;
        final double radius = nucleusRadius * 0.3 * Random().nextDouble();
        final Offset nucleolusPosition = Offset(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
        canvas.drawCircle(nucleolusPosition, scale * 2, nucleolusPaint);
      }

      // 核質の質感表現
      final Paint nucleoplasmPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, scale);

      for (int i = 0; i < 20; i++) {
        final double angle = Random().nextDouble() * 2 * pi;
        final double radius = nucleusRadius * Random().nextDouble() * 0.8;
        final Offset specklePosition = Offset(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
        canvas.drawCircle(specklePosition, scale * 0.5, nucleoplasmPaint);
      }

      // 光沢の表現
      final Paint highlightPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.2,
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: nucleusRadius));

      canvas.drawCircle(center, nucleusRadius, highlightPaint);
    }
  }

  /// 更新判定
  ///
  /// [oldDelegate] 更新前のインスタンス
  @override
  bool shouldRepaint(NodePainter oldDelegate) {
    return true;
  }
}
