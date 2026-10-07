import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'doctor_detail_screen.dart';
import 'doctor_consultation_chat_screen.dart';

enum ConsultationSessionStatus {
  active,
  upcoming,
  expired,
}

class SessionTimeInfo {
  final ConsultationSessionStatus status;
  final String statusLabel;

  const SessionTimeInfo({
    required this.status,
    required this.statusLabel,
  });
}

SessionTimeInfo calculateSessionTimeInfo(String schedule) {
  try {
    final now = DateTime.now();
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').allMatches(schedule).toList();
    int startHour = 9;
    int startMin = 0;
    int endHour = 11;
    int endMin = 0;

    if (timeMatch.isNotEmpty) {
      startHour = int.tryParse(timeMatch[0].group(1) ?? '9') ?? 9;
      startMin = int.tryParse(timeMatch[0].group(2) ?? '0') ?? 0;
      if (timeMatch.length > 1) {
        endHour = int.tryParse(timeMatch[1].group(1) ?? '11') ?? 11;
        endMin = int.tryParse(timeMatch[1].group(2) ?? '0') ?? 0;
      } else {
        endHour = startHour + 2;
        endMin = startMin;
      }
    }

    final lower = schedule.toLowerCase();
    int day = now.day;
    int month = now.month;
    int year = now.year;

    if (lower.contains('besok') || lower.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      day = tomorrow.day;
      month = tomorrow.month;
      year = tomorrow.year;
    } else if (lower.contains('hari ini') || lower.contains('today')) {
      day = now.day;
      month = now.month;
      year = now.year;
    } else {
      final isoMatch = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(schedule);
      if (isoMatch != null) {
        year = int.tryParse(isoMatch.group(1) ?? '$year') ?? year;
        month = int.tryParse(isoMatch.group(2) ?? '$month') ?? month;
        day = int.tryParse(isoMatch.group(3) ?? '$day') ?? day;
      } else {
        final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(schedule);
        if (yearMatch != null) {
          year = int.tryParse(yearMatch.group(1) ?? '$year') ?? year;
        }

        const monthsMap = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'may': 5,
          'jun': 6, 'jul': 7, 'agu': 8, 'aug': 8, 'sep': 9, 'okt': 10,
          'oct': 10, 'nov': 11, 'des': 12, 'dec': 12
        };
        for (final entry in monthsMap.entries) {
          if (lower.contains(entry.key)) {
            month = entry.value;
            break;
          }
        }

        final dayMatches = RegExp(r'\b(\d{1,2})\b').allMatches(schedule).toList();
        for (final dm in dayMatches) {
          final dVal = int.tryParse(dm.group(1) ?? '0') ?? 0;
          if (dVal >= 1 && dVal <= 31 && dVal != (year % 100) && dVal != startHour && dVal != endHour) {
            day = dVal;
            break;
          }
        }
      }
    }

    final startTime = DateTime(year, month, day, startHour, startMin);
    final endTime = DateTime(year, month, day, endHour, endMin);

    if (now.isBefore(startTime)) {
      return const SessionTimeInfo(
        status: ConsultationSessionStatus.upcoming,
        statusLabel: 'Segera Hadir',
      );
    } else if (now.isAfter(endTime)) {
      return const SessionTimeInfo(
        status: ConsultationSessionStatus.expired,
        statusLabel: 'Sesi Selesai',
      );
    } else {
      return const SessionTimeInfo(
        status: ConsultationSessionStatus.active,
        statusLabel: 'Sedang Berlangsung',
      );
    }
  } catch (_) {
    return const SessionTimeInfo(
      status: ConsultationSessionStatus.active,
      statusLabel: 'Sesi Aktif',
    );
  }
}

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  int _selectedTab = 0; // 0: Cari Psikolog, 1: Sesi Chat Dokter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String _userUuid = '';
  List<Map<String, dynamic>> _therapists = [];
  List<Map<String, dynamic>> _activeSessions = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initData() async {
    final uuid = await _storage.getOrCreateUserUuid();
    final docs = await _apiService.getPsychologists();
    final sessions = await _apiService.getUserActiveSessions(uuid);
    if (!mounted) return;

    // Deduplikasi sesi per dokter agar perpanjangan sesi memperbarui ruangan yang sama
    final seenDocIds = <String>{};
    final dedupedSessions = <Map<String, dynamic>>[];
    for (final s in sessions) {
      final doc = s['doctor'] as Map<String, dynamic>?;
      final docId = (doc?['id'] ?? s['psychologist_id'] ?? '').toString();
      if (docId.isNotEmpty && !seenDocIds.contains(docId)) {
        seenDocIds.add(docId);
        dedupedSessions.add(s);
      } else if (docId.isEmpty) {
        dedupedSessions.add(s);
      }
    }

    setState(() {
      _userUuid = uuid;
      _therapists = docs.isNotEmpty ? docs : _defaultTherapists;
      _activeSessions = dedupedSessions;
      _isLoading = false;
    });
  }

  final List<Map<String, dynamic>> _defaultTherapists = [
    {
      'id': 'psy_1',
      'name': 'dr. Nadia S., Sp.KJ',
      'role': 'Psikiater Klinis',
      'experience': '8 tahun',
      'rating': 4.9,
      'price': 'Rp 250.000',
      'category': 'Trauma & Depresi',
      'hospital': 'RS Mitra Sehat Jakarta',
      'available': 'Hari ini, 19:00',
    },
    {
      'id': 'psy_2',
      'name': 'Dimas Pratama, M.Psi., Psikolog',
      'role': 'Psikolog Klinis Dewasa',
      'experience': '5 tahun',
      'rating': 4.8,
      'price': 'Rp 180.000',
      'category': 'Karir & Burnout',
      'hospital': 'Praktek Mandiri Online',
      'available': 'Besok, 14:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF006D77);

    // Smart Filter: Nama, Spesialisasi/Role, Kategori, Rumah Sakit, & Filter Pengalaman (e.g. "> 3 tahun", "lebih dari 5 tahun")
    final filtered = _therapists.where((doc) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();

      final name = (doc['name'] ?? '').toString().toLowerCase();
      final role = (doc['role'] ?? '').toString().toLowerCase();
      final category = (doc['category'] ?? '').toString().toLowerCase();
      final hospital = (doc['hospital'] ?? '').toString().toLowerCase();
      final exp = (doc['experience'] ?? '').toString().toLowerCase();

      // 1. Text contains match
      if (name.contains(q) ||
          role.contains(q) ||
          category.contains(q) ||
          hospital.contains(q) ||
          exp.contains(q)) {
        return true;
      }

      // 2. Experience numeric filter (e.g. "lebih dari 3", ">3", "di atas 5", "min 3")
      final expYears = int.tryParse(RegExp(r'\d+').firstMatch(exp)?.group(0) ?? '0') ?? 0;
      final matchExpNum = RegExp(r'(?:lebih\s*dari|>|di\s*atas|min(?:imal)?)\s*(\d+)').firstMatch(q);
      if (matchExpNum != null) {
        final targetYears = int.tryParse(matchExpNum.group(1) ?? '0') ?? 0;
        return expYears >= targetYears;
      }

      return false;
    }).toList();

    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Konsultasi Ahli",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTab == 0
                        ? "Jadwalkan sesi privat bersama psikolog & psikiater terpercaya"
                        : "Ruang konsultasi privat dan riwayat chat dokter Anda",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Segmented Switch: [Cari Dokter]  [Sesi Chat Dokter]
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tabWidth = constraints.maxWidth / 2;
                        return Stack(
                          children: [
                            // Sliding pill background indicator
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOutCubic,
                              alignment: _selectedTab == 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                width: tabWidth,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Tab buttons (GestureDetector tanpa ripple/hover berlebih)
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (_selectedTab != 0) {
                                        setState(() => _selectedTab = 0);
                                      }
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            size: 16,
                                            color: _selectedTab == 0 ? primaryTeal : Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Cari Dokter",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: _selectedTab == 0 ? primaryTeal : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (_selectedTab != 1) {
                                        setState(() => _selectedTab = 1);
                                      }
                                    },
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 16,
                                            color: _selectedTab == 1 ? primaryTeal : Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Sesi Chat",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: _selectedTab == 1 ? primaryTeal : Colors.white,
                                            ),
                                          ),
                                          if (_activeSessions.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: _selectedTab == 1
                                                    ? primaryTeal
                                                    : const Color(0xFF10B981),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                "${_activeSessions.length}",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Search Filter Bar (Hanya di Tab Cari Dokter)
                  if (_selectedTab == 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: "Cari dokter, spesialisasi, atau '> 3 thn'...",
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. BOTTOM HALF CURVED CARD
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                    : RefreshIndicator(
                        onRefresh: () async => _initData(),
                        color: primaryTeal,
                        child: _selectedTab == 0
                            ? _buildPsychologistList(filtered)
                            : _buildActiveSessionsList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Daftar Dokter & Psikolog
  Widget _buildPsychologistList(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.search_off_rounded, size: 32, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Dokter Tidak Ditemukan",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tidak ada tenaga ahli yang cocok dengan kata kunci '$_searchQuery'. Coba cari nama, kategori, atau angka pengalaman.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.4,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0D9488)),
              label: Text(
                "Reset Pencarian",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFF0D9488),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _searchQuery.isEmpty ? "Daftar Tenaga Ahli" : "Hasil Pencarian",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              "${filtered.length} Tersedia",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D9488),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...filtered.map((doc) => _buildDoctorCard(doc)),
      ],
    );
  }

  // TAB 2: Daftar Sesi Chat Aktif
  Widget _buildActiveSessionsList() {
    if (_activeSessions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1).withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF99F6E4), width: 2),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum Ada Sesi Konsultasi",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Jadwalkan sesi privat bersama psikolog atau psikiater berlisensi untuk memulai ruang obrolan konsultasi.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.45,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                "Cari Dokter Sekarang",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => setState(() => _selectedTab = 0),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Sesi Konsultasi Terkonfirmasi",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_activeSessions.length} Sesi",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._activeSessions.map((session) {
          final doc = (session['doctor'] as Map<String, dynamic>?) ?? {};
          final docName = doc['name'] ?? 'dr. Spesialis';
          final docRole = doc['role'] ?? 'Psikiater Klinis';
          final schedule = session['schedule_time'] ?? 'Jadwal Konsultasi';
          final bookingId = session['booking_id']?.toString() ?? '';

          final sessionTimeInfo = calculateSessionTimeInfo(schedule);
          final bool isUpcoming = sessionTimeInfo.status == ConsultationSessionStatus.upcoming;
          final bool isExpired = sessionTimeInfo.status == ConsultationSessionStatus.expired;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUpcoming
                    ? const Color(0xFFFDE68A)
                    : isExpired
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFCCFBF1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUpcoming
                            ? const Color(0xFFFEF3C7)
                            : isExpired
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFCCFBF1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.medical_services_rounded,
                          color: isUpcoming
                              ? const Color(0xFFD97706)
                              : isExpired
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF0D9488),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            docRole,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUpcoming
                                      ? Icons.schedule_rounded
                                      : isExpired
                                          ? Icons.lock_clock_rounded
                                          : Icons.event_available_rounded,
                                  size: 13,
                                  color: isUpcoming
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    schedule,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFFFEF3C7)
                            : isExpired
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isUpcoming
                              ? const Color(0xFFFDE68A)
                              : isExpired
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Text(
                        sessionTimeInfo.statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                          color: isUpcoming
                              ? const Color(0xFFB45309)
                              : isExpired
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpired
                          ? const Color(0xFF64748B)
                          : isUpcoming
                              ? const Color(0xFF0F766E)
                              : const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      isExpired ? Icons.history_rounded : Icons.chat_bubble_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isExpired
                          ? "Lihat Riwayat Chat"
                          : isUpcoming
                              ? "Lihat Ruang Chat (Sesi Belum Mulai)"
                              : "Buka Ruang Chat",
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      final fullDoc = _therapists.firstWhere(
                        (p) => p['id']?.toString() == doc['id']?.toString(),
                        orElse: () => doc,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorConsultationChatScreen(
                            bookingId: bookingId,
                            doctor: fullDoc,
                            scheduleTime: schedule,
                          ),
                        ),
                      ).then((_) => _initData());
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(doctor: doc),
          ),
        ).then((_) => _initData());
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF0D9488), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doc['role'] ?? '',
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (doc['rating'] != null && doc['rating'].toString() != '-' && doc['rating'].toString() != '0')
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: (doc['rating'] != null && doc['rating'].toString() != '-' && doc['rating'].toString() != '0')
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF94A3B8),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  (doc['rating'] != null && doc['rating'].toString().isNotEmpty && doc['rating'].toString() != '0')
                                      ? "${doc['rating']}"
                                      : "-",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: (doc['rating'] != null && doc['rating'].toString() != '-' && doc['rating'].toString() != '0')
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "• ${(doc['experience'] != null && doc['experience'].toString().isNotEmpty) ? doc['experience'] : '-'}",
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "• ${(doc['hospital'] != null && doc['hospital'].toString().isNotEmpty) ? doc['hospital'] : '-'}",
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tarif Sesi (2 Jam)",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                    Text(
                      doc['price'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorDetailScreen(doctor: doc),
                      ),
                    ).then((_) => _initData());
                  },
                  child: Text(
                    "Jadwalkan",
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
