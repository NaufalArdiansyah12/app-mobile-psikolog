import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisModalOverlay extends StatelessWidget {
  const CrisisModalOverlay({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CrisisModalOverlay(),
    );
  }

  void _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFF0F0),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Bantuan Darurat",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kamu tidak sendiri. Jika sedang mengalami masa krisis, tolong hubungi bantuan profesional sekarang:",
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildHotlineCard(
              title: "Layanan Sejiwa Kemenkes",
              phone: "119 ext. 8",
              description: "Konseling krisis gratis 24 jam",
              onTap: () => _launchPhone('119'),
            ),
            const SizedBox(height: 8),
            _buildHotlineCard(
              title: "Halo Kemenkes",
              phone: "1500-567",
              description: "Informasi & tanggap darurat kesehatan",
              onTap: () => _launchPhone('1500567'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Tutup Sementara", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _launchPhone('119');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.phone),
            label: const Text("Panggil 119"),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard({
    required String title,
    required String phone,
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
