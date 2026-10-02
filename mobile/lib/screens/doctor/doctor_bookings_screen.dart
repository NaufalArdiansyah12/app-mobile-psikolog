import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'doctor_chat_screen.dart';
import 'doctor_edit_schedule_screen.dart';

class DoctorBookingsScreen extends StatefulWidget {
  final VoidCallback? onRefreshParent;

  const DoctorBookingsScreen({super.key, this.onRefreshParent});

  @override
  State<DoctorBookingsScreen> createState() => _DoctorBookingsScreenState();
}

class _DoctorBookingsScreenState extends State<DoctorBookingsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String _activeFilter = 'Semua'; // 'Semua', 'Mendatang', 'Selesai', 'Dibatalkan'
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final list = await _api.getDoctorBookings();
    if (mounted) {
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    final success = await _api.updateBookingStatus(bookingId: bookingId, status: newStatus);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Janji temu berhasil dikonfirmasi'
                : newStatus == 'completed'
                    ? 'Sesi konsultasi ditandai selesai'
                    : 'Status janji temu diperbarui',
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchBookings();
      widget.onRefreshParent?.call();
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_activeFilter == 'Semua') return _bookings;
    if (_activeFilter == 'Mendatang') {
      return _bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'pending').toList();
    }
    if (_activeFilter == 'Selesai') {
      return _bookings.where((b) => b['status'] == 'completed').toList();
    }
    if (_activeFilter == 'Dibatalkan') {
      return _bookings.where((b) => b['status'] == 'cancelled').toList();
    }
    return _bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Daftar Janji Konsultasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Atur Jadwal & Profil Praktik',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorEditScheduleScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Mendatang', 'Selesai', 'Dibatalkan'].map((filter) {
                  final isSelected = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.slate,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.bgLight,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) setState(() => _activeFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Booking List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredBookings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final item = _filteredBookings[index];
                            return _buildBookingCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: AppColors.mutedLight.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada data janji temu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kategori "$_activeFilter" saat ini kosong.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final patientName = item['patient_name'] ?? 'Pasien MindPal';
    final scheduleTime = item['schedule_time'] ?? 'Jadwal belum ditentukan';
    final notes = item['notes'] ?? 'Tidak ada catatan keluhan tambahan.';
    final bookingId = item['id'] ?? '';

    Color badgeBg;
    Color badgeFg;
    String statusLabel;

    switch (status) {
      case 'confirmed':
        badgeBg = const Color(0xFFECFDF5);
        badgeFg = const Color(0xFF047857);
        statusLabel = 'Terkonfirmasi';
        break;
      case 'completed':
        badgeBg = const Color(0xFFF1F5F9);
        badgeFg = const Color(0xFF475569);
        statusLabel = 'Selesai';
        break;
      case 'cancelled':
        badgeBg = const Color(0xFFFEF2F2);
        badgeFg = const Color(0xFFB91C1C);
        statusLabel = 'Dibatalkan';
        break;
      default:
        badgeBg = const Color(0xFFFFFBEB);
        badgeFg = const Color(0xFFB45309);
        statusLabel = 'Menunggu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pasien & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        item['patient_age'] ?? 'Pasien Umum',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          // Jadwal Waktu
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scheduleTime,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Catatan Keluhan Pasien
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              notes,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.slate,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Aksi Dokter
          Row(
            children: [
              if (status == 'pending') ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _updateStatus(bookingId, 'cancelled'),
                    child: Text('Tolak', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(bookingId, 'confirmed'),
                    child: Text('Terima', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else if (status == 'confirmed') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(
                      'Buka Chat',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.cardAquaBorder),
                      backgroundColor: const Color(0xFFF0FDFA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorChatScreen(
                            bookingId: bookingId,
                            patientName: patientName,
                            patientAge: item['patient_age'],
                            bookingNotes: notes,
                          ),
                        ),
                      ).then((completed) {
                        if (completed == true) {
                          _updateStatus(bookingId, 'completed');
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () => _updateStatus(bookingId, 'completed'),
                    child: Text('Selesai', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    status == 'completed' ? 'Sesi telah diselesaikan.' : 'Janji temu dibatalkan.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
