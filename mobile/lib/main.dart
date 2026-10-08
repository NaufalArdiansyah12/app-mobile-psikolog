import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'screens/onboarding_screen.dart';
import 'screens/launch_splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/mood_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/doctor_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/crisis_modal_overlay.dart';
import 'widgets/notification_panel.dart';
import 'widgets/breathing_bubble_widget.dart';
import 'widgets/grounding_widget.dart';
import 'widgets/daily_mood_dialog.dart';
import 'widgets/doctor_avatar.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final prefs = await SharedPreferences.getInstance();
  final bool seenWalkthrough = prefs.getBool('seen_walkthrough') ?? false;
  final String? savedUuid = prefs.getString('mindpal_user_uuid');
  final bool isLoggedIn = prefs.getBool('mindpal_is_logged_in') ?? false;

  Widget initialScreen;
  if (!seenWalkthrough) {
    // 1. Fresh install: Tampilkan onboarding walkthrough (3 slide)
    initialScreen = const OnboardingScreen();
  } else if (!isLoggedIn || savedUuid == null || savedUuid.isEmpty) {
    // 2. Belum login: Wajib Login / Register
    initialScreen = const AuthScreen();
  } else {
    // 3. Sudah login: Tampilkan Brand Launch Splash Screen (~1.5 detik)
    initialScreen = const LaunchSplashScreen();
  }

  runApp(HevenlyApp(initialScreen: initialScreen));
}

class HevenlyApp extends StatelessWidget {
  final Widget initialScreen;

  const HevenlyApp({
    super.key,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hevenly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<MoodScreenState> _moodKey = GlobalKey<MoodScreenState>();
  final GlobalKey<ChatScreenState> _chatKey = GlobalKey<ChatScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),    // Tab 1: Beranda
    MoodScreen(key: _moodKey),    // Tab 2: Jurnal & Mood
    ChatScreen(key: _chatKey),    // Tab 3: Hevenly AI (Tengah)
    const ConsultationScreen(),   // Tab 4: Konsultasi (Ahli)
    const SettingsScreen(),       // Tab 5: Profil
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DailyMoodDialog.showIfNeeded(context);
      _homeKey.currentState?.loadMoodData();
    });
  }

  void _onTabSelected(int index) async {
    if (_currentIndex == index) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (_currentIndex == 2 && (_chatKey.currentState?.hasUnsavedMessages ?? false)) {
      final shouldProceed = await _chatKey.currentState?.confirmExitIfUnsaved();
      if (shouldProceed != true) return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _currentIndex = index);
    if (index == 0) {
      _homeKey.currentState?.loadMoodData();
    } else if (index == 1) {
      _moodKey.currentState?.loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
        if (_currentIndex == 2 && (_chatKey.currentState?.hasUnsavedMessages ?? false)) {
          final shouldProceed = await _chatKey.currentState?.confirmExitIfUnsaved();
          if (shouldProceed == true) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _currentIndex = 0);
            _homeKey.currentState?.loadMoodData();
          }
          return;
        }
        if (_currentIndex != 0) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _currentIndex = 0);
          _homeKey.currentState?.loadMoodData();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: isKeyboardOpen
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, "Beranda"),
                          _buildNavItem(1, Icons.auto_stories_outlined, Icons.auto_stories_rounded, "Jurnal"),
                          _buildCenterAiNavItem(2),
                          _buildNavItem(3, Icons.medical_services_outlined, Icons.medical_services_rounded, "Konsultasi"),
                          _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, "Profil"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCCFBF1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
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
      onTap: () => _onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D9488),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Hevenly AI",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  String _nickname = 'Sobat';
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();

  List<MoodEntry> _recentMoods = []; // 7 hari terakhir

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'tag': 'PROMO KHUSUS',
      'title': 'Diskon 30% Sesi Pertama\nBersama Psikolog',
      'desc': 'Konseling online privat tanpa antre',
      'buttonText': 'Klaim Sekarang',
      'color': Color(0xFF0D9488),
      'icon': Icons.local_offer_rounded,
    },
    {
      'tag': 'FITUR BARU',
      'title': 'Ruang Curhat AI 24/7\nBebas Penghakiman',
      'desc': 'Teman cerita kapan pun cemas melanda',
      'buttonText': 'Mulai Curhat',
      'color': Color(0xFF0F766E),
      'icon': Icons.chat_bubble_outline_rounded,
    },
    {
      'tag': 'WORKSHOP KLINIS',
      'title': 'Atasi Overthinking &\nKecemasan Akut',
      'desc': 'Panduan praktis dari psikiater spesialis',
      'buttonText': 'Ikuti Workshop',
      'color': Color(0xFF115E59),
      'icon': Icons.self_improvement_rounded,
    },
  ];

  static const List<Map<String, dynamic>> _defaultDoctors = [
    {
      'id': 'psy_1',
      'name': 'dr. Nadia S., Sp.KJ',
      'role': 'Psikiater Klinis Dewasa',
      'specialty': 'Depresi, Insomnia & Trauma',
      'rating': '4.9',
      'reviews': '340',
      'fee': 'Rp 250.000',
      'experience': '9 Tahun',
      'patients': '2.100+',
      'education': 'Spesialis Kedokteran Jiwa - FK Universitas Indonesia',
      'str': 'STR: 31.1.2.100.3.19.112233',
      'bio': 'Spesialis dalam farmakoterapi dan psikoterapi suportif untuk kasus gangguan suasana hati (mood disorder), insomnia berkepanjangan, dan pemulihan trauma psikologis.',
      'avatarBg': Color(0xFFCCFBF1),
      'avatarColor': Color(0xFF0D9488),
      'icon': Icons.medical_services_rounded,
    },
    {
      'id': 'psy_2',
      'name': 'Dimas Pratama, M.Psi., Psikolog',
      'role': 'Psikolog Klinis Dewasa',
      'specialty': 'Burnout, Karir & Hubungan',
      'rating': '4.8',
      'reviews': '210',
      'fee': 'Rp 180.000',
      'experience': '6 Tahun',
      'patients': '1.350+',
      'education': 'Magister Psikologi Profesi Klinis - Universitas Gadjah Mada',
      'str': 'STR: 33.2.1.200.2.20.445566',
      'bio': 'Fokus pada konseling workplace wellbeing, quarter-life crisis, manajemen konflik relasi, dan restorasi motivasi diri melalui pendekatan Cognitive Behavioral Therapy.',
      'avatarBg': Color(0xFFFEF3C7),
      'avatarColor': Color(0xFFD97706),
      'icon': Icons.person_outline_rounded,
    },
    {
      'id': 'psy_3',
      'name': 'Chloe Kelly, M.Psi., Psikolog',
      'role': 'Spesialis Regulasi Emosi & Cemas',
      'specialty': 'Panic Attack & Mindfulness',
      'rating': '4.9',
      'reviews': '280',
      'fee': 'Rp 150.000',
      'experience': '7 Tahun',
      'patients': '1.800+',
      'education': 'Magister Psikologi Klinis - Universitas Padjadjaran',
      'str': 'STR: 32.2.1.150.1.21.778899',
      'bio': 'Berpengalaman mendampingi individu dengan Generalized Anxiety Disorder (GAD), serangan panik, dan psikosomatis melalui terapi Mindfulness-Based Stress Reduction.',
      'avatarBg': Color(0xFFFCE7F3),
      'avatarColor': Color(0xFFDB2777),
      'icon': Icons.face_3_rounded,
    },
    {
      'id': 'psy_4',
      'name': 'dr. Alana Pradipta, Sp.KJ',
      'role': 'Psikiater Konsultasi Keluarga',
      'specialty': 'Manajemen Stres & Bipolar',
      'rating': '4.9',
      'reviews': '195',
      'fee': 'Rp 220.000',
      'experience': '10 Tahun',
      'patients': '2.450+',
      'education': 'Spesialis Ilmu Kedokteran Jiwa - FK Universitas Airlangga',
      'str': 'STR: 35.1.2.300.4.18.990011',
      'bio': 'Ahli dalam diagnosa dan penanganan komprehensif spektrum bipolar, manajemen stres keluarga, serta konsultasi kesehatan mental remaja & dewasa muda.',
      'avatarBg': Color(0xFFEEF2FF),
      'avatarColor': Color(0xFF4F46E5),
      'icon': Icons.psychology_rounded,
    },
  ];

  List<Map<String, dynamic>> _doctors = List.from(_defaultDoctors);

  @override
  void initState() {
    super.initState();
    _loadUser();
    loadMoodData();
    loadDoctors();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void loadDoctors() async {
    try {
      final docs = await _api.getPsychologists();
      if (mounted && docs.isNotEmpty) {
        setState(() => _doctors = docs);
      }
    } catch (_) {}
  }

  void loadMoodData() async {
    final list = await _storage.getMoods();
    if (mounted) {
      setState(() => _recentMoods = list);
    }
    loadDoctors();
  }

  int _calculateStreak() {
    if (_recentMoods.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool hasEntryOn(DateTime date) {
      return _recentMoods.any((m) {
        final d = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
        return d == date;
      });
    }

    int streak = 0;
    DateTime checkDate = today;
    if (!hasEntryOn(checkDate)) {
      // Jika hari ini belum check-in, cek mulai dari kemarin
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (hasEntryOn(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _getMoodEmoji(int score) {
    switch (score) {
      case 1:
        return '😢';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  Color _getMoodColor(int score) {
    switch (score) {
      case 1:
        return const Color(0xFFF87171);
      case 2:
        return const Color(0xFF38BDF8);
      case 3:
        return const Color(0xFFFFA69E);
      case 4:
        return const Color(0xFFFFD166);
      case 5:
        return const Color(0xFF4ADE80);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _loadUser() async {
    final name = await _storage.getNickname();
    if (mounted && name.isNotEmpty) {
      setState(() => _nickname = name);
    }
  }

  void _showBreathingModal(BreathingTechnique technique) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: BreathingBubbleWidget(technique: technique),
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

  void _showBookingSheet(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (dialogCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                DoctorAvatar(
                  doctor: doctor,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor['role'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Biaya Sesi (2 Jam)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    (doctor['fee'] ?? doctor['price'] ?? 'Rp 150.000').toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0D9488),
                      content: Text(
                        'Jadwal konsultasi berhasil diajukan untuk ${doctor["name"]}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Konfirmasi Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF006D77);

    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HEADER SECTION (Hijau Aqua / Deep Teal)
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 14.0),
              child: Column(
                children: [
                  // User Greeting & Quick Action Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: primaryTeal,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back,',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _nickname,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Hero Doctor Illustration Card (Desain Sesuai Referensi)
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                    ),
                    child: Stack(
                      children: [
                        // Background Doctor Image
                        Positioned(
                          right: -10,
                          bottom: -15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/gambar_home.jpeg',
                              width: 135,
                              height: 135,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 90,
                                height: 90,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCCFBF1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: primaryTeal,
                                  size: 38,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Soft Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: const [0.0, 0.65, 1.0],
                                colors: [
                                  primaryTeal.withValues(alpha: 0.95),
                                  primaryTeal.withValues(alpha: 0.75),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Content Text
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 110, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello,  👋',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'How can we\nhelp you today?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Temukan Psikolog & Konseling',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. BOTTOM HALF CURVED CARD (Card Putih Melengkung)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 100.0),
                  children: [
            // 2. SLIDER BANNER PROMOSI / INFO (Bagian Atas)
            SizedBox(
              height: 156,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _promoBanners.length,
                onPageChanged: (idx) => setState(() => _bannerIndex = idx),
                itemBuilder: (context, index) {
                  final banner = _promoBanners[index];
                  final Color bannerColor = banner['color'] as Color;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: bannerColor.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  banner['tag'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banner['title'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  banner['buttonText'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: bannerColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              child: Icon(
                                banner['icon'] as IconData,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Banner Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_promoBanners.length, (i) {
                final isCurrent = i == _bannerIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isCurrent ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // 3. CARD DAILY MOOD LOG (Di bawah Slider)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Mood Log',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFD97706),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _calculateStreak() > 0
                                  ? '${_calculateStreak()}-Day Streak'
                                  : 'Mulai Streak',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Baris 7 Hari Kalender Mingguan (Senin s/d Minggu)
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final monday = today.subtract(Duration(days: today.weekday - 1));
                      const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (idx) {
                          final dayDate = monday.add(Duration(days: idx));
                          final isToday = dayDate == today;
                          final isFuture = dayDate.isAfter(today);

                          // Cari apakah ada mood log untuk hari ini
                          MoodEntry? entry;
                          for (final m in _recentMoods) {
                            final mDate = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
                            if (mDate == dayDate) {
                              entry = m;
                              break;
                            }
                          }

                          final loggedEntry = entry;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (loggedEntry != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFF0F172A),
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        '${dayLabels[idx]} (${dayDate.day}/${dayDate.month}): ${loggedEntry.label}${loggedEntry.notes != null ? " - ${loggedEntry.notes}" : ""}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (isToday) {
                                  // Klik hari ini untuk isi mood
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => const DailyMoodDialog(),
                                  ).then((_) => loadMoodData());
                                }
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: idx == 6 ? 0 : 5),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: loggedEntry != null
                                      ? _getMoodColor(loggedEntry.score).withValues(alpha: 0.15)
                                      : isToday
                                          ? const Color(0xFFF1F5F9)
                                          : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isToday
                                        ? const Color(0xFF0D9488)
                                        : loggedEntry != null
                                            ? _getMoodColor(loggedEntry.score).withValues(alpha: 0.4)
                                            : const Color(0xFFE2E8F0),
                                    width: isToday ? 1.8 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dayLabels[idx],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                        color: isToday
                                            ? const Color(0xFF0D9488)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (loggedEntry != null)
                                      Text(
                                        _getMoodEmoji(loggedEntry.score),
                                        style: const TextStyle(fontSize: 18),
                                      )
                                    else if (isFuture)
                                      Text(
                                        '•',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: const Color(0xFFCBD5E1),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    else
                                      Text(
                                        '-',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: const Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${dayDate.day}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                        color: isToday
                                            ? const Color(0xFF0D9488)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 4. LATIHAN INTERAKTIF (Di bawah Daily Mood Log)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latihan Relaksasi Interaktif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Klinis & Aman',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dua Kartu Interaktif: Box Breathing & Grounding 5-4-3-2-1
            Row(
              children: [
                // Box Breathing (Liquid Glass)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        onTap: () => _showBreathingModal(BreathingTechnique.box),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.air_rounded,
                                  color: Color(0xFFD97706),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Box Breathing',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tahan napas 4 detik saat cemas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Grounding 5-4-3-2-1 (Liquid Glass)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        onTap: _showGroundingModal,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1).withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.self_improvement_rounded,
                                  color: Color(0xFF0D9488),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Grounding 5-4-3-2-1',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Redakan overthinking & panik',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF115E59),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 5. BOOKING DOKTER / PSIKOLOG (Tanpa Kategori, Khusus Mental Health)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Dokter & Psikolog',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Tersedia Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List Nama-Nama Dokter / Psikolog Mental Health
            ...List.generate(_doctors.length, (idx) {
              final doc = _doctors[idx];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailScreen(doctor: doc),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                  children: [
                    // Avatar Bulat
                    DoctorAvatar(
                      doctor: doc,
                      size: 50,
                    ),
                    const SizedBox(width: 12),

                    // Detail Dokter (Nama, Role, Spesialisasi, Rating)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (doc['name'] ?? 'Dokter').toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (doc['role'] ?? 'Psikolog Klinis').toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                (doc['rating'] != null && doc['rating'].toString() != '-' && doc['rating'].toString() != '0')
                                    ? '${doc["rating"]} (${doc["reviews"] ?? 0})'
                                    : 'Baru',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Biaya & Tombol Book Now
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (doc['fee'] ?? doc['price'] ?? 'Rp 150.000').toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showBookingSheet(doc),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Book Now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  ],
),
      ),
    );
  }
}
