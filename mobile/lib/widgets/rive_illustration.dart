import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveIllustration extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final double fallbackSize;
  final Color fallbackColor;

  const RiveIllustration({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.fallbackSize = 50,
    this.fallbackColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: FileLoader.fromAsset(asset, riveFactory: Factory.rive),
      builder: (context, state) {
        if (state case RiveLoaded(:final controller)) {
          return RiveWidget(controller: controller, fit: Fit.contain);
        }
        if (state case RiveFailed()) {
          return Icon(fallbackIcon, size: fallbackSize, color: fallbackColor);
        }
        return Icon(
          fallbackIcon,
          size: fallbackSize,
          color: fallbackColor.withValues(alpha: 0.45),
        );
      },
    );
  }
}
