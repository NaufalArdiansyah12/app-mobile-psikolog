import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class DoctorEditScheduleScreen extends StatefulWidget {
  const DoctorEditScheduleScreen({super.key});

  @override
  State<DoctorEditScheduleScreen> createState() => _DoctorEditScheduleScreenState();
}

class _DoctorEditScheduleScreenState extends State<DoctorEditScheduleScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _allDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  List<String> _selectedDays = [];
  List<String> _slots = [];

  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _expCtrl = TextEditingController();
  final TextEditingController _hospCtrl = TextEditingController();
  final TextEditingController _eduCtrl = TextEditingController();
  final TextEditingController _strCtrl = TextEditingController();

  static const Color primaryTeal = Color(0xFF006D77);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color softTealBg = Color(0xFFCCFBF1);

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _aboutCtrl.dispose();
    _expCtrl.dispose();
    _hospCtrl.dispose();
    _eduCtrl.dispose();
    _strCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    // 1. Ambil dari lokal
    var days = await _storage.getDoctorScheduleDays();
    var slots = await _storage.getDoctorScheduleSlots();
    var price = await _storage.getDoctorPrice();
    var about = await _storage.getDoctorAbout();
    var exp = await _storage.getDoctorExperience();
    var hosp = await _storage.getDoctorHospital();
    var edu = await _storage.getDoctorEducation();
    var str = await _storage.getDoctorStr();

    // 2. Coba sync dari DB Supabase
    try {
      final dbData = await _api.getDoctorDashboard();
      if (dbData != null) {
        if (dbData['available_days'] != null && (dbData['available_days'] as List).isNotEmpty) {
          days = List<String>.from(dbData['available_days']);
        }
        if (dbData['available_slots'] != null && (dbData['available_slots'] as List).isNotEmpty) {
          slots = List<String>.from(dbData['available_slots']);
        }
        if (dbData['price'] != null && dbData['price'].toString().isNotEmpty) {
          price = dbData['price'].toString();
        }
        if (dbData['bio'] != null && dbData['bio'].toString().isNotEmpty) {
          about = dbData['bio'].toString();
        }
        if (dbData['experience'] != null && dbData['experience'].toString().isNotEmpty) {
          exp = dbData['experience'].toString();
        }
        if (dbData['hospital'] != null && dbData['hospital'].toString().isNotEmpty) {
          hosp = dbData['hospital'].toString();
        }
        if (dbData['education'] != null && dbData['education'].toString().isNotEmpty) {
          edu = dbData['education'].toString();
        }
        if (dbData['str_number'] != null && dbData['str_number'].toString().isNotEmpty) {
          str = dbData['str_number'].toString();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _selectedDays = List<String>.from(days);
        _slots = List<String>.from(slots);
        _priceCtrl.text = price;
        _aboutCtrl.text = about;
        _expCtrl.text = exp;
        _hospCtrl.text = hosp;
        _eduCtrl.text = edu;
        _strCtrl.text = str;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedDays.isEmpty) {
      _showSnackbar('Pilih minimal satu hari praktik aktif');
      return;
    }
    if (_slots.isEmpty) {
      _showSnackbar('Tambahkan minimal satu slot jam sesi');
      return;
    }

    setState(() => _isSaving = true);

    final finalPrice = _priceCtrl.text.trim();
    final finalAbout = _aboutCtrl.text.trim();
    final finalExp = _expCtrl.text.trim();
    final finalHosp = _hospCtrl.text.trim();
    final finalEdu = _eduCtrl.text.trim();
    final finalStr = _strCtrl.text.trim();

    // 1. Simpan ke local cache
    await _storage.setDoctorScheduleDays(_selectedDays);
    await _storage.setDoctorScheduleSlots(_slots);
    await _storage.setDoctorPrice(finalPrice);
    await _storage.setDoctorAbout(finalAbout);
    await _storage.setDoctorExperience(finalExp);
    await _storage.setDoctorHospital(finalHosp);
    await _storage.setDoctorEducation(finalEdu);
    await _storage.setDoctorStr(finalStr);

    // 2. Kirim update ke Database Supabase
    final successDb = await _api.updateDoctorFullProfile(
      price: finalPrice,
      experience: finalExp,
      hospital: finalHosp,
      education: finalEdu,
      strNumber: finalStr,
      bio: finalAbout,
      availableDays: _selectedDays,
      availableSlots: _slots,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    _showSnackbar(successDb
        ? 'Perubahan berhasil tersimpan di Database Supabase!'
        : 'Tersimpan lokal & disinkronkan saat online.');
    Navigator.pop(context, true);
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        backgroundColor: primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _applyDayPreset(List<String> preset) {
    setState(() {
      _selectedDays = List<String>.from(preset);
    });
  }

  Future<void> _addNewTimeSlot() async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'PILIH JAM MULAI SESI',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (startTime == null || !mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute),
      helpText: 'PILIH JAM SELESAI SESI',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (endTime == null || !mounted) return;

    final formatTime = (TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final slotString = '${formatTime(startTime)} - ${formatTime(endTime)}';

    if (_slots.contains(slotString)) {
      _showSnackbar('Slot jam ini sudah ada di daftar');
      return;
    }

    setState(() {
      _slots.add(slotString);
      _slots.sort();
    });
  }

  void _removeSlot(int index) {
    setState(() {
      _slots.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Praktik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Jadwal, sesi jam, tarif & profil dokter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // White Rounded Bottom Card Body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
                        children: [
                          // 1. Hari Praktik Aktif
                          _buildSectionCard(
                            icon: Icons.calendar_month_rounded,
                            iconColor: primaryTeal,
                            iconBg: softTealBg,
                            title: 'Hari Praktik Aktif',
                            subtitle: 'Tentukan hari ketika Anda siap melayani pasien',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Presets Buttons
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildPresetChip('Senin – Kamis', ['Senin', 'Selasa', 'Rabu', 'Kamis']),
                                      const SizedBox(width: 6),
                                      _buildPresetChip('Senin – Jumat', ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat']),
                                      const SizedBox(width: 6),
                                      _buildPresetChip('Semua Hari', _allDays),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Day Chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _allDays.map((day) {
                                    final isSelected = _selectedDays.contains(day);
                                    return FilterChip(
                                      selected: isSelected,
                                      showCheckmark: false,
                                      avatar: isSelected
                                          ? const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)
                                          : null,
                                      label: Text(
                                        day,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? Colors.white : AppColors.dark,
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      selectedColor: primaryTeal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected ? primaryTeal : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      onSelected: (_) => _toggleDay(day),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2. Slot Jam Sesi
                          _buildSectionCard(
                            icon: Icons.access_time_filled_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            title: 'Slot Waktu Sesi Konsultasi',
                            subtitle: 'Pilihan jam mulai & berakhir per sesi janji temu',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_slots.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Belum ada slot jam yang ditambahkan',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: const Color(0xFFB91C1C),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(_slots.length, (index) {
                                      final slot = _slots[index];
                                      return Container(
                                        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDFA),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF99F6E4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.schedule_rounded, size: 14, color: primaryTeal),
                                            const SizedBox(width: 6),
                                            Text(
                                              slot,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.dark,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            InkWell(
                                              onTap: () => _removeSlot(index),
                                              borderRadius: BorderRadius.circular(10),
                                              child: const Padding(
                                                padding: EdgeInsets.all(2.0),
                                                child: Icon(Icons.close_rounded, size: 15, color: Color(0xFF94A3B8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryTeal,
                                    side: const BorderSide(color: primaryTeal),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                  label: Text(
                                    'Tambah Slot Jam Baru',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: _addNewTimeSlot,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. Biaya Konseling
                          _buildSectionCard(
                            icon: Icons.monetization_on_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFECFDF5),
                            title: 'Tarif & Biaya Konseling',
                            subtitle: 'Nominal harga per 1 sesi konsultasi pasien',
                            child: _buildFormField(
                              controller: _priceCtrl,
                              hintText: 'Contoh: Rp 250.000',
                              prefixIcon: Icons.payments_outlined,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 4. Tentang Dokter (Bio & Pendekatan Terapi)
                          _buildSectionCard(
                            icon: Icons.psychology_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF5F3FF),
                            title: 'Tentang Dokter (About)',
                            subtitle: 'Penjelasan spesialisasi, modalitas terapi & pendekatan klinis',
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: _aboutCtrl,
                                maxLines: 4,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.dark),
                                decoration: InputDecoration(
                                  hintText: 'Tuliskan bio, fokus keluhan (CBT, trauma, mood disorder)...',
                                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 5. Pengalaman Klinis & Kredensial
                          _buildSectionCard(
                            icon: Icons.verified_user_rounded,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFFFBEB),
                            title: 'Pengalaman & Kredensial',
                            subtitle: 'Pengalaman kerja, riwayat instansi, pendidikan & STR',
                            child: Column(
                              children: [
                                _buildFormField(
                                  controller: _expCtrl,
                                  hintText: 'Pengalaman Praktik (contoh: 8 Tahun)',
                                  prefixIcon: Icons.work_history_outlined,
                                ),
                                const SizedBox(height: 10),
                                _buildFormField(
                                  controller: _hospCtrl,
                                  hintText: 'Rumah Sakit / Klinik Praktik',
                                  prefixIcon: Icons.local_hospital_outlined,
                                ),
                                const SizedBox(height: 10),
                                _buildFormField(
                                  controller: _eduCtrl,
                                  hintText: 'Pendidikan (contoh: Spesialis Jiwa FK UI)',
                                  prefixIcon: Icons.school_outlined,
                                ),
                                const SizedBox(height: 10),
                                _buildFormField(
                                  controller: _strCtrl,
                                  hintText: 'Nomor STR / SIP Aktif',
                                  prefixIcon: Icons.badge_outlined,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Simpan Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                              onPressed: _isSaving ? null : _saveSettings,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'Simpan Pengaturan Praktik',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, List<String> presetDays) {
    final isMatching = _selectedDays.length == presetDays.length &&
        presetDays.every((d) => _selectedDays.contains(d));

    return InkWell(
      onTap: () => _applyDayPreset(presetDays),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isMatching ? primaryTeal.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMatching ? primaryTeal : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isMatching ? FontWeight.w800 : FontWeight.w600,
            color: isMatching ? primaryTeal : AppColors.slate,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
          prefixIcon: Icon(prefixIcon, color: primaryTeal, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
