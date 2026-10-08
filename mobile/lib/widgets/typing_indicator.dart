import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color dotColor;
  final double dotSize;

  const TypingIndicator({
    super.key,
    this.dotColor = const Color(0xFF0D9488),
    this.dotSize = 7.0,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double start = index * 0.2;
        final double end = start + 0.4;
        final double progress = _controller.value;

        double scale = 0.6;
        double opacity = 0.35;

        if (progress >= start && progress <= end) {
          final localT = (progress - start) / 0.4;
          final sine = (1 - (localT * 2 - 1).abs());
          scale = 0.6 + (0.4 * sine);
          opacity = 0.35 + (0.65 * sine);
        }

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDot(0),
          const SizedBox(width: 4.5),
          _buildDot(1),
          const SizedBox(width: 4.5),
          _buildDot(2),
        ],
      ),
    );
  }
}
