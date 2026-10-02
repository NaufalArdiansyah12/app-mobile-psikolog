import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_panel.dart';
import 'doctor_chat_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DoctorHomeScreen({super.key, this.onNavigateTab});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  bool _isAvailable = true;
  String _doctorName = 'dr. Nadia S., Sp.KJ';
  String _specialization = 'Psikiater Klinis';
  double _rating = 4.9;
  int _totalConsultations = 14;
  int _todaySessions = 2;
  String _earnings = 'Rp 3.500.000';
  List<Map<String, dynamic>> _todayBookings = [];

  static const Color primaryTeal = Color(0xFF006D77);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final savedName = await _storage.getNickname();
    if (savedName.isNotEmpty && savedName != 'Sobat MindPal') {
      _doctorName = savedName;
    }

    final dashboardData = await _api.getDoctorDashboard();
    final bookingsData = await _api.getDoctorBookings();

    if (mounted) {
      setState(() {
        if (dashboardData != null) {
          _doctorName = dashboardData['name'] ?? _doctorName;
          _specialization = dashboardData['specialization'] ?? _specialization;
          _rating = (dashboardData['rating'] as num?)?.toDouble() ?? _rating;
          _totalConsultations = dashboardData['total_consultations'] ?? _totalConsultations;
          _todaySessions = dashboardData['today_sessions'] ?? _todaySessions;
          _isAvailable = dashboardData['is_available'] ?? true;
          _earnings = dashboardData['earnings_this_month'] ?? _earnings;
        }
        _todayBookings = bookingsData.take(3).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    final success = await _api.updateDoctorAvailability(value);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Status: Siap Menerima Pasien (Online)' : 'Status: Sedang Istirahat (Offline)',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: value ? AppColors.primary : AppColors.slate,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HEADER SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 14.0),
              child: Column(
                children: [
                  // Greeting & Quick Action Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
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
                                Icons.medical_services_rounded,
                                color: primaryTeal,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portal Dokter MindPal',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      _doctorName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Colors.white, size: 15),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Online/Offline Pill
                          GestureDetector(
                            onTap: () => _toggleAvailability(!_isAvailable),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isAvailable ? const Color(0xFFECFDF5) : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isAvailable ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isAvailable ? const Color(0xFF10B981) : Colors.white70,
                                      boxShadow: _isAvailable
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isAvailable ? 'Online' : 'Offline',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _isAvailable ? const Color(0xFF047857) : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Notification Bell
                          InkWell(
                            onTap: () => NotificationPanel.show(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  Positioned(
                                    top: 7,
                                    right: 7,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Hero Doctor Illustration Card
                  Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
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
                              width: 140,
                              height: 140,
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
                          padding: const EdgeInsets.fromLTRB(16, 14, 110, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Selamat Bertugas! 👋',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Siap dampingi pasien\nhari ini?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _specialization,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.flash_on_rounded, color: Color(0xFFFDE047), size: 11),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$_todaySessions Sesi Terjadwal',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

            // 2. BOTTOM HALF CURVED CARD
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 100.0),
                          children: [
                            // Status Praktik Banner
                            _buildDutyStatusBanner(),
                            const SizedBox(height: 18),

                            // Ringkasan Statistik Dokter
                            _buildExecutiveStats(),
                            const SizedBox(height: 22),

                            // Antrean Janji Temu Hari Ini
                            _buildTodayQueueHeader(),
                            const SizedBox(height: 12),
                            _buildTodayQueueList(),
                            const SizedBox(height: 22),

                            // Menu Pintasan Cepat
                            _buildQuickActions(),
                            const SizedBox(height: 20),

                            // Tips Klinis / Banner Edukasi
                            _buildClinicalTipCard(),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isAvailable ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isAvailable ? AppColors.cardAquaBorder : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isAvailable ? AppColors.primary.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isAvailable ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  _isAvailable ? Icons.headset_mic_rounded : Icons.pause_circle_outline_rounded,
                  color: _isAvailable ? AppColors.primaryDark : AppColors.muted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAvailable ? 'Menerima Pasien (Aktif)' : 'Sedang Istirahat (Offline)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _isAvailable ? AppColors.primaryDark : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isAvailable ? 'Notifikasi konsultasi langsung aktif' : 'Jadwal konsultasi ditutup sementara',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _isAvailable,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.mutedLight.withValues(alpha: 0.5),
              onChanged: _toggleAvailability,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Praktik',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bulan Ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Primary Honor Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006D77), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Estimasi Pendapatan Praktik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _earnings,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Siap dicairkan ke rekening terdaftar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFFFDE047), size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3 Secondary Stats Cards in Row
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.calendar_today_rounded,
                label: 'Sesi Hari Ini',
                value: '$_todaySessions Pasien',
                color: AppColors.primary,
                bg: const Color(0xFFF0FDFA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.people_alt_rounded,
                label: 'Total Selesai',
                value: '$_totalConsultations Sesi',
                color: const Color(0xFF2563EB),
                bg: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStatCard(
                icon: Icons.star_rounded,
                label: 'Rating',
                value: '$_rating ★',
                color: const Color(0xFFD97706),
                bg: const Color(0xFFFFFBEB),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayQueueHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Antrean Pasien Hari Ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (_todayBookings.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_todayBookings.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ],
        ),
        GestureDetector(
          onTap: () => widget.onNavigateTab?.call(1),
          child: Row(
            children: [
              Text(
                'Lihat Semua',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayQueueList() {
    if (_todayBookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.muted,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada janji konsultasi hari ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Jadwal baru dari pasien akan muncul di sini secara otomatis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _todayBookings.map((b) {
        final patientName = b['patient_name'] ?? 'Pasien MindPal';
        final time = b['schedule_time'] ?? 'Hari ini, 19:00';
        final notes = b['notes'] ?? 'Keluhan kecemasan dan stres harian.';
        final status = b['status'] ?? 'confirmed';
        final isConfirmed = status == 'confirmed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConfirmed ? const Color(0xFF99F6E4) : AppColors.borderLight,
              width: isConfirmed ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Header Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFCCFBF1),
                            border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                          ),
                          child: Center(
                            child: Text(
                              patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  time,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConfirmed ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isConfirmed ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Text(
                        isConfirmed ? 'Siap Konseling' : 'Menunggu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isConfirmed ? const Color(0xFF047857) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Patient Notes Preview
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Keluhan: $notes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.slate,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                    label: Text(
                      'Buka Ruang Konseling',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorChatScreen(
                            bookingId: b['id']?.toString() ?? 'bk_doc_1',
                            patientName: patientName,
                            bookingNotes: notes,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Pintasan Dokter',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.calendar_month_rounded,
                title: 'Jadwal Janji',
                subtitle: 'Kelola sesi',
                iconColor: AppColors.primary,
                bgColor: const Color(0xFFF0FDFA),
                onTap: () => widget.onNavigateTab?.call(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Pasien',
                subtitle: 'Riwayat aktif',
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () => widget.onNavigateTab?.call(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.badge_outlined,
                title: 'Profil STR',
                subtitle: 'Tarif & info',
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: () => widget.onNavigateTab?.call(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF16A34A),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Praktik MindPal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Awali sesi dengan validasi perasaan pasien untuk membangun ruang aman dan rasa percaya lebih cepat.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF15803D),
                    height: 1.3,
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
