import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();

  String _nickname = '';
  String _userUuid = '';
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final name = await _storage.getNickname();
    final uuid = await _storage.getOrCreateUserUuid();
    final pinSet = await _storage.hasPin();
    if (!mounted) return;
    setState(() {
      _nickname = name;
      _userUuid = uuid;
      _hasPin = pinSet;
    });
  }

  void _editNickname() {
    final controller = TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Ganti Nama Panggilan (Alias)"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nama Alias"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _storage.setNickname(newName);
                if (mounted) setState(() => _nickname = newName);
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _setOrChangePin() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Setel PIN Keamanan (6 Digit)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Masukkan 6 Digit PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().length == 6) {
                await _storage.setPin(controller.text.trim());
                if (mounted) setState(() => _hasPin = true);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              }
            },
            child: const Text("Aktifkan"),
          ),
        ],
      ),
    );
  }

  void _confirmPanicClear() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text("Hapus Riwayat & Akun"),
          ],
        ),
        content: const Text(
          "Tindakan ini akan menghapus seluruh data percakapan lokal di ponsel dan server secara permanen (hard delete).",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _apiService.purgeUserData(_userUuid);
              await _storage.clearAllData();
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Seluruh data berhasil dihapus permanen.")),
                );
                _loadProfile();
              }
            },
            child: const Text("Hapus Permanen"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan & Privasi", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Nama Panggilan (Alias)"),
            subtitle: Text(_nickname),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: _editNickname,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Proteksi Kunci PIN"),
            subtitle: Text(_hasPin ? "PIN Aktif" : "Belum diaktifkan"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _setOrChangePin,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text("Identitas Anonim (Zero-KYC)"),
            subtitle: Text(
              _userUuid.isNotEmpty ? "UUID: ${_userUuid.substring(0, 8)}..." : "-",
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: Colors.red.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Panic Button: Hapus Seluruh Data", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _confirmPanicClear,
            ),
          ),
        ],
      ),
    );
  }
}
