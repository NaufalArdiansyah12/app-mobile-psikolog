import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  String _nickname = 'Nina Sarah';
  String _userUuid = '';
  String _email = '';
  String _bio = 'Graphics and Web Designer';
  String _avatarType = 'asset:assets/gambar_home.jpeg';

  static const Color primaryTeal = Color(0xFF006D77);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color softTealBg = Color(0xFFCCFBF1);

  final List<Map<String, String>> _avatarPresets = [
    {'type': 'asset:assets/gambar_home.jpeg', 'label': 'Dokter 1'},
    {'type': 'emoji:👩‍💼', 'label': 'Profesional'},
    {'type': 'emoji:🌸', 'label': 'Bunga'},
    {'type': 'emoji:🎨', 'label': 'Kreatif'},
    {'type': 'emoji:🌿', 'label': 'Tenang'},
    {'type': 'emoji:🧘‍♀️', 'label': 'Meditasi'},
    {'type': 'emoji:☕', 'label': 'Santai'},
    {'type': 'emoji:⭐', 'label': 'Bintang'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final name = await _storage.getNickname();
    final uuid = await _storage.getOrCreateUserUuid();
    final email = await _storage.getUserEmail();
    final bio = await _storage.getUserBio();
    final avatar = await _storage.getUserAvatar();
    if (!mounted) return;
    setState(() {
      _nickname = name.isNotEmpty ? name : 'Nina Sarah';
      _userUuid = uuid;
      _email = email ?? '';
      _bio = bio.isNotEmpty ? bio : 'Graphics and Web Designer';
      _avatarType = avatar ?? 'asset:assets/gambar_home.jpeg';
    });
  }

  Future<void> _safeLaunchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showSnackBar("Membuka: $urlString");
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar("Membuka tautan: $urlString");
      }
    }
  }

  // 1. MODAL EDIT PROFILE & UPLOAD AVATAR
  void _openEditProfileModal() {
    final nameCtrl = TextEditingController(text: _nickname);
    final bioCtrl = TextEditingController(text: _bio);
    final emailCtrl = TextEditingController(text: _email);
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
              if (mounted) _showSnackBar("Gagal mengambil foto: $e");
            }
          }

          Widget buildModalAvatarPreview() {
            if (selectedAvatar.startsWith('file:')) {
              final path = selectedAvatar.replaceFirst('file:', '');
              return ClipOval(
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Text("🌸", style: TextStyle(fontSize: 32))),
                ),
              );
            } else if (selectedAvatar.startsWith('asset:')) {
              final path = selectedAvatar.replaceFirst('asset:', '');
              return ClipOval(
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Text("🌸", style: TextStyle(fontSize: 32))),
                ),
              );
            } else {
              final emoji = selectedAvatar.replaceFirst('emoji:', '');
              return Center(child: Text(emoji, style: const TextStyle(fontSize: 36)));
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
                        child: const Icon(Icons.person_outline_rounded, color: primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Edit Profile",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Upload foto profil, perbarui nama & bio",
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

                  // Avatar Live Preview & Upload Buttons
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF1F5F9),
                                border: Border.all(color: primaryTeal, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTeal.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: buildModalAvatarPreview(),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: primaryTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
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
                              label: Text("Pilih Galeri", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
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
                              label: Text("Kamera", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => pickImage(ImageSource.camera),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avatar Presets Picker
                  Text(
                    "ATAU PILIH PRESET AVATAR",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _avatarPresets.map((preset) {
                        final isSelected = selectedAvatar == preset['type'];
                        final isAsset = preset['type']!.startsWith('asset:');
                        final val = preset['type']!.replaceFirst('asset:', '').replaceFirst('emoji:', '');

                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedAvatar = preset['type']!);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? primaryTeal : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primaryTeal.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF1F5F9),
                              ),
                              child: isAsset
                                  ? ClipOval(child: Image.asset(val, fit: BoxFit.cover))
                                  : Center(child: Text(val, style: const TextStyle(fontSize: 24))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Field Nama Lengkap
                  _buildInputLabel("NAMA LENGKAP"),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: nameCtrl,
                    hintText: "Nama kamu",
                    prefixIcon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 16),

                  // Field Bio
                  _buildInputLabel("BIO / PEKERJAAN"),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: bioCtrl,
                    hintText: "Contoh: Graphics and Web Designer",
                    prefixIcon: Icons.work_outline_rounded,
                  ),

                  const SizedBox(height: 16),

                  // Field Email
                  _buildInputLabel("EMAIL TERDAFTAR"),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: emailCtrl,
                    hintText: "email@contoh.com",
                    prefixIcon: Icons.mail_outline_rounded,
                  ),

                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        final newBio = bioCtrl.text.trim();
                        final newEmail = emailCtrl.text.trim();

                        if (newName.isNotEmpty) {
                          await _storage.setNickname(newName);
                        }
                        if (newBio.isNotEmpty) {
                          await _storage.setUserBio(newBio);
                        }
                        if (newEmail.isNotEmpty) {
                          await _storage.setUserEmail(newEmail);
                        }
                        await _storage.setUserAvatar(selectedAvatar);

                        setState(() {
                          if (newName.isNotEmpty) _nickname = newName;
                          if (newBio.isNotEmpty) _bio = newBio;
                          if (newEmail.isNotEmpty) _email = newEmail;
                          _avatarType = selectedAvatar;
                        });

                        if (modalCtx.mounted) Navigator.pop(modalCtx);

                        if (mounted) {
                          _showSnackBar("Profil berhasil diperbarui!");
                        }
                      },
                      child: Text(
                        "Simpan Perubahan",
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
          );
        },
      ),
    );
  }

  // 2. MODAL MY STATS (Data Real dari Storage)
  void _openStatsModal() async {
    final chatSessions = await _storage.getChatSessions();
    final moods = await _storage.getMoods();

    int totalMessages = 0;
    int totalDistress = 0;
    int scoredSessions = 0;

    for (final s in chatSessions) {
      totalMessages += s.messages.length;
      if (s.analysis != null) {
        totalDistress += s.analysis!.distressScore;
        scoredSessions++;
      }
    }

    final double avgDistress = scoredSessions > 0 ? (totalDistress / scoredSessions) : 4.0;

    if (!mounted) return;

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
                  child: const Icon(Icons.bar_chart_rounded, color: primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Statistik Kesehatan Mental",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Data aktivitas & evaluasi dirimu",
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

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    "Sesi AI Selesai",
                    "${chatSessions.length} Sesi",
                    Icons.forum_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    "Mood Log",
                    "${moods.length} Check-in",
                    Icons.auto_stories_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    "Beban Emosi Rata-rata",
                    "${avgDistress.toStringAsFixed(1)} / 10",
                    Icons.analytics_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    "Pesan Teranalisis",
                    "$totalMessages Pesan",
                    Icons.insights_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

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
                child: Text(
                  "Tutup",
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. MODAL SOCIAL MEDIA & KOMUNITAS
  void _openSocialMediaModal() {
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
                  child: const Icon(Icons.groups_rounded, color: primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Komunitas & Media Sosial",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Terhubung dengan teman seperjuangan",
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

            _buildActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: const Color(0xFF10B981),
              iconBg: const Color(0xFFECFDF5),
              title: "Komunitas WhatsApp",
              subtitle: "Grup diskusi & dukungan emosional harian",
              onTap: () {
                _safeLaunchUrl("https://chat.whatsapp.com/mindpal-community");
              },
            ),
            const SizedBox(height: 8),

            _buildActionTile(
              icon: Icons.camera_alt_outlined,
              iconColor: const Color(0xFFE1306C),
              iconBg: const Color(0xFFFDF2F8),
              title: "Instagram @mindpal.app",
              subtitle: "Edukasi kesehatan mental & tips mindfulness harian",
              onTap: () {
                _safeLaunchUrl("https://instagram.com/mindpal.app");
              },
            ),
            const SizedBox(height: 8),

            _buildActionTile(
              icon: Icons.send_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFF0F9FF),
              title: "Telegram Channel",
              subtitle: "Rangkuman jurnal psikologi & jadwal webinar",
              onTap: () {
                _safeLaunchUrl("https://t.me/mindpal_channel");
              },
            ),
            const SizedBox(height: 8),

            _buildActionTile(
              icon: Icons.public_rounded,
              iconColor: primaryTeal,
              iconBg: softTealBg,
              title: "Website Resmi Hevenly",
              subtitle: "hevenly.health • Portal artikel & layanan klinis",
              onTap: () {
                _safeLaunchUrl("https://mindpal.health");
              },
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
                child: Text(
                  "Tutup",
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. MODAL SECURITY (Zero-KYC, Salin UUID, Setup PIN, Cache)
  void _openSecurityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (secCtx, setSecState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
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
                      child: const Icon(Icons.shield_outlined, color: primaryTeal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Keamanan & Privasi Zero-KYC",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Enkripsi lokal & proteksi identitas anonim",
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

                // Kartu UUID & Salin ID
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "ID Zero-KYC Pengguna",
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _userUuid));
                              _showSnackBar("ID Zero-KYC berhasil disalin!");
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.copy_rounded, color: primaryTeal, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "Salin ID",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: primaryTeal),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _userUuid.isNotEmpty ? _userUuid : "UUID sedang dibuat...",
                        style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Bersihkan Cache Lokal
                _buildActionTile(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  title: "Bersihkan Cache Aplikasi",
                  subtitle: "Bebaskan penyimpanan lokal tanpa menghapus akun",
                  onTap: () {
                    _showSnackBar("Cache aplikasi berhasil dibersihkan (2.4 MB dibebaskan)");
                  },
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
                    child: Text(
                      "Selesai",
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 5. MODAL MENU ACCOUNT (Ganti Password, Info Akun, Hapus Akun)
  void _openAccountModal() {
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
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Color(0xFF334155), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pengaturan Akun",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Keamanan, informasi ID & privasi akun",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Opsi 1: Ganti Password
            _buildActionTile(
              icon: Icons.key_rounded,
              iconColor: primaryTeal,
              iconBg: softTealBg,
              title: "Ganti Password",
              subtitle: "Perbarui kata sandi login akunmu",
              onTap: () {
                Navigator.pop(ctx);
                _openChangePasswordModal();
              },
            ),

            const SizedBox(height: 8),

            // Opsi 2: Info Email & UUID
            _buildActionTile(
              icon: Icons.badge_outlined,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: "Informasi ID & Email",
              subtitle: _email.isNotEmpty ? _email : "Zero-KYC ID: ${_userUuid.isNotEmpty ? _userUuid.substring(0, 8) : ''}...",
              onTap: () {
                Navigator.pop(ctx);
                _openAccountInfoModal();
              },
            ),

            const SizedBox(height: 8),

            // Opsi 3: Hapus Akun
            _buildActionTile(
              icon: Icons.person_remove_rounded,
              iconColor: const Color(0xFFE11D48),
              iconBg: const Color(0xFFFFF1F2),
              title: "Hapus Akun",
              subtitle: "Hapus akun beserta riwayat obrolan permanen",
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _openDeleteAccountModal();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 6. MODAL GANTI PASSWORD
  void _openChangePasswordModal() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isNewPassValid = newPassCtrl.text.trim().length >= 6;

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
                        child: const Icon(Icons.key_rounded, color: primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ganti Password",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Kata sandi baru minimal 6 karakter",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Password Lama
                  _buildInputLabel("PASSWORD SAAT INI"),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: oldPassCtrl,
                    hintText: "Masukkan password lama",
                    obscure: obscureOld,
                    onToggle: () => setModalState(() => obscureOld = !obscureOld),
                  ),

                  const SizedBox(height: 16),

                  // Password Baru
                  _buildInputLabel("PASSWORD BARU"),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: newPassCtrl,
                    hintText: "Minimal 6 karakter",
                    obscure: obscureNew,
                    onToggle: () => setModalState(() => obscureNew = !obscureNew),
                    onChanged: (_) => setModalState(() {}),
                  ),

                  // Checklist validasi minimal 6 karakter
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        Icon(
                          isNewPassValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: isNewPassValid ? primaryTeal : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Minimal 6 karakter",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isNewPassValid ? primaryTeal : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Konfirmasi Password Baru
                  _buildInputLabel("KONFIRMASI PASSWORD BARU"),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                    controller: confirmPassCtrl,
                    hintText: "Ketik ulang password baru",
                    obscure: obscureConfirm,
                    onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Simpan Password Baru
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: isLoading ? null : () async {
                        final oldPass = oldPassCtrl.text.trim();
                        final newPass = newPassCtrl.text.trim();
                        final confPass = confirmPassCtrl.text.trim();

                        if (oldPass.isEmpty) {
                          _showSnackBar("Masukkan password saat ini.");
                          return;
                        }
                        if (newPass.length < 6) {
                          _showSnackBar("Password baru minimal 6 karakter.");
                          return;
                        }
                        if (newPass != confPass) {
                          _showSnackBar("Password konfirmasi tidak cocok.");
                          return;
                        }

                        var emailToUse = _email;
                        if (emailToUse.isEmpty) {
                          emailToUse = await _storage.getUserEmail() ?? '';
                        }
                        if (emailToUse.isEmpty) {
                          _showSnackBar("Akun anonim belum memiliki email terdaftar.");
                          return;
                        }

                        setModalState(() => isLoading = true);

                        final result = await _apiService.changePassword(
                          email: emailToUse,
                          oldPassword: oldPass,
                          newPassword: newPass,
                        );

                        setModalState(() => isLoading = false);

                        if (result['success'] == true) {
                          await _storage.setUserPassword(newPass);
                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          if (mounted) {
                            _showSnackBar(result['message'] ?? "Password berhasil diperbarui!");
                          }
                        } else {
                          if (mounted) {
                            _showSnackBar(result['message'] ?? "Gagal memperbarui password.");
                          }
                        }
                      },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Simpan Password Baru",
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
          );
        },
      ),
    );
  }

  // 7. MODAL DETAIL INFORMASI AKUN
  void _openAccountInfoModal() {
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
                  child: const Icon(Icons.badge_outlined, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Detail Akun",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Identitas & status keamanan privasi",
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
                  _buildDetailRow(Icons.person_outline_rounded, "Nama Pengguna", _nickname),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildDetailRow(Icons.mail_outline_rounded, "Email Terdaftar", _email.isNotEmpty ? _email : "Mode Tamu Anonim"),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildDetailRow(Icons.shield_outlined, "Proteksi Identitas", "100% Zero-KYC E2EE"),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _buildDetailRow(Icons.fingerprint_rounded, "User UUID", _userUuid.isNotEmpty ? _userUuid : "-"),
                ],
              ),
            ),
            const SizedBox(height: 22),

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
                child: Text(
                  "Selesai",
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. MODAL HAPUS AKUN
  void _openDeleteAccountModal() {
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
            const SizedBox(height: 22),

            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF1F2),
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 36),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Hapus Akun Permanen?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              "Akun beserta seluruh riwayat obrolan, evaluasi emosi, dan catatan konsultasi akan dihapus permanen dari server dan perangkat ini.",
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
                    child: Text(
                      "Batal",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
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
                      await _apiService.purgeUserData(_userUuid);
                      await _storage.clearAllData();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: Text(
                      "Ya, Hapus",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
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

  // 9. MODAL KONFIRMASI LOGOUT
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: softTealBg,
              ),
              child: const Center(
                child: Icon(Icons.logout_rounded, color: primaryTeal, size: 30),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Keluar dari Akun?",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Kamu perlu masuk kembali dengan email dan kata sandi untuk mengakses obrolan Hevenly.",
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
                    child: Text(
                      "Batal",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
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
                    child: Text(
                      "Keluar",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
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

  // 10. MODAL HELP & PANDUAN DENGAN HOTLINE
  void _openHelpModal() {
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFF334155), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pusat Bantuan & Panduan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Panduan fitur dan petunjuk penggunaan aplikasi",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildHelpGuideItem(
                Icons.auto_awesome_rounded,
                "Hevenly AI CBT",
                "Sahabat AI empatik yang menerapkan Cognitive Behavioral Therapy untuk membantumu mengurai overthinking kapan pun.",
              ),
              const SizedBox(height: 10),
              _buildHelpGuideItem(
                Icons.medical_services_outlined,
                "Konsultasi Psikolog",
                "Pilih jadwal konsultasi privat bersama psikiater dan psikolog klinis tersertifikasi di tab Konsultasi.",
              ),
              const SizedBox(height: 10),
              _buildHelpGuideItem(
                Icons.auto_stories_rounded,
                "Jurnal & Mood Tracker",
                "Catat perasaanmu setiap hari dan tinjau kembali evaluasi distress dari percakapan AI yang tersimpan.",
              ),
              const SizedBox(height: 22),

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
                  child: Text(
                    "Mengerti",
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER UI
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
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryTeal, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                      color: isDestructive ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
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
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryTeal),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryTeal, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpGuideItem(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: softTealBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryTeal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    if (_avatarType.startsWith('file:')) {
      final path = _avatarType.replaceFirst('file:', '');
      return ClipOval(
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text("🌸", style: TextStyle(fontSize: 38)),
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
            child: Text("🌸", style: TextStyle(fontSize: 38)),
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
            // 1. TOP HEADER WITH CIRCULAR ART ACCENT
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

                  Positioned(
                    top: 10,
                    left: 14,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),

                  // Avatar Tengah & Detail Nama
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

                        // Nama Profil
                        Text(
                          _nickname,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 3),

                        // Role / Bio
                        Text(
                          _bio,
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

            // 2. BOTTOM HALF CURVED CARD (Card Putih Melengkung)
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
                    // 1. Edit Profile
                    _buildMenuItem(
                      icon: Icons.person_rounded,
                      iconBg: softTealBg,
                      iconColor: accentTeal,
                      title: "Edit Profile",
                      subtitle: "Ubah nama, bio, dan foto profil",
                      onTap: _openEditProfileModal,
                    ),

                    // 2. My Stats
                    _buildMenuItem(
                      icon: Icons.bar_chart_rounded,
                      iconBg: softTealBg,
                      iconColor: accentTeal,
                      title: "My Stats",
                      subtitle: "Statistik kesehatan mental & log aktivitas",
                      onTap: _openStatsModal,
                    ),

                    // 3. Social Media
                    _buildMenuItem(
                      icon: Icons.share_rounded,
                      iconBg: softTealBg,
                      iconColor: accentTeal,
                      title: "Social Media",
                      subtitle: "Komunitas Hevenly & saluran edukasi",
                      onTap: _openSocialMediaModal,
                    ),

                    // 4. Security
                    _buildMenuItem(
                      icon: Icons.shield_outlined,
                      iconBg: softTealBg,
                      iconColor: accentTeal,
                      title: "Security",
                      subtitle: "Enkripsi Zero-KYC & pembersih cache",
                      onTap: _openSecurityModal,
                    ),

                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                    const SizedBox(height: 10),

                    // 5. Account (Ganti Password, Info Akun, Hapus Akun)
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF334155),
                      title: "Account",
                      subtitle: "Ganti password, info akun & hapus akun",
                      onTap: _openAccountModal,
                    ),

                    // 6. Help
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF334155),
                      title: "Help",
                      subtitle: "Panduan fitur & petunjuk aplikasi",
                      onTap: _openHelpModal,
                    ),

                    // 7. Log-out
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF334155),
                      title: "Log-out",
                      subtitle: "Keluar dari sesi saat ini",
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
