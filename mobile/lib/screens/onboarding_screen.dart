import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
      backgroundColor: const Color(0xFFF6FAF8),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Soft Gradient Orbs
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D9488).withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              top: 240,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD97706).withValues(alpha: 0.08),
                ),
              ),
            ),

            // Carousel Slide
            Column(
              children: [
                // Top Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage < _totalPages - 1)
                        TextButton(
                          onPressed: _onSkip,
                          child: Text(
                            "Lewati",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildSlide(
                        tag: "TEMAN CURHAT 24/7",
                        title: "Curhat Bebas Tanpa\nPenghakiman",
                        description:
                            "Teman AI empatik yang selalu siap mendengarkan kapan pun dan membantumu mengurai benang kusut di kepala.",
                        illustration: _buildSlide1Illustration(),
                      ),
                      _buildSlide(
                        tag: "MINDFULNESS & NAFAS",
                        title: "Latihan Relaksasi &\nRegulasi Emosi",
                        description:
                            "Panduan Box Breathing dan teknik Grounding 5-4-3-2-1 ilmiah untuk meredakan panik & cemas seketika.",
                        illustration: _buildSlide2Illustration(),
                      ),
                      _buildSlide(
                        tag: "PRIVASI & AHLI KLINIS",
                        title: "Privasi Utuh &\nKonsultasi Ahli",
                        description:
                            "Jaminan data aman tanpa KYC serta akses langsung jadwal konsultasi dokter & psikolog klinis terpercaya.",
                        illustration: _buildSlide3Illustration(),
                      ),
                    ],
                  ),
                ),

                // Controls
                _buildBottomControls(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required String tag,
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
                SizedBox(
                  height: 290,
                  child: Center(child: illustration),
                ),

                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalPages, (i) {
                    final isCurrent = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 28 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D9488),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
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

  // Slide 1: AI Chat Curhat
  Widget _buildSlide1Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFCCFBF1).withValues(alpha: 0.8),
                const Color(0xFFE6FFFA).withValues(alpha: 0.2),
              ],
            ),
          ),
        ),

        // Floating Love Badge
        Positioned(
          top: 15,
          left: 15,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 20),
          ),
        ),

        // Floating MindPal AI Pill
        Positioned(
          top: 20,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 14),
                const SizedBox(width: 5),
                Text(
                  "MindPal AI",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Central 3D Chat Bubble
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/illustrations/chat_bubble_3d.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.chat_bubble_rounded,
                size: 58,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Slide 2: Mindfulness & Breathing
  Widget _buildSlide2Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFEF3C7).withValues(alpha: 0.8),
                const Color(0xFFFFFBEB).withValues(alpha: 0.2),
              ],
            ),
          ),
        ),

        // Floating Wind/Air Badge
        Positioned(
          top: 15,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.air_rounded, color: Color(0xFF0D9488), size: 15),
                const SizedBox(width: 4),
                Text(
                  "Box Breathing",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Central Meditation Avatar
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/illustrations/meditation_3d.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.self_improvement_rounded,
                size: 58,
                color: Color(0xFFD97706),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Slide 3: Dokter Psikolog & Privasi Terjamin (Desain Baru Elegan & Nyaman)
  Widget _buildSlide3Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft Teal Aura Circle
        Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFCCFBF1).withValues(alpha: 0.85),
                const Color(0xFFE6FFFA).withValues(alpha: 0.15),
              ],
            ),
          ),
        ),

        // Floating Shield / Zero-KYC Badge Kiri Atas
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF0D9488), size: 15),
                const SizedBox(width: 4),
                Text(
                  "100% Anonim",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Verified Dokter Kanan Atas
        Positioned(
          top: 15,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF0D9488), size: 20),
          ),
        ),

        // Central Doctor Card dengan Frame Cantik
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF99F6E4), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.22),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/gambar_home.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: 54,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
                // Soft bottom gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF006D77).withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Psikolog Ahli",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Star Rating Kiri Bawah
        Positioned(
          bottom: 12,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 3),
                Text(
                  "4.9",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final isLast = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        height: 52,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: _onNext,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLast ? "Mulai Sekarang" : "Lanjutkan",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
