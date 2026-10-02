import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class DoctorChatScreen extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final String? patientAge;
  final String? bookingNotes;

  const DoctorChatScreen({
    super.key,
    this.bookingId = 'bk_doc_1',
    required this.patientName,
    this.patientAge,
    this.bookingNotes,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollNewMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchMessages() async {
    final msgs = await _apiService.getDoctorChatMessages(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _messages = List<Map<String, dynamic>>.from(msgs);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _pollNewMessages() async {
    if (!mounted || _isSending) return;
    final msgs = await _apiService.getDoctorChatMessages(widget.bookingId);
    if (!mounted || _isSending) return;

    if (msgs.length != _messages.length ||
        (msgs.isNotEmpty && _messages.isNotEmpty && msgs.last['id'] != _messages.last['id'])) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(msgs);
      });
      _scrollToBottom();
    }
  }

  void _sendMessage([String? promptText]) async {
    final text = promptText ?? _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    _textController.clear();
    setState(() {
      _isSending = true;
      _messages.add({
        'id': tempId,
        'booking_id': widget.bookingId,
        'sender_id': 'psy_1',
        'sender_name': 'dr. Nadia S., Sp.KJ',
        'sender_role': 'doctor',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    final result = await _apiService.sendDoctorMessage(
      bookingId: widget.bookingId,
      senderId: 'psy_1',
      senderName: 'dr. Nadia S., Sp.KJ',
      message: text,
      senderRole: 'doctor',
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
    await StorageService().saveDoctorChat(widget.bookingId, _messages);
    _scrollToBottom();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan gagal dikirim. Periksa koneksi server.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 40,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Selesaikan Sesi Konsultasi?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Sesi konsultasi dengan ${widget.patientName} akan ditandai selesai dan rekap catatan akan disimpan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // return completed = true
            },
            child: Text('Selesaikan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'P',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Pasien ${widget.patientAge ?? "Umum"} • Sesi Berlangsung',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Selesaikan Konsultasi',
            icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
            onPressed: _showCompleteSessionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Info Pasien
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF0FDFA),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesi konsultasi medis terenkripsi & tersinkronisasi real-time.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Catatan Keluhan Pasien Jika Ada
          if (widget.bookingNotes != null && widget.bookingNotes!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan Keluhan Pasien: "${widget.bookingNotes}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Daftar Pesan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada pesan. Sapa pasien untuk memulai sesi.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final bool isDoctor = msg['sender_role'] == 'doctor';
                          final String text = msg['message'] ?? msg['text'] ?? '';
                          final String time = _formatTime(msg['created_at']);

                          return Align(
                            alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: isDoctor ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isDoctor ? 16 : 4),
                                  bottomRight: Radius.circular(isDoctor ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isDoctor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isDoctor)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2.0),
                                      child: Text(
                                        widget.patientName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    text,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: isDoctor ? Colors.white : AppColors.dark,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (time.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      time,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: isDoctor ? Colors.white.withOpacity(0.7) : AppColors.mutedLight,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Quick Doctor Prompts
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickChip('Bisa ceritakan apa pemicunya?'),
                _buildQuickChip('Kapan keluhan ini mulai dirasa?'),
                _buildQuickChip('Coba tarik napas perlahan...'),
                _buildQuickChip('Rekomendasi tindak lanjut terapi'),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan untuk pasien...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.mutedLight, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.cardAquaBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.primaryDark),
        ),
        onPressed: () {
          _sendMessage(text);
        },
      ),
    );
  }
}
