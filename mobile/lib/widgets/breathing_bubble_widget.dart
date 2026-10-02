import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BreathingTechnique { box, relax478 }

class BreathingBubbleWidget extends StatefulWidget {
  final BreathingTechnique technique;
  final VoidCallback? onComplete;

  const BreathingBubbleWidget({
    super.key,
    this.technique = BreathingTechnique.box,
    this.onComplete,
  });

  @override
  State<BreathingBubbleWidget> createState() => _BreathingBubbleWidgetState();
}

class _BreathingBubbleWidgetState extends State<BreathingBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<Color?> _color;
  String _guideText = "Tarik Napas";
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scale = Tween<double>(begin: 0.75, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _color = ColorTween(begin: Colors.teal.shade300, end: Colors.teal.shade600)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _startCycle();
  }

  void _haptic() => HapticFeedback.lightImpact();

  void _startCycle() async {
    while (_running && mounted) {
      // Tarik napas
      _haptic();
      if (mounted) setState(() => _guideText = "Tarik Napas...");
      await _controller.forward();
      if (!_running || !mounted) break;

      // Tahan
      _haptic();
      if (mounted) setState(() => _guideText = "Tahan...");
      await Future.delayed(
        Duration(seconds: widget.technique == BreathingTechnique.box ? 4 : 7),
      );
      if (!_running || !mounted) break;

      // Hembuskan
      _haptic();
      if (mounted) setState(() => _guideText = "Hembuskan...");
      await _controller.reverse();
      if (!_running || !mounted) break;

      // Jeda (Box Breathing)
      if (widget.technique == BreathingTechnique.box) {
        _haptic();
        if (mounted) setState(() => _guideText = "Istirahat...");
        await Future.delayed(const Duration(seconds: 4));
      }
    }
  }

  @override
  void dispose() {
    _running = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.technique == BreathingTechnique.box
        ? "Box Breathing • 4-4-4-4"
        : "Relaksasi • 4-7-8";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  if (widget.onComplete != null) {
                    widget.onComplete!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color.value ?? const Color(0xFF0D9488),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _guideText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Ikuti ritme pernapasan ini untuk menenangkan pikiran",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
