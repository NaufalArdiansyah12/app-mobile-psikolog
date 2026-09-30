import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();
  int _selectedScore = 3;
  final List<String> _selectedTriggers = [];
  final TextEditingController _notesController = TextEditingController();
  List<MoodEntry> _history = [];

  final List<Map<String, dynamic>> _moodLevels = [
    {'score': 1, 'emoji': '😢', 'label': 'Sangat Buruk'},
    {'score': 2, 'emoji': '😟', 'label': 'Buruk'},
    {'score': 3, 'emoji': '😐', 'label': 'Netral'},
    {'score': 4, 'emoji': '🙂', 'label': 'Baik'},
    {'score': 5, 'emoji': '😄', 'label': 'Sangat Baik'},
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

  @override
  void initState() {
    super.initState();
    _loadMoods();
  }

  void _loadMoods() async {
    final list = await _storage.getMoods();
    setState(() {
      _history = list.reversed.toList();
    });
  }

  void _saveCurrentMood() async {
    final activeMood = _moodLevels.firstWhere((m) => m['score'] == _selectedScore);
    final entry = MoodEntry(
      id: const Uuid().v4(),
      score: _selectedScore,
      label: activeMood['label'],
      triggers: List.from(_selectedTriggers),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await _storage.saveMood(entry);
    final uuid = await _storage.getOrCreateUserUuid();
    _apiService.syncMood(entry, uuid); // Sync async ke Supabase backend

    _notesController.clear();
    setState(() => _selectedTriggers.clear());
    _loadMoods();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan mood berhasil disimpan!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jurnal Emosi & Mood", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card Input Mood
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bagaimana perasaanmu sekarang?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _moodLevels.map((m) {
                      final isSelected = _selectedScore == m['score'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedScore = m['score']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal.shade50 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.teal : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(m['emoji'], style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                m['label'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.teal : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Faktor Pemicu (Trigger):", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _triggerOptions.map((tag) {
                      final isSelected = _selectedTriggers.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTriggers.add(tag);
                            } else {
                              _selectedTriggers.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Catatan singkat (opsional)...",
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saveCurrentMood,
                      child: const Text("Simpan Mood"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Riwayat Catatan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text("Belum ada catatan mood.", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._history.map((m) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      _moodLevels.firstWhere((lvl) => lvl['score'] == m.score)['emoji'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.triggers.isNotEmpty)
                        Text(
                          "Pemicu: ${m.triggers.join(', ')}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      if (m.notes != null)
                        Text(
                          m.notes!,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  trailing: Text(
                    "${m.timestamp.day}/${m.timestamp.month} ${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
