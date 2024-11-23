import 'package:flutter/material.dart';

class SphericalColorWidget extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;
  final bool showCheckmark;
  final IconData checkIcon; // アイコンの種類を引数として追加

  // 定数の定義
  static const double _kDefaultSize = 40.0;
  static const double _kMinLightnessAdjustment = 0.2;
  static const double _kMaxLightnessAdjustment = 0.2;
  static const double _kTweenScaleBegin = 0.8;
  static const double _kTweenScaleEnd = 1.0;
  static const double _kCheckIconSizeRatio = 0.5;
  static const double _kBoxShadowOpacity = 0.5;
  static const double _kSelectedBoxShadowOpacity = 0.6;
  static const double _kShadowBlurRadius = 4.0;
  static const double _kShadowSpreadRadius = 0.0;
  static const Duration _kAnimationDuration = Duration(milliseconds: 200);

  const SphericalColorWidget({
    super.key,
    required this.color,
    this.isSelected = false,
    this.size = _kDefaultSize,
    this.onTap,
    this.showCheckmark = true,
    this.checkIcon = Icons.check, // デフォルトアイコンは check
  });

  // アイコンの色を計算
  Color _getIconColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.lightness > 0.5 ? Colors.black : Colors.white;
  }

  // より明るい色を取得
  Color _getBrighterColor(Color baseColor) {
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor
        .withLightness(
            (hslColor.lightness + _kMinLightnessAdjustment).clamp(0.0, 1.0))
        .withSaturation(
            (hslColor.saturation - _kMinLightnessAdjustment).clamp(0.0, 1.0))
        .toColor();
  }

  // より暗い色を取得
  Color _getDarkerColor(Color baseColor) {
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor
        .withLightness(
            (hslColor.lightness - _kMaxLightnessAdjustment).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final brighterColor = _getBrighterColor(color);
    final darkerColor = _getDarkerColor(color);
    final iconColor = _getIconColor(color);

    return TweenAnimationBuilder<double>(
      duration: _kAnimationDuration,
      tween: Tween(
          begin: _kTweenScaleBegin,
          end: isSelected ? _kTweenScaleEnd : _kTweenScaleBegin),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.5),
              radius: 0.9,
              colors: [
                brighterColor,
                color,
                darkerColor,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: darkerColor.withOpacity(_kBoxShadowOpacity),
                offset: const Offset(2, 2),
                blurRadius: _kShadowBlurRadius,
                spreadRadius: _kShadowSpreadRadius,
              ),
              if (isSelected)
                BoxShadow(
                  color: color.withOpacity(_kSelectedBoxShadowOpacity),
                  offset: const Offset(0, 0),
                  blurRadius: 8.0,
                  spreadRadius: 2.0,
                ),
            ],
          ),
          child: showCheckmark
              ? AnimatedOpacity(
                  duration: _kAnimationDuration,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Center(
                    child: Icon(
                      checkIcon, // アイコンを引数として指定
                      color: iconColor,
                      size: size * _kCheckIconSizeRatio,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
