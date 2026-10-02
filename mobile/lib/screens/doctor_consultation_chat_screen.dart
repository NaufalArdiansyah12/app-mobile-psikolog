import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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

class DoctorConsultationChatScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> doctor;
  final String scheduleTime;

  const DoctorConsultationChatScreen({
    super.key,
    required this.bookingId,
    required this.doctor,
    required this.scheduleTime,
  });

  @override
  State<DoctorConsultationChatScreen> createState() => _DoctorConsultationChatScreenState();
}

class _DoctorConsultationChatScreenState extends State<DoctorConsultationChatScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String _userUuid = '';
  String _userName = 'Pasien';

  final List<String> _quickChips = [
    "Sering merasa cemas tiba-tiba",
    "Pikiran berisik & sulit tidur",
    "Burnout dengan rutinitas",
    "Mohon arahan latihan napas",
  ];

  @override
  void initState() {
    super.initState();
    _initChat();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollNewMessages();
      if (mounted) setState(() {});
    });
  }

  DoctorChatSessionInfo _getChatSessionInfo() {
    final schedule = widget.scheduleTime;
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
      // Cek format ISO YYYY-MM-DD
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
        subtitle: 'Konsultasi 2 jam telah selesai pada $schedule. Obrolan digembok dan tersimpan sebagai arsip.',
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

  void _initChat() async {
    final uuid = await _storage.getOrCreateUserUuid();
    final name = await _storage.getNickname();
    final msgs = await _apiService.getDoctorChatMessages(widget.bookingId);

    if (!mounted) return;
    setState(() {
      _userUuid = uuid;
      _userName = name.isNotEmpty ? name : 'Pasien';
      _messages = msgs;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _pollNewMessages() async {
    if (!mounted || _isSending) return;
    final msgs = await _apiService.getDoctorChatMessages(widget.bookingId);
    if (!mounted) return;
    if (msgs.length != _messages.length ||
        (msgs.isNotEmpty && _messages.isNotEmpty && msgs.last['id'] != _messages.last['id'])) {
      setState(() {
        _messages = msgs;
      });
      _scrollToBottom();
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

  void _sendMessage([String? prefilledText]) async {
    final sessionInfo = _getChatSessionInfo();
    if (sessionInfo.status != DoctorChatSessionStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sessionInfo.status == DoctorChatSessionStatus.upcoming
                ? 'Sesi belum dimulai. Pesan otomatis dapat dikirim saat jam sesi tiba.'
                : 'Sesi konsultasi telah berakhir. Pesan dinonaktifkan.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
      return;
    }

    final text = prefilledText ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() {
      _isSending = true;
      _messages.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'booking_id': widget.bookingId,
        'sender_id': _userUuid,
        'sender_name': _userName,
        'sender_role': 'user',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final result = await _apiService.sendDoctorMessage(
      bookingId: widget.bookingId,
      senderId: _userUuid,
      senderName: _userName,
      message: text,
      senderRole: 'user',
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan gagal dikirim. Periksa koneksi server.')),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docName = widget.doctor['name'] ?? 'dr. Spesialis';
    final docRole = widget.doctor['role'] ?? 'Psikiater Klinis';
    final sessionInfo = _getChatSessionInfo();
    final bool isActive = sessionInfo.status == DoctorChatSessionStatus.active;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                    color: sessionInfo.themeColor,
                  ),
                  child: const Center(
                    child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
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
                    docName,
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
                      Text(
                        '$docRole • ${sessionInfo.badgeText}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sessionInfo.themeColor,
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
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
            tooltip: 'Perbarui Pesan',
            onPressed: _initChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Jadwal Konsultasi Dinamis
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sessionInfo.bgColor,
              border: Border(
                bottom: BorderSide(color: sessionInfo.borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(sessionInfo.icon, color: sessionInfo.themeColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sessionInfo.title,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      letterSpacing: 0.5,
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
                              Icon(
                                isActive ? Icons.chat_bubble_outline_rounded : Icons.lock_outline_rounded,
                                size: 40,
                                color: const Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isActive
                                    ? 'Mulai obrolan dengan menyapa $docName.'
                                    : sessionInfo.status == DoctorChatSessionStatus.upcoming
                                        ? 'Ruang obrolan belum dimulai.\nAnda dapat mulai berkonsultasi pada jam sesi.'
                                        : 'Sesi konsultasi telah selesai.\nBelum ada riwayat pesan dalam sesi ini.',
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

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment:
                                  isDoctor ? MainAxisAlignment.start : MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isDoctor) ...[
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0D9488),
                                    ),
                                    child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDoctor ? Colors.white : const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isDoctor ? 4 : 18),
                                        bottomRight: Radius.circular(isDoctor ? 18 : 4),
                                      ),
                                      border: Border.all(
                                        color: isDoctor ? const Color(0xFFE2E8F0) : const Color(0xFF99F6E4),
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
                                          isDoctor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                      children: [
                                        if (isDoctor)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text(
                                              msg['sender_name'] ?? docName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0D9488),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          msg['message'] ?? '',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            height: 1.4,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
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

          // Quick Chips Keluhan (HANYA MUNCUL SAAT SESI AKTIF)
          if (isActive) ...[
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final chip = _quickChips[idx];
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
          ],

          // Input Bar / Locked Card Gembok
          if (isActive) ...[
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: "Tulis pesan ke ${docName.split(',').first}...",
                          hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0D9488),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tampilan Tergembok saat Sesi Belum Mulai atau Selesai
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              decoration: BoxDecoration(
                color: sessionInfo.bgColor,
                border: Border(top: BorderSide(color: sessionInfo.borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: sessionInfo.themeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: sessionInfo.borderColor),
                    ),
                    child: Icon(sessionInfo.icon, color: sessionInfo.themeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              sessionInfo.status == DoctorChatSessionStatus.upcoming
                                  ? 'Ruang Chat Digembok'
                                  : 'Ruang Chat Digembok',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: sessionInfo.themeColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.lock_rounded, size: 14, color: sessionInfo.themeColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sessionInfo.status == DoctorChatSessionStatus.upcoming
                              ? 'Fitur kirim pesan dibuka saat jam sesi: ${widget.scheduleTime}'
                              : 'Waktu konsultasi 2 jam telah selesai. Riwayat chat bersifat hanya-baca.',
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
                      color: const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
