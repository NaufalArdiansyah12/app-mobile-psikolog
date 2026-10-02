import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'doctor_chat_screen.dart';

class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({super.key});

  @override
  State<DoctorChatListScreen> createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final bookings = await _api.getDoctorBookings();
    if (mounted) {
      setState(() {
        _chatRooms = bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'completed').toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Konsultasi Pasien',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.mutedLight.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada percakapan aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pasien yang booking akan muncul di sini saat sesi aktif.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                    itemCount: _chatRooms.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final item = _chatRooms[index];
                      final patientName = item['patient_name'] ?? 'Pasien MindPal';
                      final time = item['schedule_time'] ?? 'Hari ini';
                      final notes = item['notes'] ?? 'Keluhan konsultasi';
                      final isCompleted = item['status'] == 'completed';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (!isCompleted)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                patientName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              isCompleted ? 'Selesai' : 'Aktif',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? AppColors.muted : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            notes,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorChatScreen(
                                bookingId: item['id']?.toString() ?? 'bk_doc_1',
                                patientName: patientName,
                                patientAge: item['patient_age'],
                                bookingNotes: notes,
                              ),
                            ),
                          ).then((_) => _loadChats());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
