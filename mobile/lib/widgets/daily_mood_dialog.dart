import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class DailyMoodDialog extends StatefulWidget {
  const DailyMoodDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final storage = StorageService();
    final alreadyCheckedIn = await storage.hasCheckedInToday();
    if (alreadyCheckedIn || !context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DailyMoodDialog(),
    );
  }

  @override
  State<DailyMoodDialog> createState() => _DailyMoodDialogState();
}

class _DailyMoodDialogState extends State<DailyMoodDialog> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();

  int _selectedScore = 3;
  final List<String> _selectedTriggers = [];
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _moodLevels = [
    {
      'score': 1,
      'emoji': '😢',
      'label': 'Sangat Buruk',
      'color': const Color(0xFFF87171),
    },
    {
      'score': 2,
      'emoji': '😟',
      'label': 'Buruk',
      'color': const Color(0xFF38BDF8),
    },
    {
      'score': 3,
      'emoji': '😐',
      'label': 'Netral',
      'color': const Color(0xFFFFA69E),
    },
    {
      'score': 4,
      'emoji': '🙂',
      'label': 'Baik',
      'color': const Color(0xFFFFD166),
    },
    {
      'score': 5,
      'emoji': '😄',
      'label': 'Sangat Baik',
      'color': const Color(0xFF4ADE80),
    },
  ];

  final List<String> _triggerOptions = [
    'Pekerjaan',
    'Perkuliahan',
    'Finansial',
    'Asmara',
    'Keluarga',
    'Kesehatan',
    'Kurang Tidur',
    'Cuaca',
  ];

  void _saveMood() async {
    final activeMood = _moodLevels.firstWhere((m) => m['score'] == _selectedScore);
    final entry = MoodEntry(
      id: const Uuid().v4(),
      score: _selectedScore,
      label: activeMood['label'],
      triggers: List.from(_selectedTriggers),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await _storage.saveMood(entry);
    await _storage.markCheckinToday();

    final uuid = await _storage.getOrCreateUserUuid();
    _apiService.syncMood(entry, uuid);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Terima kasih telah berbagi perasaanmu hari ini!",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _skip() async {
    await _storage.markCheckinToday();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo Sobat!",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Bagaimana perasaanmu hari ini?",
                        style: GoogleFonts.newsreader(
                          fontSize: 19,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                  onPressed: _skip,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 5 Mood Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moodLevels.map((m) {
                final isSelected = _selectedScore == m['score'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedScore = m['score']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(m['emoji'], style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            m['label'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF065F46) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),
            Text(
              "Apa yang memengaruhimu?",
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _triggerOptions.map((tag) {
                final isSelected = _selectedTriggers.contains(tag);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTriggers.remove(tag);
                      } else {
                        _selectedTriggers.add(tag);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: "Tulis sepatah kata (opsional)...",
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0D9488)),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      "Nanti Saja",
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _saveMood,
                    child: Text(
                      "Simpan Mood",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
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
