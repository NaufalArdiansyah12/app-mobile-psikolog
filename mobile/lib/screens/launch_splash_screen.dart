import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

class LaunchSplashScreen extends StatefulWidget {
  const LaunchSplashScreen({super.key});

  @override
  State<LaunchSplashScreen> createState() => _LaunchSplashScreenState();
}

class _LaunchSplashScreenState extends State<LaunchSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _timer = Timer(const Duration(milliseconds: 1500), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Warm Spotlight Glow (sama seperti referensi HTML)
          Positioned(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEFECE6).withValues(alpha: 0.9),
                    const Color(0xFFF7F4EE).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Logo Badge with Breathing Pulse
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF0A0A0A),
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "MindPal",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF09090B),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Ruang aman untuk bercerita",
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Discrete Bottom Status Pill
          const Positioned(
            bottom: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0A)),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Memuat ruang aman...",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFA1A1AA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
