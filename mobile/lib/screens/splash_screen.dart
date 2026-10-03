import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class WalkthroughSlide {
  final String title;
  final String description;
  final Widget illustration;

  WalkthroughSlide({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishWalkthrough();
    }
  }

  void _onSkip() {
    _finishWalkthrough();
  }

  void _finishWalkthrough() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_walkthrough', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Aqua Glow Spotlight
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCCFBF1).withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),

            // Main Carousel & Content
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildSlide(
                        title: "Curhat Bebas Tanpa\nPenghakiman",
                        description:
                            "Teman AI yang selalu siap mendengarkan 24/7 dan membantumu menata pikiran yang berisik.",
                        illustration: _buildSlide1Illustration(),
                      ),
                      _buildSlide(
                        title: "Latihan Relaksasi &\nRegulasi Emosi",
                        description:
                            "Panduan napas Box Breathing dan teknik Grounding 5-4-3-2-1 saat cemas atau panik melanda.",
                        illustration: _buildSlide2Illustration(),
                      ),
                      _buildSlide(
                        title: "Privasi Utuh &\nKonsultasi Ahli",
                        description:
                            "Data aman tanpa KYC dan akses terhubung ke psikolog profesional saat kamu siap.",
                        illustration: _buildSlide3Illustration(),
                      ),
                    ],
                  ),
                ),

                // Pagination Indicator & Controls
                _buildBottomControls(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String description,
    required Widget illustration,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 8),
                // Illustration Stage
                SizedBox(
                  height: 280,
                  child: Center(child: illustration),
                ),
                // Pagination Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalPages, (i) {
                    final isCurrent = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF0A0A0A) : const Color(0xFFD4D4D8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Typography Content Block
                Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF09090B),
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF52525B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // Slide 1: AI Listening & Mindful Workspace
  Widget _buildSlide1Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Spotlight circle
        Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            color: Color(0xFFEFECE6),
            shape: BoxShape.circle,
          ),
        ),
        // Floating Heart / Care Pill
        Positioned(
          top: 20,
          left: 15,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Color(0xFFE11D48), size: 22),
          ),
        ),
        // Floating Trend Indicator
        Positioned(
          top: 25,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 14),
                SizedBox(width: 4),
                Text(
                  "Hevenly AI",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Avatar Center
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D9488),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/illustrations/chat_bubble_3d.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Slide 2: Breathing & Relaxation
  Widget _buildSlide2Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            color: Color(0xFFEFECE6),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.air, color: Color(0xFFB45309), size: 20),
          ),
        ),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD99B26).withValues(alpha: 0.15),
            border: Border.all(color: const Color(0xFFD99B26), width: 2),
          ),
          child: Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D9488),
              ),
              child: Image.asset(
                'assets/illustrations/meditation_3d.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.self_improvement,
                  size: 45,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Slide 3: Secure & Connected Care
  Widget _buildSlide3Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            color: Color(0xFFEFECE6),
            shape: BoxShape.circle,
          ),
        ),
        Positioned(
          top: 20,
          left: 15,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.verified_user, color: Color(0xFF0D9488), size: 20),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF18181B),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
              ),
            ],
          ),
          child: Image.asset(
            'assets/illustrations/blue_shield_3d.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.lock_person_outlined,
              size: 50,
              color: Color(0xFF18181B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final isLast = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: SizedBox(
        height: 52,
        child: isLast
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0A0A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _onNext,
                  child: const Text(
                    "MULAI SEKARANG",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      "LEWATI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF09090B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _onNext,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "LANJUT",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
