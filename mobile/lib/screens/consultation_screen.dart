import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  String _userUuid = '';
  List<Map<String, dynamic>> _therapists = [];

  final List<String> _categories = [
    'Semua',
    'Kecemasan & Stres',
    'Trauma & Depresi',
    'Hubungan & Asmara',
    'Karir & Burnout',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    final uuid = await _storage.getOrCreateUserUuid();
    final docs = await _apiService.getPsychologists();
    if (!mounted) return;
    setState(() {
      _userUuid = uuid;
      _therapists = docs.isNotEmpty ? docs : _defaultTherapists;
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

  void _showBookingSheet(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              doctor['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              doctor['role'] ?? '',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tarif Sesi (50 Menit)", style: TextStyle(fontSize: 14)),
                Text(
                  doctor['price'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Jadwal Terdekat", style: TextStyle(fontSize: 14)),
                Text(
                  doctor['available'] ?? 'Hari ini, 19:00',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _apiService.createBooking(
                    userUuid: _userUuid,
                    psychologistId: doctor['id']?.toString() ?? 'psy_1',
                    scheduleTime: doctor['available'] ?? 'Hari ini, 19:00',
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Jadwal sesi bersama ${doctor['name']} berhasil dikonfirmasi!"),
                        backgroundColor: const Color(0xFF0D9488),
                      ),
                    );
                  }
                },
                child: const Text("Konfirmasi & Booking Sesi", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'Semua'
        ? _therapists
        : _therapists.where((t) => t['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Konsultasi Ahli", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : Column(
              children: [
                // Filter Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFCCFBF1),
                          checkmarkColor: const Color(0xFF0D9488),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Directory List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Color(0xFFCCFBF1),
                                    child: Icon(Icons.person, color: Color(0xFF0D9488), size: 30),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          doc['role'] ?? '',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${doc['rating']} (${doc['experience']})",
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "• ${doc['hospital']}",
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Tarif Sesi", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      Text(
                                        doc['price'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    onPressed: () => _showBookingSheet(doc),
                                    child: const Text("Jadwalkan", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
