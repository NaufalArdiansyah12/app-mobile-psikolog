import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_bubble_widget.dart';
import 'chat_screen.dart';

class ChatSessionDetailScreen extends StatefulWidget {
  final ChatSession session;
  final VoidCallback? onDelete;

  const ChatSessionDetailScreen({
    super.key,
    required this.session,
    this.onDelete,
  });

  @override
  State<ChatSessionDetailScreen> createState() => _ChatSessionDetailScreenState();
}

class _ChatSessionDetailScreenState extends State<ChatSessionDetailScreen> {
  final StorageService _storage = StorageService();
  late ChatSession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  void _loadLatestSession() async {
    final sessions = await _storage.getChatSessions();
    final updated = sessions.firstWhere(
      (s) => s.id == _session.id,
      orElse: () => _session,
    );
    if (mounted) {
      setState(() {
        _session = updated;
      });
    }
  }

  void _continueChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialSession: _session),
      ),
    );
    _loadLatestSession();
  }

  Color _getDistressColor(int score) {
    if (score <= 3) return const Color(0xFF10B981); // Emerald / Hijau
    if (score <= 6) return const Color(0xFFF59E0B); // Amber / Kuning
    return const Color(0xFFEF4444); // Red / Merah
  }

  String _getDistressBadge(int score) {
    if (score <= 3) return "Tingkat Rendah (Terkendali)";
    if (score <= 6) return "Tingkat Sedang (Perlu Perhatian)";
    return "Tingkat Tinggi (Waspada / Butuh Reda)";
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _session.analysis;
    final distressScore = analysis?.distressScore ?? 4;
    final distressColor = _getDistressColor(distressScore);

    const Color primaryTeal = Color(0xFF006D77);

    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HEADER (Hijau Aqua / Deep Teal)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Statistik & Evaluasi Sesi",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFECDD3), size: 22),
                      tooltip: "Hapus Sesi",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text(
                              "Hapus Sesi Ini?",
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                            ),
                            content: Text(
                              "Riwayat obrolan dan analisis ini akan dihapus permanen.",
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                  widget.onDelete!();
                                },
                                child: Text("Hapus", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
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
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                  children: [
                    // 1. STATISTIK KEPARAHAN (METER CARD)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: distressColor.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: distressColor.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: distressColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.analytics_rounded, size: 14, color: distressColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          "SKOR DISTRESS / BEBAN",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: distressColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${_session.createdAt.day}/${_session.createdAt.month}/${_session.createdAt.year} ${_session.createdAt.hour.toString().padLeft(2, '0')}:${_session.createdAt.minute.toString().padLeft(2, '0')}",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "$distressScore",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: distressColor,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                " / 10",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: distressColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: distressColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  analysis?.distressLevel ?? "Normal",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: distressColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Linear Meter
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (distressScore / 10).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(distressColor),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getDistressBadge(distressScore),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),

                          if (distressScore >= 7) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: BreathingBubbleWidget(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFECDD3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.air_rounded, color: Color(0xFFE11D48), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Beban terasa berat? Coba Latihan Napas sekarang",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFBE185D),
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFBE185D), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. EMOSI & DISTORSI KOGNITIF
                    if (analysis != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology_rounded, color: Color(0xFF0D9488), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Emosi & Pola Pikir Terdeteksi",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (analysis.dominantEmotions.isNotEmpty) ...[
                              Text(
                                "Emosi Dominan:",
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: analysis.dominantEmotions.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF99F6E4)),
                                    ),
                                    child: Text(
                                      "#$e",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F766E),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (analysis.cognitiveDistortions.isNotEmpty) ...[
                              Text(
                                "Distorsi Kognitif (Pola Overthinking):",
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: analysis.cognitiveDistortions.map((d) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Text(
                                      "⚡ $d",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. RINGKASAN & INSIGHT CBT
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Analisis & Wawasan CBT",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Ringkasan Masalah:",
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysis.summary.isNotEmpty ? analysis.summary : "Percakapan curhat santai dengan Hevenly.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.45,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Sudut Pandang Terapi (CBT):",
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                analysis.cbtInsights.isNotEmpty
                                    ? analysis.cbtInsights
                                    : "Fokuslah memisahkan fakta objektif dari kekhawatiran pikiran.",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. ACTION RECOMMENDATIONS
                      if (analysis.actionRecommendations.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Langkah Tindakan Mandiri",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...analysis.actionRecommendations.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 3),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF10B981)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${entry.key + 1}",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            color: const Color(0xFF334155),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // 5. TRANSKRIP CHAT LENGKAP (ACCORDION / PREVIEW)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.forum_outlined, color: Color(0xFF64748B), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Transkrip Obrolan",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${_session.messages.length} pesan",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._session.messages.map((m) {
                            final isUser = m.role == 'user';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUser ? const Color(0xFFCCFBF1) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUser ? "Kamu" : "Hevenly AI",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isUser ? const Color(0xFF0D9488) : const Color(0xFF7E22CE),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m.content,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF334155),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          MediaQuery.of(context).padding.bottom > 0 ? (MediaQuery.of(context).padding.bottom + 6) : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
          label: Text(
            "Lanjutkan Percakapan dengan AI",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: _continueChat,
        ),
      ),
    );
  }
}
