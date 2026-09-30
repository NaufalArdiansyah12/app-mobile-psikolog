import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/launch_splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/mood_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/breathing_bubble_widget.dart';
import 'widgets/grounding_widget.dart';
import 'widgets/crisis_modal_overlay.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool seenWalkthrough = prefs.getBool('seen_walkthrough') ?? false;
  final String? savedUuid = prefs.getString('mindpal_user_uuid');

  Widget initialScreen;
  if (!seenWalkthrough) {
    // 1. Fresh install: Tampilkan onboarding walkthrough (3 slide)
    initialScreen = const OnboardingScreen();
  } else if (savedUuid == null || savedUuid.isEmpty) {
    // 2. Sudah onboarding tapi belum login/tamu
    initialScreen = const AuthScreen();
  } else {
    // 3. Sudah login/tamu: Tampilkan Brand Launch Splash Screen (~1.5 detik)
    initialScreen = const LaunchSplashScreen();
  }

  runApp(MindPalApp(initialScreen: initialScreen));
}

class MindPalApp extends StatelessWidget {
  final Widget initialScreen;

  const MindPalApp({
    super.key,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF09090B),
          primary: const Color(0xFF09090B),
          surface: const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: initialScreen,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),         // Tab 1: Beranda
    MoodScreen(),         // Tab 2: Jurnal & Mood
    ChatScreen(),         // Tab 3: MindPal AI (Tengah)
    ConsultationScreen(), // Tab 4: Konsultasi (Ahli)
    SettingsScreen(),     // Tab 5: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, "Beranda"),
                _buildNavItem(1, Icons.auto_stories_outlined, Icons.auto_stories, "Jurnal"),
                _buildCenterAiNavItem(2),
                _buildNavItem(3, Icons.medical_services_outlined, Icons.medical_services, "Konsultasi"),
                _buildNavItem(4, Icons.person_outline, Icons.person, "Profil"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? const Color(0xFF09090B) : const Color(0xFF71717A),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF09090B) : const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAiNavItem(int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0A0A), Color(0xFF27272A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "MindPal AI",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF09090B) : const Color(0xFF52525B),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  String _nickname = 'Sobat';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final name = await _storage.getNickname();
    if (mounted) setState(() => _nickname = name);
  }

  void _showBreathingModal(BreathingTechnique tech) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: BreathingBubbleWidget(technique: tech),
      ),
    );
  }

  void _showGroundingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: GroundingExerciseWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        title: const Text(
          "MindPal",
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF09090B), letterSpacing: -0.5),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sos_rounded, color: Colors.redAccent),
            tooltip: "Bantuan Darurat SOS",
            onPressed: () => CrisisModalOverlay.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Halo, $_nickname",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand, color: Color(0xFFFBBF24), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ruang amanmu untuk curhat 24/7 tanpa penghakiman. Semua data tersimpan aman dan privat.",
                  style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Pertolongan Pertama Emosional",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF09090B)),
          ),
          const SizedBox(height: 12),
          _buildExerciseCard(
            title: "Box Breathing (4-4-4-4)",
            subtitle: "Menenangkan detak jantung cepat dan dada berdebar",
            icon: Icons.air,
            color: const Color(0xFF0D9488),
            onTap: () => _showBreathingModal(BreathingTechnique.box),
          ),
          const SizedBox(height: 10),
          _buildExerciseCard(
            title: "Relaksasi 4-7-8",
            subtitle: "Membantu meredakan overthinking menjelang tidur",
            icon: Icons.bedtime_outlined,
            color: const Color(0xFF4F46E5),
            onTap: () => _showBreathingModal(BreathingTechnique.relax478),
          ),
          const SizedBox(height: 10),
          _buildExerciseCard(
            title: "Teknik Grounding 5-4-3-2-1",
            subtitle: "Kembalikan fokus saat panic attack atau disosiasi",
            icon: Icons.psychology_outlined,
            color: const Color(0xFFD97706),
            onTap: _showGroundingModal,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.phone_in_talk, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Butuh Bantuan Segera?",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF09090B)),
                      ),
                      Text(
                        "Layanan konseling krisis gratis Kemenkes 119 ext. 8",
                        style: TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.redAccent),
                  onPressed: () => CrisisModalOverlay.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
        trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFF09090B)),
        onTap: onTap,
      ),
    );
  }
}
