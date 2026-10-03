import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth_screen.dart';
import 'doctor_edit_schedule_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  String _doctorName = 'dr. Nadia S., Sp.KJ';
  String _doctorEmail = 'dokter@mindpal.id';
  String _specialization = 'Psikiater Klinis';
  String _experience = '8 Tahun';
  String _hospital = 'RS Mitra Sehat Jakarta';
  String _price = 'Rp 250.000 / sesi';
  String _avatarType = 'asset:assets/gambar_home.jpeg';
  String _education = 'Spesialis Kedokteran Jiwa - FK UI';
  String _str = 'STR: 31.1.2.100.3.19.112233';
  String _about = '';
  List<String> _days = [];
  List<String> _slots = [];

  static const Color primaryTeal = Color(0xFF006D77);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color softTealBg = Color(0xFFCCFBF1);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await _storage.getNickname();
    final email = await _storage.getUserEmail();
    final avatar = await _storage.getUserAvatar();

    final savedDays = await _storage.getDoctorScheduleDays();
    final savedSlots = await _storage.getDoctorScheduleSlots();
    final savedPrice = await _storage.getDoctorPrice();
    final savedAbout = await _storage.getDoctorAbout();
    final savedExp = await _storage.getDoctorExperience();
    final savedHosp = await _storage.getDoctorHospital();
    final savedEdu = await _storage.getDoctorEducation();
    final savedStr = await _storage.getDoctorStr();

    final dashboard = await _api.getDoctorDashboard();

    var days = savedDays;
    var slots = savedSlots;
    var price = savedPrice.contains('/ sesi') ? savedPrice : '$savedPrice / sesi';
    var about = savedAbout;
    var exp = savedExp;
    var hosp = savedHosp;
    var edu = savedEdu;
    var str = savedStr;

    if (dashboard != null) {
      if (dashboard['available_days'] != null && (dashboard['available_days'] as List).isNotEmpty) {
        days = List<String>.from(dashboard['available_days']);
      }
      if (dashboard['available_slots'] != null && (dashboard['available_slots'] as List).isNotEmpty) {
        slots = List<String>.from(dashboard['available_slots']);
      }
      if (dashboard['price'] != null && dashboard['price'].toString().isNotEmpty) {
        final p = dashboard['price'].toString();
        price = p.contains('/ sesi') ? p : '$p / sesi';
      }
      if (dashboard['bio'] != null && dashboard['bio'].toString().isNotEmpty) {
        about = dashboard['bio'].toString();
      }
      if (dashboard['experience'] != null && dashboard['experience'].toString().isNotEmpty) {
        exp = dashboard['experience'].toString();
      }
      if (dashboard['hospital'] != null && dashboard['hospital'].toString().isNotEmpty) {
        hosp = dashboard['hospital'].toString();
      }
      if (dashboard['education'] != null && dashboard['education'].toString().isNotEmpty) {
        edu = dashboard['education'].toString();
      }
      if (dashboard['str_number'] != null && dashboard['str_number'].toString().isNotEmpty) {
        str = dashboard['str_number'].toString();
      }
    }

    if (mounted) {
      setState(() {
        if (name.isNotEmpty && name != 'Sobat Hevenly' && name != 'Sobat Havenly' && name != 'Sobat MindPal') _doctorName = name;
        if (email != null && email.isNotEmpty) _doctorEmail = email;
        if (avatar != null && avatar.isNotEmpty) _avatarType = avatar;

        _days = days;
        _slots = slots;
        _price = price;
        _about = about;
        _experience = exp;
        _hospital = hosp;
        _education = edu;
        _str = str;

        if (dashboard != null) {
          _doctorName = dashboard['name'] ?? _doctorName;
          _specialization = dashboard['specialization'] ?? _specialization;
        }
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // MODAL EDIT PROFIL DOKTER
  void _openEditProfileModal() {
    final nameCtrl = TextEditingController(text: _doctorName);
    final specCtrl = TextEditingController(text: _specialization);
    String selectedAvatar = _avatarType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          Future<void> pickImage(ImageSource source) async {
            try {
              final picked = await _imagePicker.pickImage(
                source: source,
                maxWidth: 720,
                maxHeight: 720,
                imageQuality: 85,
              );
              if (picked != null) {
                setModalState(() {
                  selectedAvatar = 'file:${picked.path}';
                });
              }
            } catch (e) {
              if (mounted) _showSnackBar('Gagal mengambil foto: $e');
            }
          }

          Widget buildModalAvatarPreview() {
            if (selectedAvatar.startsWith('file:')) {
              final path = selectedAvatar.replaceFirst('file:', '');
              return ClipOval(
                child: Image.file(File(path), fit: BoxFit.cover),
              );
            } else if (selectedAvatar.startsWith('asset:')) {
              final path = selectedAvatar.replaceFirst('asset:', '');
              return ClipOval(
                child: Image.asset(path, fit: BoxFit.cover),
              );
            } else {
              final emoji = selectedAvatar.replaceFirst('emoji:', '');
              return Center(child: Text(emoji, style: const TextStyle(fontSize: 34)));
            }
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              top: 14,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: softTealBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.edit_outlined, color: primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profil Dokter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Ubah nama tampilan dan foto profil praktik',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar Picker Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryTeal, width: 2),
                          ),
                          child: buildModalAvatarPreview(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTeal,
                                side: const BorderSide(color: primaryTeal),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.photo_library_rounded, size: 16),
                              label: Text('Galeri', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => pickImage(ImageSource.gallery),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTeal,
                                side: const BorderSide(color: primaryTeal),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.camera_alt_outlined, size: 16),
                              label: Text('Kamera', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => pickImage(ImageSource.camera),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildInputLabel('NAMA DOKTER LENGKAP'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: nameCtrl,
                    hintText: 'dr. Nama Lengkap, Sp.KJ',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),

                  _buildInputLabel('SPESIALISASI / PERAN'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: specCtrl,
                    hintText: 'Contoh: Psikiater Klinis Dewasa',
                    prefixIcon: Icons.medical_services_outlined,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        final newSpec = specCtrl.text.trim();
                        if (newName.isNotEmpty) {
                          await _storage.setNickname(newName);
                        }
                        if (selectedAvatar.isNotEmpty) {
                          await _storage.setUserAvatar(selectedAvatar);
                        }
                        setState(() {
                          if (newName.isNotEmpty) _doctorName = newName;
                          if (newSpec.isNotEmpty) _specialization = newSpec;
                          _avatarType = selectedAvatar;
                        });
                        if (modalCtx.mounted) Navigator.pop(modalCtx);
                        _showSnackBar('Profil dokter berhasil diperbarui');
                      },
                      child: Text('Simpan Perubahan', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MODAL DETAIL KREDENSIAL DOKTER
  void _openCredentialsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kredensial & Izin Praktik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Informasi legalitas dan fasilitas kesehatan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.badge_outlined, 'Nomor STR / SIP', _str),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildDetailRow(Icons.school_outlined, 'Riwayat Pendidikan', _education),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildDetailRow(Icons.local_hospital_outlined, 'Fasilitas Praktik', _hospital),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildDetailRow(Icons.work_history_outlined, 'Pengalaman', _experience),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildDetailRow(Icons.payments_outlined, 'Tarif Konsultasi', _price),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MODAL LOGOUT
  void _openLogoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),

            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: softTealBg,
              ),
              child: const Center(
                child: Icon(Icons.logout_rounded, color: primaryTeal, size: 30),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Keluar dari Akun Dokter?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Anda perlu masuk kembali untuk menerima konsultasi baru dan mengelola antrean pasien.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _storage.logout();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    },
                    child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPERS
  Widget _buildAvatarWidget() {
    if (_avatarType.startsWith('file:')) {
      final path = _avatarType.replaceFirst('file:', '');
      return ClipOval(
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.medical_services_rounded, color: primaryTeal, size: 38),
          ),
        ),
      );
    } else if (_avatarType.startsWith('asset:')) {
      final path = _avatarType.replaceFirst('asset:', '');
      return ClipOval(
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.medical_services_rounded, color: primaryTeal, size: 38),
          ),
        ),
      );
    } else {
      final emoji = _avatarType.replaceFirst('emoji:', '');
      return Center(
        child: Text(emoji, style: const TextStyle(fontSize: 42)),
      );
    }
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF64748B),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: Icon(prefixIcon, color: primaryTeal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryTeal, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HEADER WITH CIRCULAR ART ACCENT (Identik dengan Tampilan User)
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -65,
                    right: -55,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D9488).withValues(alpha: 0.55),
                      ),
                    ),
                  ),

                  // Avatar Tengah & Detail Nama Dokter
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Avatar Bulat Besar dengan Badge Edit di Sudut
                        Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.white, width: 3.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _buildAvatarWidget(),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _openEditProfileModal,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryTeal, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.camera_alt_rounded, color: primaryTeal, size: 15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Nama Dokter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _doctorName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.verified, color: Colors.white, size: 16),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Spesialisasi & Rumah Sakit
                        Text(
                          '$_specialization • $_hospital',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. BOTTOM HALF CURVED CARD (Card Putih Melengkung Identik User)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
                  children: [
                    // OPSI 1: ATUR JADWAL & PROFIL PRAKTIK (Fitur Utama)
                    _buildMenuItem(
                      icon: Icons.edit_calendar_rounded,
                      iconBg: softTealBg,
                      iconColor: accentTeal,
                      title: 'Atur Jadwal & Profil Praktik',
                      subtitle: '${_days.join(', ')} • ${_slots.length} Sesi • $_price',
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DoctorEditScheduleScreen(),
                          ),
                        );
                        if (updated == true) {
                          _loadProfile();
                        }
                      },
                    ),

                    // 1. Edit Profil Dokter
                    _buildMenuItem(
                      icon: Icons.person_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Edit Profil Dokter',
                      subtitle: 'Ubah nama gelar, spesialisasi, dan foto',
                      onTap: _openEditProfileModal,
                    ),

                    // 2. Kredensial & Izin Praktik
                    _buildMenuItem(
                      icon: Icons.badge_outlined,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      title: 'Kredensial & Legalitas',
                      subtitle: 'Nomor STR, riwayat pendidikan & RS',
                      onTap: _openCredentialsModal,
                    ),

                    // 3. Keluar
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Keluar dari Portal Dokter',
                      subtitle: 'Akhiri sesi praktik dokter saat ini',
                      onTap: _openLogoutModal,
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
}
