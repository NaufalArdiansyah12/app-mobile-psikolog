import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final StorageService _storage = StorageService();

  bool _isLoginTab = true; // true: Masuk, false: Daftar
  bool _obscurePassword = true;

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Alur 1: Masuk Anonim (Zero-KYC sesuai PRD)
  void _startGuestSession() async {
    final alias = _nicknameController.text.trim().isNotEmpty
        ? _nicknameController.text.trim()
        : "Sobat MindPal";

    await _storage.setNickname(alias);
    await _storage.getOrCreateUserUuid();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  // Alur 2: Email & Password Auth
  void _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showToast("Format email tidak valid");
      return;
    }
    if (password.length < 6) {
      _showToast("Password minimal 6 karakter");
      return;
    }

    // Set nickname dari email username
    final defaultNickname = email.split('@').first;
    await _storage.setNickname(defaultNickname);
    await _storage.getOrCreateUserUuid();

    if (!mounted) return;
    _showToast(_isLoginTab ? "Berhasil Masuk!" : "Pendaftaran Berhasil!");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF09090B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Brand Logo Badge
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF0A0A0A),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header Title
              const Text(
                "MindPal",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF09090B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Ruang aman untuk bercerita dan pulih tanpa stigma.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF71717A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Segmented Pill Tab: Masuk / Daftar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLoginTab = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLoginTab ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isLoginTab
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            "Masuk",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _isLoginTab ? const Color(0xFF09090B) : const Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLoginTab = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isLoginTab ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isLoginTab
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            "Daftar Akun",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: !_isLoginTab ? const Color(0xFF09090B) : const Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              _buildInputLabel("EMAIL"),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hintText: "nama@email.com",
                  prefixIcon: Icons.mail_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              _buildInputLabel("KATA SANDI"),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  hintText: "Minimal 6 karakter",
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF71717A),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Submit Utama
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 2,
                ),
                onPressed: _submitEmailAuth,
                child: Text(
                  _isLoginTab ? "MASUK KE MINDPAL" : "BUAT AKUN BARU",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              // Divider "ATAU"
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE4E4E7))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "ATAU MASUK ANONIM",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE4E4E7))),
                  ],
                ),
              ),

              // Zero-KYC Mode Card (Sesuai PRD)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Mode Privasi Penuh (Zero-KYC)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Mulai curhat tanpa email atau nomor HP. Cukup masukkan nama panggilan samaran:",
                      style: TextStyle(fontSize: 12, color: Color(0xFF71717A), height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: "Contoh: Bintang, Rian, Kawan (opsional)",
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFA1A1AA)),
                        filled: true,
                        fillColor: const Color(0xFFF4F4F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF09090B),
                          side: const BorderSide(color: Color(0xFF27272A), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _startGuestSession,
                        icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                        label: const Text(
                          "Mulai Sebagai Tamu Anonim",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF52525B),
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA1A1AA)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF71717A), size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF09090B), width: 1.5),
      ),
    );
  }
}
