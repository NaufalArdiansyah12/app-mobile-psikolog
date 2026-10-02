import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'doctor_home_screen.dart';
import 'doctor_bookings_screen.dart';
import 'doctor_chat_list_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  final int initialIndex;

  const DoctorMainScreen({super.key, this.initialIndex = 0});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final List<Widget> screens = [
      DoctorHomeScreen(onNavigateTab: _onTabTapped),
      const DoctorBookingsScreen(),
      const DoctorChatListScreen(),
      const DoctorProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: isKeyboardOpen
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, "Beranda"),
                    _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_month_rounded, "Janji Temu"),
                    _buildNavItem(2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "Chat Pasien"),
                    _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, "Profil"),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCCFBF1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
