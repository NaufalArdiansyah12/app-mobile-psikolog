import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String category;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.category,
    this.isRead = false,
  });
}

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const NotificationPanel(),
    );
  }

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final List<NotificationItem> _items = [
    NotificationItem(
      id: 'n1',
      title: 'Jadwal Sesi Hari Ini 🗓️',
      body: 'Sesi konseling dengan dr. Nadia S. dimulai pukul 19:00. Persiapkan dirimu.',
      time: '5 mnt lalu',
      icon: Icons.calendar_today_rounded,
      iconColor: Color(0xFF0D9488),
      iconBg: Color(0xFFCCFBF1),
      category: 'Pengingat',
      isRead: false,
    ),
    NotificationItem(
      id: 'n2',
      title: 'Selamat! Streak 5 Hari 🔥',
      body: 'Kamu sudah konsisten mencatat mood selama 5 hari berturut-turut. Pertahankan!',
      time: '1 jam lalu',
      icon: Icons.local_fire_department_rounded,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFEF3C7),
      category: 'Pencapaian',
      isRead: false,
    ),
    NotificationItem(
      id: 'n3',
      title: 'Tips Kesehatan Mental 🧠',
      body: 'Cobalah teknik Box Breathing 5 menit setiap pagi untuk mengurangi kecemasan harian.',
      time: '3 jam lalu',
      icon: Icons.lightbulb_outline_rounded,
      iconColor: Color(0xFF4F46E5),
      iconBg: Color(0xFFEEF2FF),
      category: 'Tips',
      isRead: true,
    ),
    NotificationItem(
      id: 'n4',
      title: 'Promo: Diskon 30% Sesi Pertama',
      body: 'Dapatkan potongan harga sesi konseling pertamamu. Berlaku hingga akhir bulan ini.',
      time: 'Kemarin',
      icon: Icons.local_offer_rounded,
      iconColor: Color(0xFFDB2777),
      iconBg: Color(0xFFFCE7F3),
      category: 'Promo',
      isRead: true,
    ),
    NotificationItem(
      id: 'n5',
      title: 'Catatan Harian Belum Diisi',
      body: 'Luangkan 2 menit untuk mencatat perasaanmu hari ini. Kesehatan mental dimulai dari kesadaran diri.',
      time: 'Kemarin',
      icon: Icons.edit_note_rounded,
      iconColor: Color(0xFF0D9488),
      iconBg: Color(0xFFCCFBF1),
      category: 'Pengingat',
      isRead: true,
    ),
  ];

  int get _unreadCount => _items.where((e) => !e.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.isRead = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      final item = _items.firstWhere((e) => e.id == id);
      item.isRead = true;
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => !e.isRead).toList();
    final read = _items.where((e) => e.isRead).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifikasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadCount baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Tandai Semua Dibaca',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // List area
          Flexible(
            child: _items.isEmpty
                ? _buildEmpty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      // Unread section
                      if (unread.isNotEmpty) ...[
                        _buildSectionLabel('Belum Dibaca'),
                        const SizedBox(height: 8),
                        ...unread.map((item) => _buildCard(item)),
                        const SizedBox(height: 16),
                      ],

                      // Read section
                      if (read.isNotEmpty) ...[
                        _buildSectionLabel('Sebelumnya'),
                        const SizedBox(height: 8),
                        ...read.map((item) => _buildCard(item)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCard(NotificationItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteItem(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFEF4444),
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: () => _markRead(item.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF0FDFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF99F6E4),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: item.isRead ? 0.02 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.iconBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: item.iconColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.time,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D9488),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Semua sudah dibaca!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kamu sudah up to date. Tidak ada notifikasi baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
