import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../widgets/app_logo.dart';
import 'doctor/doctor_main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();

  bool _isLogin = true; // true = Login, false = Sign Up
  bool _obscurePassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color fieldBorderColor = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (!_isLogin && name.isEmpty) {
      _showToast("Nama tidak boleh kosong");
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showToast("Format email tidak valid");
      return;
    }

    if (password.length < 6) {
      _showToast("Kata sandi minimal 6 karakter");
      return;
    }

    if (!_isLogin && !_agreeTerms) {
      _showToast("Harap setujui Syarat dan Ketentuan");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final res = await _api.login(email: email, password: password);
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res.success && res.userId != null) {
          final effectiveRole = res.role.isNotEmpty ? res.role : 'user';
          await _storage.saveUserSession(
            userId: res.userId!,
            email: res.email ?? email,
            nickname: res.nickname ?? email.split('@').first,
            role: effectiveRole,
            doctorId: res.psychologistId,
            token: res.token,
          );
          if (!mounted) return;
          _showSuccessDialog(effectiveRole);
        } else {
          _showToast(res.errorMessage ?? "Gagal masuk. Periksa kembali email dan sandi.");
        }
      } else {
        final res = await _api.register(
          email: email,
          password: password,
          name: name,
          role: 'user',
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res.success && res.userId != null) {
          final effectiveRole = res.role.isNotEmpty ? res.role : 'user';
          await _storage.saveUserSession(
            userId: res.userId!,
            email: res.email ?? email,
            nickname: res.nickname ?? name,
            role: effectiveRole,
            doctorId: res.psychologistId,
            token: res.token,
          );
          if (!mounted) return;
          _showSuccessDialog(effectiveRole);
        } else {
          _showToast(res.errorMessage ?? "Gagal mendaftar. Silakan coba lagi.");
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showToast("Terjadi kendala jaringan: $e");
    }
  }

  void _showSuccessDialog(String role) {
    final bool isDoctor = role == 'doctor';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFCCFBF1),
                ),
                child: Center(
                  child: Icon(
                    isDoctor ? Icons.medical_services_rounded : Icons.check_rounded,
                    color: primaryTeal,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isDoctor
                    ? "Selamat Datang, Dokter!"
                    : (_isLogin ? "Selamat Datang Kembali!" : "Akun Berhasil Dibuat!"),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isDoctor
                    ? "Portal tenaga ahli siap digunakan untuk mengelola antrean dan sesi konsultasi pasien."
                    : (_isLogin
                        ? "Berhasil masuk ke Hevenly. Data obrolan dan jurnalmu siap digunakan."
                        : "Akunmu berhasil didaftarkan dan tersimpan aman di database."),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final Widget targetScreen = isDoctor
                        ? const DoctorMainScreen()
                        : const MainNavigationScreen();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => targetScreen),
                    );
                  },
                  child: Text(
                    isDoctor ? "Masuk ke Dashboard Dokter" : "Mulai Sekarang",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: !_isLogin
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
                onPressed: () => setState(() => _isLogin = true),
              )
            : null,
        centerTitle: true,
        title: Text(
          _isLogin ? "Masuk ke Akun" : "Daftar Akun Baru",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Brand Badge
              Center(
                child: Column(
                  children: [
                    const AppLogo(
                      size: 72,
                      iconSize: 36,
                      borderRadius: 22,
                      backgroundColor: primaryTeal,
                      iconColor: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Hevenly",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLogin
                          ? "Masuk untuk melanjutkan perjalanan kesehatan mentalmu"
                          : "Buat akun pribadi untuk menyimpan jurnal & riwayat sesi",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isLogin) ...[
                // Banner Pintasan Akun Demo Dokter untuk Pengujian
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: primaryTeal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Uji Akun Dokter: dokter@mindpal.id",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF0F766E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 0),
                        ),
                        onPressed: () {
                          setState(() {
                            _emailController.text = "dokter@mindpal.id";
                            _passwordController.text = "password123";
                          });
                        },
                        child: Text(
                          "Gunakan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Field Nama (Khusus Sign Up)
              if (!_isLogin) ...[
                _buildFieldLabel("NAMA LENGKAP"),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: _nameController,
                  hintText: "Masukkan nama kamu",
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 18),
              ],

              // Field Email
              _buildFieldLabel("ALAMAT EMAIL"),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _emailController,
                hintText: "nama@email.com",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                suffix: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _emailController,
                  builder: (context, val, _) {
                    if (val.text.contains('@') && val.text.contains('.')) {
                      return const Icon(Icons.check_rounded, color: primaryTeal, size: 20);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Field Password
              _buildFieldLabel("KATA SANDI"),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _passwordController,
                hintText: "Minimal 6 karakter",
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 12),

              // Forgot Password (Hanya muncul saat Login)
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showToast("Tautan reset sandi dapat dikirimkan ke email terdaftar.");
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Lupa Kata Sandi?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryTeal,
                      ),
                    ),
                  ),
                ),

              // Terms and Conditions Checkbox (Hanya muncul saat Sign Up)
              if (!_isLogin) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Saya menyetujui ",
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                          children: const [
                            TextSpan(
                              text: "Syarat & Ketentuan",
                              style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: " serta "),
                            TextSpan(
                              text: "Kebijakan Privasi",
                              style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 26),

              // Tombol Utama Login / Sign Up
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitAuth,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLogin ? "MASUK KE HEVENLY" : "BUAT AKUN BARU",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),

              // Switch Login <-> Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Belum memiliki akun? " : "Sudah memiliki akun? ",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                    child: Text(
                      _isLogin ? "Daftar Sekarang" : "Masuk",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF475569),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fieldBorderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}
