import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ai_screening_modal.dart';

enum DoctorChatSessionStatus {
  upcoming,
  active,
  expired,
}

class DoctorChatSessionInfo {
  final DoctorChatSessionStatus status;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color themeColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  const DoctorChatSessionInfo({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.themeColor,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });
}

class DoctorChatScreen extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final String? patientAge;
  final String? bookingNotes;
  final String? doctorId;
  final String? userId;
  final String? scheduleTime;
  final Map<String, dynamic>? aiScreening;

  const DoctorChatScreen({
    super.key,
    this.bookingId = 'bk_doc_1',
    required this.patientName,
    this.patientAge,
    this.bookingNotes,
    this.doctorId,
    this.userId,
    this.scheduleTime,
    this.aiScreening,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String _doctorName = 'dr. Nadia S., Sp.KJ';
  String _doctorId = '3354dda3-863d-48a2-ab48-19d1cded24dc';
  late String _scheduleTime;

  final List<String> _quickDoctorChips = [
    "Halo, bagaimana kabar Anda hari ini?",
    "Bisa ceritakan apa yang sedang Anda rasakan?",
    "Kapan keluhan ini mulai terasa paling berat?",
    "Coba lakukan latihan napas perlahan...",
    "Saya siap mendengarkan cerita Anda dengan nyaman.",
    "Rekomendasi tindak lanjut sesi konseling",
  ];

  @override
  void initState() {
    super.initState();
    _scheduleTime = (widget.scheduleTime != null && widget.scheduleTime!.isNotEmpty)
        ? widget.scheduleTime!
        : 'Hari ini, 09:00 - 11:00';
    _initDoctorInfo();
    _fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollNewMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  DoctorChatSessionInfo _getChatSessionInfo() {
    final schedule = _scheduleTime;
    final now = DateTime.now();
    final lower = schedule.toLowerCase();

    // 1. Ekstrak jam mulai dan jam selesai
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

    // 2. Ekstrak tanggal
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
      final diff = startTime.difference(now);
      String diffText = '';
      if (diff.inDays > 0) {
        diffText = '${diff.inDays} hari lagi';
      } else if (diff.inHours > 0) {
        diffText = '${diff.inHours} jam ${diff.inMinutes % 60} mnt lagi';
      } else {
        diffText = '${diff.inMinutes} menit lagi';
      }

      return DoctorChatSessionInfo(
        status: DoctorChatSessionStatus.upcoming,
        title: 'Sesi Belum Dimulai',
        subtitle: 'Sesi dijadwalkan pada $schedule ($diffText). Fitur chat otomatis aktif saat jam sesi tiba.',
        badgeText: 'SEGERA HADIR',
        themeColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        icon: Icons.lock_clock_rounded,
      );
    } else if (now.isAfter(endTime)) {
      return DoctorChatSessionInfo(
        status: DoctorChatSessionStatus.expired,
        title: 'Sesi Telah Berakhir',
        subtitle: 'Konsultasi telah selesai pada $schedule. Obrolan digembok dan tersimpan sebagai arsip medis.',
        badgeText: 'SESI SELESAI',
        themeColor: const Color(0xFF64748B),
        bgColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        icon: Icons.lock_rounded,
      );
    } else {
      final remaining = endTime.difference(now);
      final remainingMins = remaining.inMinutes;
      return DoctorChatSessionInfo(
        status: DoctorChatSessionStatus.active,
        title: 'Sesi Sedang Berlangsung',
        subtitle: 'Sisa waktu konsultasi aktif: $remainingMins menit ($schedule).',
        badgeText: 'SESI AKTIF',
        themeColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFFCCFBF1).withValues(alpha: 0.5),
        borderColor: const Color(0xFF99F6E4),
        icon: Icons.chat_bubble_rounded,
      );
    }
  }

  void _initDoctorInfo() async {
    final name = await _storage.getNickname();
    if (name.isNotEmpty &&
        name != 'Sobat Hevenly' &&
        name != 'Sobat Havenly' &&
        name != 'Sobat MindPal') {
      setState(() => _doctorName = name);
    }
    if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
      _doctorId = widget.doctorId!;
    }
  }

  void _fetchMessages() async {
    final msgs = await _apiService.getDoctorChatMessages(
      widget.bookingId,
      doctorId: _doctorId,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _messages = List<Map<String, dynamic>>.from(msgs);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  bool _isPolling = false;

  void _pollNewMessages() async {
    if (!mounted || _isPolling) return;
    _isPolling = true;
    try {
      final msgs = await _apiService.getDoctorChatMessages(
        widget.bookingId,
        doctorId: _doctorId,
        userId: widget.userId,
      );
      if (!mounted) return;

      final pendingTemp = _messages.where((m) => (m['id']?.toString() ?? '').startsWith('temp_')).toList();
      final merged = List<Map<String, dynamic>>.from(msgs);
      for (final temp in pendingTemp) {
        final tempText = temp['message']?.toString() ?? '';
        final alreadyPresent = merged.any((m) =>
            m['message'] == tempText && m['sender_role'] == temp['sender_role']);
        if (!alreadyPresent) {
          merged.add(temp);
        }
      }

      bool hasChange = false;
      if (merged.length != _messages.length) {
        hasChange = true;
      } else {
        for (int i = 0; i < merged.length; i++) {
          if (merged[i]['id'] != _messages[i]['id'] ||
              merged[i]['message'] != _messages[i]['message']) {
            hasChange = true;
            break;
          }
        }
      }

      if (hasChange) {
        setState(() {
          _messages = merged;
        });
        _scrollToBottom();
      }
    } finally {
      _isPolling = false;
    }
  }

  void _sendMessage([String? promptText]) async {
    final sessionInfo = _getChatSessionInfo();
    if (sessionInfo.status != DoctorChatSessionStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sessionInfo.status == DoctorChatSessionStatus.upcoming
                ? 'Sesi belum dimulai. Pesan otomatis dapat dikirim saat jam sesi tiba.'
                : 'Sesi konsultasi telah berakhir. Pesan dinonaktifkan.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
      return;
    }

    final text = promptText ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _textController.clear();
    setState(() {
      _isSending = true;
      _messages.add({
        'id': tempId,
        'booking_id': widget.bookingId,
        'sender_id': _doctorId,
        'sender_name': _doctorName,
        'sender_role': 'doctor',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final result = await _apiService.sendDoctorMessage(
      bookingId: widget.bookingId,
      senderId: _doctorId,
      senderName: _doctorName,
      message: text,
      senderRole: 'doctor',
      doctorId: _doctorId,
      userId: widget.userId,
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (result != null && result['message'] != null) {
        final serverMsg = Map<String, dynamic>.from(result['message']);
        final idx = _messages.indexWhere((m) => m['id'] == tempId);
        if (idx != -1) {
          _messages[idx] = serverMsg;
        }
      }
    });
    await StorageService().saveDoctorChat(widget.bookingId, _messages, doctorId: _doctorId, userId: widget.userId);
    _scrollToBottom();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pesan gagal terkirim. Disimpan di cache lokal.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      final now = TimeOfDay.now();
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showCompleteSessionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          'Selesaikan Sesi Konsultasi?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Sesi konsultasi dengan ${widget.patientName} akan ditandai selesai dan rekap catatan akan disimpan.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // return completed = true
            },
            child: Text(
              'Tandai Selesai',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionInfo = _getChatSessionInfo();
    final bool isActive = sessionInfo.status == DoctorChatSessionStatus.active;

    final patientInitial = widget.patientName.isNotEmpty
        ? widget.patientName.trim()[0].toUpperCase()
        : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [sessionInfo.themeColor, sessionInfo.themeColor.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      patientInitial,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: sessionInfo.themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: sessionInfo.themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Pasien ${widget.patientAge ?? "Umum"} • ${sessionInfo.badgeText}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sessionInfo.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat Pre-Screening AI',
            icon: const Icon(Icons.psychology_rounded, color: Color(0xFF0D9488), size: 24),
            onPressed: () {
              AiScreeningModal.show(
                context,
                patientName: widget.patientName,
                screeningData: widget.aiScreening ?? {
                  'distress_score': 2,
                  'distress_level': 'Ringan',
                  'dominant_emotions': ['Stabil'],
                  'summary': 'Pasien ini belum memiliki catatan riwayat sesi curhat AI.',
                  'cbt_insights': 'Indikasi kondisi emosi dalam batas normal.',
                },
              );
            },
          ),
          if (isActive)
            IconButton(
              tooltip: 'Selesaikan Sesi',
              icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF0D9488), size: 23),
              onPressed: _showCompleteSessionDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
            tooltip: 'Perbarui Pesan',
            onPressed: _fetchMessages,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Jadwal Konsultasi Dinamis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sessionInfo.bgColor,
              border: Border(
                bottom: BorderSide(color: sessionInfo.borderColor, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(sessionInfo.icon, color: sessionInfo.themeColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sessionInfo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: sessionInfo.themeColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sessionInfo.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: sessionInfo.themeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sessionInfo.badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini Triage Bar Pre-Screening AI Pasien
          if (widget.aiScreening != null) ...[
            Builder(builder: (context) {
              final score = int.tryParse(widget.aiScreening!['distress_score']?.toString() ?? '4') ?? 4;
              final level = widget.aiScreening!['distress_level']?.toString() ?? (score <= 3 ? 'Ringan' : score <= 6 ? 'Sedang' : 'Berat');
              final color = score <= 3
                  ? const Color(0xFF10B981)
                  : score <= 6
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);

              return InkWell(
                onTap: () {
                  AiScreeningModal.show(
                    context,
                    patientName: widget.patientName,
                    screeningData: widget.aiScreening!,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insights_rounded, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Pre-Screening AI: Distress $score/10 ($level)",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        "Lihat Detail",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Catatan Keluhan Pasien Jika Ada
          if (widget.bookingNotes != null && widget.bookingNotes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan Pasien: "${widget.bookingNotes}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF92400E),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Area Obrolan
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0D9488),
                      strokeWidth: 2.5,
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 42,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada pesan dalam sesi ini.\nSapa pasien untuk memulai percakapan.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final bool isDoctor = msg['sender_role'] == 'doctor';
                          final String text = msg['message'] ?? msg['text'] ?? '';
                          final String time = _formatTime(msg['created_at']);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment:
                                  isDoctor ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isDoctor) ...[
                                  Container(
                                    width: 32,
                                    height: 32,
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
                                        patientInitial,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDoctor ? const Color(0xFFCCFBF1) : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isDoctor ? 18 : 4),
                                        bottomRight: Radius.circular(isDoctor ? 4 : 18),
                                      ),
                                      border: Border.all(
                                        color: isDoctor
                                            ? const Color(0xFF99F6E4)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          isDoctor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        if (!isDoctor)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text(
                                              widget.patientName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0D9488),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          text,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            height: 1.4,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (time.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            time,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: isDoctor
                                                  ? const Color(0xFF0F766E).withValues(alpha: 0.7)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Quick Doctor Prompt Chips (hanya aktif jika sesi sedang berjalan)
          if (isActive)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickDoctorChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final chip = _quickDoctorChips[idx];
                  return ActionChip(
                    label: Text(
                      chip,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF99F6E4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onPressed: () => _sendMessage(chip),
                  );
                },
              ),
            ),

          // Input Bar / Locked Warning Container
          if (!isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              decoration: BoxDecoration(
                color: sessionInfo.bgColor,
                border: Border(top: BorderSide(color: sessionInfo.borderColor, width: 1.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                sessionInfo.status == DoctorChatSessionStatus.upcoming
                                    ? 'Ruang Chat Belum Dimulai'
                                    : 'Sesi Konsultasi Telah Selesai',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: sessionInfo.themeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.lock_rounded, size: 14, color: sessionInfo.themeColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sessionInfo.status == DoctorChatSessionStatus.upcoming
                              ? 'Fitur kirim pesan dibuka saat jam sesi: $_scheduleTime'
                              : 'Waktu konsultasi telah selesai. Obrolan digembok sebagai arsip medis.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: sessionInfo.themeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded, color: sessionInfo.themeColor, size: 18),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: "Tulis pesan untuk ${widget.patientName}...",
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
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
                      child: const Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
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
