import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'doctor_chat_screen.dart';
import 'doctor_edit_schedule_screen.dart';

class DoctorBookingsScreen extends StatefulWidget {
  final VoidCallback? onRefreshParent;

  const DoctorBookingsScreen({super.key, this.onRefreshParent});

  @override
  State<DoctorBookingsScreen> createState() => _DoctorBookingsScreenState();
}

class _DoctorBookingsScreenState extends State<DoctorBookingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String _activeFilter = 'Semua'; // 'Semua', 'Terkonfirmasi', 'Menunggu', 'Selesai'
  List<Map<String, dynamic>> _bookings = [];

  final List<String> _daysIndo = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  final List<String> _monthsIndo = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final list = await _api.getDoctorBookings();
    if (mounted) {
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    final success = await _api.updateBookingStatus(bookingId: bookingId, status: newStatus);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Janji temu berhasil dikonfirmasi'
                : newStatus == 'completed'
                    ? 'Sesi konsultasi ditandai selesai'
                    : 'Status janji temu diperbarui',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _fetchBookings();
      widget.onRefreshParent?.call();
    }
  }

  bool _isScheduleToday(dynamic scheduleRaw) {
    if (scheduleRaw == null) return false;
    final schedule = scheduleRaw.toString().trim();
    final lower = schedule.toLowerCase();
    if (lower.contains('hari ini') || lower.contains('today')) return true;

    final now = DateTime.now();

    // 1. Cek format ISO YYYY-MM-DD
    final isoMatch = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(schedule);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1) ?? '');
      final m = int.tryParse(isoMatch.group(2) ?? '');
      final d = int.tryParse(isoMatch.group(3) ?? '');
      if (y == now.year && m == now.month && d == now.day) return true;
    }

    // 2. Bulan Indonesia & Inggris
    const monthsMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'may': 5,
      'jun': 6, 'jul': 7, 'agu': 8, 'aug': 8, 'sep': 9, 'okt': 10,
      'oct': 10, 'nov': 11, 'des': 12, 'dec': 12
    };

    int? schedMonth;
    for (final entry in monthsMap.entries) {
      if (lower.contains(entry.key)) {
        schedMonth = entry.value;
        break;
      }
    }

    // 3. Tahun
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(schedule);
    final schedYear = yearMatch != null ? int.tryParse(yearMatch.group(1)!) : now.year;

    // 4. Hari (1-31)
    final dayMatches = RegExp(r'\b(\d{1,2})\b').allMatches(schedule).toList();
    for (final dm in dayMatches) {
      final dVal = int.tryParse(dm.group(1) ?? '0') ?? 0;
      if (dVal >= 1 && dVal <= 31 && dVal != (schedYear! % 100)) {
        if (schedMonth != null) {
          if (dVal == now.day && schedMonth == now.month && schedYear == now.year) {
            return true;
          }
        } else if (dVal == now.day) {
          return true;
        }
      }
    }

    return false;
  }

  List<Map<String, dynamic>> get _todayBookings {
    return _bookings.where((b) => _isScheduleToday(b['schedule_time'])).toList();
  }

  List<Map<String, dynamic>> get _filteredBookings {
    final list = _todayBookings;
    if (_activeFilter == 'Semua') return list;
    if (_activeFilter == 'Terkonfirmasi') {
      return list.where((b) => b['status'] == 'confirmed').toList();
    }
    if (_activeFilter == 'Menunggu') {
      return list.where((b) => b['status'] == 'pending').toList();
    }
    if (_activeFilter == 'Selesai') {
      return list.where((b) => b['status'] == 'completed').toList();
    }
    return list;
  }

  String get _todayFormattedText {
    final now = DateTime.now();
    final dayName = _daysIndo[now.weekday - 1];
    final monthName = _monthsIndo[now.month];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = _todayBookings.length;
    final confirmedCount = _todayBookings.where((b) => b['status'] == 'confirmed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Janji Temu Hari Ini',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0D9488)),
            tooltip: 'Atur Jam Praktik',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorEditScheduleScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0D9488)),
            tooltip: 'Perbarui',
            onPressed: _fetchBookings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Header Date Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: const Color(0xFFF1F5F9), width: 1)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayFormattedText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$todayCount Pasien Terjadwal Hari Ini • $confirmedCount Aktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFCCFBF1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Terkonfirmasi', 'Menunggu', 'Selesai'].map((filter) {
                  final isSelected = _activeFilter == filter;
                  int count = 0;
                  if (filter == 'Semua') {
                    count = _todayBookings.length;
                  } else if (filter == 'Terkonfirmasi') {
                    count = _todayBookings.where((b) => b['status'] == 'confirmed').length;
                  } else if (filter == 'Menunggu') {
                    count = _todayBookings.where((b) => b['status'] == 'pending').length;
                  } else if (filter == 'Selesai') {
                    count = _todayBookings.where((b) => b['status'] == 'completed').length;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _activeFilter = filter),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Booking List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        color: const Color(0xFF0D9488),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final item = _filteredBookings[index];
                            return _buildBookingCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCCFBF1),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 40,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tidak Ada Jadwal Hari Ini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeFilter == 'Semua'
                  ? 'Belum ada janji temu pasien yang terjadwal untuk hari ini ($todayLabel).'
                  : 'Tidak ada janji temu dengan status "$_activeFilter" untuk hari ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Perbarui Data',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get todayLabel {
    final now = DateTime.now();
    return '${now.day} ${_monthsIndo[now.month]} ${now.year}';
  }

  Widget _buildBookingCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final patientName = item['patient_name'] ?? 'Pasien Hevenly';
    final scheduleTime = item['schedule_time'] ?? 'Jadwal Konsultasi';
    final notes = item['notes'] ?? 'Sesi konsultasi privat kesehatan mental bersama tenaga ahli.';
    final bookingId = item['id']?.toString() ?? '';

    Color badgeBg;
    Color badgeFg;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'confirmed':
        badgeBg = const Color(0xFFECFDF5);
        badgeFg = const Color(0xFF047857);
        statusLabel = 'Terkonfirmasi';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'completed':
        badgeBg = const Color(0xFFF1F5F9);
        badgeFg = const Color(0xFF475569);
        statusLabel = 'Selesai';
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        badgeBg = const Color(0xFFFEF2F2);
        badgeFg = const Color(0xFFB91C1C);
        statusLabel = 'Dibatalkan';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        badgeBg = const Color(0xFFFFFBEB);
        badgeFg = const Color(0xFFB45309);
        statusLabel = 'Menunggu Konfirmasi';
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: status == 'confirmed' ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pasien & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pasien Konsultasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeFg.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Waktu Sesi Konsultasi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scheduleTime,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hari Ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Catatan Keluhan Pasien
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_outlined, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notes,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Aksi Dokter
          Row(
            children: [
              if (status == 'pending') ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _updateStatus(bookingId, 'cancelled'),
                    child: Text(
                      'Tolak',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(bookingId, 'confirmed'),
                    child: Text(
                      'Terima Janji Temu',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ] else if (status == 'confirmed') ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: Text(
                      'Buka Chat Sesi',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorChatScreen(
                            bookingId: bookingId,
                            userId: item['user_id']?.toString(),
                            patientName: patientName,
                            patientAge: item['patient_age'],
                            bookingNotes: notes,
                            scheduleTime: scheduleTime,
                          ),
                        ),
                      ).then((completed) {
                        if (completed == true) {
                          _updateStatus(bookingId, 'completed');
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                      backgroundColor: const Color(0xFFF0FDFA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _updateStatus(bookingId, 'completed'),
                    child: Text(
                      'Selesai',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else if (status == 'completed') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: Text(
                      'Lihat Riwayat Chat',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorChatScreen(
                            bookingId: bookingId,
                            userId: item['user_id']?.toString(),
                            patientName: patientName,
                            patientAge: item['patient_age'],
                            bookingNotes: notes,
                            scheduleTime: scheduleTime,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
