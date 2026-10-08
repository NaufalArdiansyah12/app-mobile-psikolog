import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'doctor_chat_screen.dart';

enum ConsultationSessionStatus {
  upcoming,
  active,
  expired,
}

class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({super.key});

  @override
  State<DoctorChatListScreen> createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final bookings = await _api.getDoctorBookings();
    if (mounted) {
      // 1 User = 1 Ruang Chat Konsultasi (Deduplikasi per user agar percakapan bersambung)
      final userRoomsMap = <String, Map<String, dynamic>>{};
      for (final b in bookings) {
        final status = (b['status'] ?? '').toString().toLowerCase();
        if (status != 'confirmed' && status != 'completed') continue;

        final userId = (b['user_id'] ?? '').toString().trim();
        final patientName = (b['patient_name'] ?? 'Pasien').toString().trim();
        final userKey = userId.isNotEmpty ? 'u_$userId' : 'name_${patientName.toLowerCase()}';

        if (!userRoomsMap.containsKey(userKey)) {
          userRoomsMap[userKey] = Map<String, dynamic>.from(b);
        } else {
          final existing = userRoomsMap[userKey]!;
          // Jika salah satu sesi 'confirmed' (aktif), jadikan ruangan berstatus aktif
          if (status == 'confirmed' && existing['status'] != 'confirmed') {
            userRoomsMap[userKey] = Map<String, dynamic>.from(b);
          }
        }
      }

      setState(() {
        _chatRooms = userRoomsMap.values.toList();
        _isLoading = false;
      });
    }
  }

  ConsultationSessionStatus _calculateSessionStatus(String schedule) {
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
        return ConsultationSessionStatus.upcoming;
      } else if (now.isAfter(endTime)) {
        return ConsultationSessionStatus.expired;
      } else {
        return ConsultationSessionStatus.active;
      }
    } catch (_) {
      return ConsultationSessionStatus.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ruang Chat Pasien',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0D9488)),
            tooltip: 'Perbarui',
            onPressed: _loadChats,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D9488),
                strokeWidth: 2.5,
              ),
            )
          : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  color: const Color(0xFF0D9488),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Header Counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                              Text(
                                "Sesi Konsultasi Pasien",
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${_chatRooms.length} Sesi",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card List
                      ..._chatRooms.map((item) {
                        return _buildChatCard(item);
                      }),
                    ],
                  ),
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
            const SizedBox(height: 20),
            Text(
              "Belum Ada Sesi Chat Pasien",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pasien yang booking dan terkonfirmasi akan muncul di sini saat sesi konsultasi aktif.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.45,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                "Perbarui Data",
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: _loadChats,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> item) {
    final patientName = item['patient_name'] ?? 'Pasien Hevenly';
    final scheduleTime = item['schedule_time'] ?? 'Jadwal Konsultasi';
    final notes = item['notes'] ?? 'Sesi konsultasi kesehatan mental';
    final rawStatus = (item['status'] ?? '').toString().toLowerCase();
    final bookingId = item['id']?.toString() ?? 'bk_doc_1';
    final patientAge = item['patient_age'] ?? 'Umum';

    // Hitung status sesi: upcoming, active, atau expired
    ConsultationSessionStatus sessionStatus;
    if (rawStatus == 'completed') {
      sessionStatus = ConsultationSessionStatus.expired;
    } else {
      sessionStatus = _calculateSessionStatus(scheduleTime);
    }

    final bool isUpcoming = sessionStatus == ConsultationSessionStatus.upcoming;
    final bool isExpired = sessionStatus == ConsultationSessionStatus.expired;

    final patientInitial = patientName.isNotEmpty ? patientName.trim()[0].toUpperCase() : 'P';

    // Warna & atribut kartu
    final Color cardBorderColor = isUpcoming
        ? const Color(0xFFFDE68A)
        : isExpired
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF99F6E4);

    final Color badgeBgColor = isUpcoming
        ? const Color(0xFFFEF3C7)
        : isExpired
            ? const Color(0xFFF1F5F9)
            : const Color(0xFFECFDF5);

    final Color badgeBorderColor = isUpcoming
        ? const Color(0xFFFDE68A)
        : isExpired
            ? const Color(0xFFCBD5E1)
            : const Color(0xFFA7F3D0);

    final Color badgeTextColor = isUpcoming
        ? const Color(0xFFB45309)
        : isExpired
            ? const Color(0xFF64748B)
            : const Color(0xFF059669);

    final String badgeText = isUpcoming
        ? "Segera Hadir"
        : isExpired
            ? "Selesai"
            : "Sesi Aktif";

    // Tombol: Kuning jika belum dimulai, Abu-abu jika selesai, Teal jika aktif
    final Color btnBgColor = isUpcoming
        ? const Color(0xFFD97706) // Kuning / Amber
        : isExpired
            ? const Color(0xFF64748B) // Abu-abu / Slate
            : const Color(0xFF0D9488); // Teal / Hijau

    final String btnText = isUpcoming
        ? "Buka Ruang Chat (Sesi Belum Mulai)"
        : isExpired
            ? "Lihat Riwayat Chat"
            : "Buka Ruang Chat";

    final IconData btnIcon = isUpcoming
        ? Icons.lock_clock_rounded
        : isExpired
            ? Icons.history_rounded
            : Icons.chat_bubble_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorderColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Pasien
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isExpired
                          ? null
                          : isUpcoming
                              ? const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                      color: isExpired ? const Color(0xFFF1F5F9) : null,
                    ),
                    child: Center(
                      child: Text(
                        patientInitial,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: isExpired ? const Color(0xFF64748B) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (!isExpired)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isUpcoming ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Detail Pasien
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pasien $patientAge • Konsultasi Privat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isUpcoming ? const Color(0xFFD97706) : const Color(0xFF0D9488),
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
                                    : Icons.access_time_filled_rounded,
                            size: 13,
                            color: isUpcoming
                                ? const Color(0xFFD97706)
                                : isExpired
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              scheduleTime,
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

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorderColor),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),

          // Complaint preview note
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                notes,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Tombol Aksi (Kuning jika belum mulai, Abu-abu jika selesai, Teal jika aktif)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: btnBgColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(btnIcon, size: 16),
              label: Text(
                btnText,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
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
                ).then((_) => _loadChats());
              },
            ),
          ),
        ],
      ),
    );
  }
}
