import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color backgroundColor;
  final Color iconColor;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 72,
    this.iconSize = 36,
    this.borderRadius = 22,
    this.backgroundColor = const Color(0xFF0D9488),
    this.iconColor = Colors.white,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.spa_rounded,
              color: iconColor,
              size: iconSize,
            ),
            Positioned(
              top: iconSize * 0.1,
              right: iconSize * 0.1,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: const Color(0xFFCCFBF1),
                size: iconSize * 0.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
