import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiScreeningModal extends StatelessWidget {
  final String patientName;
  final Map<String, dynamic> screeningData;

  const AiScreeningModal({
    super.key,
    required this.patientName,
    required this.screeningData,
  });

  static void show(BuildContext context, {required String patientName, required Map<String, dynamic> screeningData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiScreeningModal(
        patientName: patientName,
        screeningData: screeningData,
      ),
    );
  }

  Color _getDistressColor(int score) {
    if (score <= 3) return const Color(0xFF10B981); // Hijau (Normal/Ringan)
    if (score <= 6) return const Color(0xFFF59E0B); // Kuning/Oranye (Sedang)
    return const Color(0xFFEF4444); // Merah (Tinggi/Waspada)
  }

  String _getDistressBadge(int score) {
    if (score <= 3) return "Tingkat Rendah / Ringan (Terkendali)";
    if (score <= 6) return "Tingkat Sedang (Perlu Pendampingan)";
    return "Tingkat Tinggi (Prioritas Intervensi)";
  }

  @override
  Widget build(BuildContext context) {
    final int score = int.tryParse(screeningData['distress_score']?.toString() ?? '4') ?? 4;
    final String level = screeningData['distress_level']?.toString() ?? (score <= 3 ? 'Ringan' : score <= 6 ? 'Sedang' : 'Berat');
    final String summary = screeningData['summary']?.toString() ?? 'Percakapan curhat santai bersama AI MindPal.';
    final String cbtInsights = screeningData['cbt_insights']?.toString() ?? 'Tidak ditemukan indikasi distorsi kognitif akut.';
    
    final emotionsRaw = screeningData['dominant_emotions'];
    final List<String> emotions = (emotionsRaw is List)
        ? emotionsRaw.map((e) => e.toString()).toList()
        : [];

    final distortionsRaw = screeningData['cognitive_distortions'];
    final List<String> distortions = (distortionsRaw is List)
        ? distortionsRaw.map((d) => d.toString()).toList()
        : [];

    final actionsRaw = screeningData['action_recommendations'];
    final List<String> actions = (actionsRaw is List)
        ? actionsRaw.map((a) => a.toString()).toList()
        : [];

    final themeColor = _getDistressColor(score);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_rounded, color: themeColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pre-Screening AI Pasien",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          patientName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Skor Distress Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tingkat Keparahan (Distress Score)",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                "$level ($score/10)",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (score / 10).clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDistressBadge(score),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Emosi Dominan
                  if (emotions.isNotEmpty) ...[
                    Text(
                      "Emosi yang Terdeteksi",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emotions.map((emo) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFF0D9488)),
                              const SizedBox(width: 5),
                              Text(
                                emo,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. Distorsi Kognitif (Jika ada)
                  if (distortions.isNotEmpty) ...[
                    Text(
                      "Pola Pikir / Distorsi Kognitif",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: distortions.map((dist) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                dist,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 4. Ringkasan Obrolan Chat AI
                  Text(
                    "Ringkasan Sesi AI Terakhir",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      summary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. CBT Insights
                  Text(
                    "Insight CBT (Akar Masalah)",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text(
                      cbtInsights,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF0F766E),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 6. Action Recommendations (Jika ada)
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      "Rekomendasi Latihan Pasien",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...actions.map((act) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 8),
                                child: Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0D9488)),
                              ),
                              Expanded(
                                child: Text(
                                  act,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
