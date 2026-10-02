import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'checkout_payment_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  String _selectedTime = '09:00 - 11:00 WIB';
  bool _isFavorite = false;
  List<String> _bookedSchedules = [];
  bool _isLoadingSchedules = true;

  final List<String> _timeSlots = [
    '09:00 - 11:00 WIB',
    '11:00 - 13:00 WIB',
    '13:00 - 15:00 WIB',
    '15:00 - 17:00 WIB',
    '17:00 - 19:00 WIB',
    '19:00 - 21:00 WIB',
  ];

  final List<String> _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final List<String> _weekDayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;

    final docSlots = widget.doctor['available_slots'];
    if (docSlots != null && docSlots is List && docSlots.isNotEmpty) {
      _timeSlots.clear();
      _timeSlots.addAll(List<String>.from(docSlots));
      _selectedTime = _timeSlots.first;
    }

    _loadBookedSchedules();
  }

  void _loadBookedSchedules() async {
    final docId = widget.doctor['id']?.toString() ?? 'psy_1';
    final schedules = await _apiService.getDoctorBookedSchedules(docId);
    if (!mounted) return;
    setState(() {
      _bookedSchedules = schedules;
      _isLoadingSchedules = false;
      // Jika tanggal default ternyata full, cari tanggal terdekat yang masih tersedia
      if (_isDayFull(_selectedDate)) {
        final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          final testDate = DateTime(_currentMonth.year, _currentMonth.month, d);
          final isPast = testDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
          if (!isPast && !_isDayFull(testDate)) {
            _selectedDate = testDate;
            break;
          }
        }
      }
      // Jika default time slot ternyata booked, geser ke slot pertama yang kosong
      if (_isSlotBooked(_selectedDate, _selectedTime)) {
        for (final slot in _timeSlots) {
          if (!_isSlotBooked(_selectedDate, slot)) {
            _selectedTime = slot;
            break;
          }
        }
      }
    });
  }

  bool _isSlotPastToday(DateTime date, String slot) {
    final now = DateTime.now();
    final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return false;

    final slotHourMatches = RegExp(r'(\d{1,2}):(\d{2})').allMatches(slot).toList();
    if (slotHourMatches.isEmpty) return false;

    final h1 = int.tryParse(slotHourMatches[0].group(1) ?? '0') ?? 0;
    final m1 = int.tryParse(slotHourMatches[0].group(2) ?? '0') ?? 0;
    final slotStartMin = h1 * 60 + m1;

    final nowMinutes = now.hour * 60 + now.minute;
    // Jam mulai sesi sudah terlewati atau sedang berjalan hari ini -> coret dan nonaktifkan
    return slotStartMin <= nowMinutes;
  }

  bool _isSlotBooked(DateTime date, String slot) {
    // 0. Cek apakah slot hari ini sudah lewat waktu
    if (_isSlotPastToday(date, slot)) {
      return true;
    }

    final int day = date.day;
    final int month = date.month;
    final int year = date.year;
    final String monthName = _monthNames[month].toLowerCase();

    // Short month names (Indonesian & English)
    const shortMonthsId = [
      '', 'jan', 'feb', 'mar', 'apr', 'mei', 'jun', 'jul', 'agu', 'sep', 'okt', 'nov', 'des'
    ];
    const shortMonthsEn = [
      '', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];

    // Extract start & end minutes from slot (e.g. "09:00 - 11:00 WIB")
    final slotHourMatches = RegExp(r'(\d{1,2}):(\d{2})').allMatches(slot).toList();
    int slotStartMin = 0;
    int slotEndMin = 0;
    if (slotHourMatches.isNotEmpty) {
      final h1 = int.tryParse(slotHourMatches[0].group(1) ?? '0') ?? 0;
      final m1 = int.tryParse(slotHourMatches[0].group(2) ?? '0') ?? 0;
      slotStartMin = h1 * 60 + m1;
      if (slotHourMatches.length > 1) {
        final h2 = int.tryParse(slotHourMatches[1].group(1) ?? '0') ?? 0;
        final m2 = int.tryParse(slotHourMatches[1].group(2) ?? '0') ?? 0;
        slotEndMin = h2 * 60 + m2;
      } else {
        slotEndMin = slotStartMin + 120; // default 2 jam (120 menit)
      }
    }

    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    for (final sched in _bookedSchedules) {
      final schedLower = sched.toLowerCase().trim();
      if (schedLower.isEmpty) continue;

      // 1. Cek Tanggal
      bool dateMatches = false;
      if (isToday && (schedLower.contains('hari ini') || schedLower.contains('today'))) {
        dateMatches = true;
      } else {
        final bool hasDay = RegExp(r'\b0?' + '$day' + r'\b').hasMatch(schedLower);
        final bool hasMonth = schedLower.contains(monthName) ||
            schedLower.contains(shortMonthsId[month]) ||
            schedLower.contains(shortMonthsEn[month]) ||
            schedLower.contains('-$month-') ||
            schedLower.contains('/$month/') ||
            schedLower.contains('-0$month-') ||
            schedLower.contains('/0$month/');
        final bool hasYear = schedLower.contains('$year');

        if (hasDay && hasMonth && (hasYear || !schedLower.contains('202'))) {
          dateMatches = true;
        }
      }

      if (!dateMatches) continue;

      // 2. Cek Jam / Waktu
      final schedHourMatches = RegExp(r'(\d{1,2}):(\d{2})').allMatches(schedLower).toList();
      if (schedHourMatches.isEmpty) {
        final startTimeStr = slot.split('-').first.trim().split(' ').first.trim().toLowerCase();
        if (schedLower.contains(startTimeStr)) return true;
        continue;
      }

      final sh1 = int.tryParse(schedHourMatches[0].group(1) ?? '0') ?? 0;
      final sm1 = int.tryParse(schedHourMatches[0].group(2) ?? '0') ?? 0;
      final int schedStartMin = sh1 * 60 + sm1;
      int schedEndMin = schedStartMin + 120;
      if (schedHourMatches.length > 1) {
        final sh2 = int.tryParse(schedHourMatches[1].group(1) ?? '0') ?? 0;
        final sm2 = int.tryParse(schedHourMatches[1].group(2) ?? '0') ?? 0;
        schedEndMin = sh2 * 60 + sm2;
      }

      // Overlap: slot waktu bertabrakan dengan jadwal booked
      if (slotStartMin < schedEndMin && slotEndMin > schedStartMin) {
        return true;
      }
    }
    return false;
  }

  bool _isDayFull(DateTime dayDate) {
    int bookedCount = 0;
    for (final slot in _timeSlots) {
      if (_isSlotBooked(dayDate, slot)) {
        bookedCount++;
      }
    }
    return bookedCount >= _timeSlots.length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final String name = doc['name'] ?? 'dr. Nadia S., Sp.KJ';
    final String role = doc['role'] ?? 'Psikiater Klinis Dewasa';
    final String fee = doc['fee'] ?? doc['price'] ?? 'Rp 250.000';
    final String rating = (doc['rating'] ?? '4.9').toString();
    final String reviews = (doc['reviews'] ?? '340').toString();
    final String experience = doc['experience'] ?? '9 Tahun';
    final String patients = doc['patients'] ?? '2.100+';
    final String education = doc['education'] ?? 'Spesialis Kedokteran Jiwa - FK Universitas Indonesia';
    final String strNumber = doc['str'] ?? 'STR: 31.1.2.100.3.19.112233';
    final String bio = doc['bio'] ??
        'Berpengalaman lebih dari 8 tahun dalam menangani kasus kecemasan umum, depresi, trauma emosional, serta peningkatan resiliensi mental melalui pendekatan Cognitive Behavioral Therapy (CBT) dan Mindfulness.';

    const Color primaryTeal = Color(0xFF006D77);

    return Scaffold(
      backgroundColor: primaryTeal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP HALF: Deep Teal Background with Doctor Profile
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFavorite ? const Color(0xFFF43F5E) : Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() => _isFavorite = !_isFavorite);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  duration: Duration(seconds: 1),
                                  backgroundColor: primaryTeal,
                                  content: Text('Tautan profil disalin!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Avatar & Info Dokter
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/gambar_home.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person_rounded,
                              color: primaryTeal,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              role,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '$rating ($reviews reviews)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. BOTTOM HALF: Curved White Card containing Stats, Tabs, and Details
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
                child: Column(
                  children: [
                    const SizedBox(height: 14),

                    // 3 Stat Highlights (Experience, Patients, Fee)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(experience, 'Experience'),
                            Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                            _buildStatItem(patients, 'Patients'),
                            Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                            _buildStatItem(fee, 'Per Sesi (2 Jam)'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: primaryTeal,
                      unselectedLabelColor: const Color(0xFF94A3B8),
                      indicatorColor: primaryTeal,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Schedules'),
                        Tab(text: 'About'),
                        Tab(text: 'Experiences'),
                        Tab(text: 'Reviews'),
                      ],
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Schedules (Calendar & Time Slots)
                          _buildScheduleTab(primaryTeal),

                          // Tab 2: About (Bio & Lulusan)
                          _buildAboutTab(bio, education, strNumber),

                          // Tab 3: Experiences
                          _buildExperienceTab(primaryTeal),

                          // Tab 4: Reviews
                          _buildReviewsTab(rating, reviews),
                        ],
                      ),
                    ),

                    // Bottom Floating Action Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Builder(
                        builder: (context) {
                          final bool isSlotDisabled = _isSlotBooked(_selectedDate, _selectedTime) || _isDayFull(_selectedDate);

                          String buttonText = 'Lanjut ke Pembayaran';
                          if (_isDayFull(_selectedDate)) {
                            buttonText = 'Tanggal Penuh (Pilih Tanggal Lain)';
                          } else if (_isSlotBooked(_selectedDate, _selectedTime)) {
                            buttonText = 'Sesi Telah Dibooking (Pilih Jam Lain)';
                          }

                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSlotDisabled ? const Color(0xFF94A3B8) : primaryTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              onPressed: isSlotDisabled
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CheckoutPaymentScreen(
                                            doctor: widget.doctor,
                                            selectedDate: _selectedDate,
                                            selectedTime: _selectedTime,
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                buttonText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildStatItem(String topText, String label) {
    return Column(
      children: [
        Text(
          topText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(Color primaryTeal) {
    final bool isSelectedDateFull = _isDayFull(_selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      children: [
        Text(
          'Pilih Tanggal Sesi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        _buildCalendarCard(primaryTeal),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih Waktu Konsultasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelectedDateFull ? const Color(0xFFF1F5F9) : const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSelectedDateFull ? 'Tanggal Penuh' : '2 Jam / Sesi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelectedDateFull ? const Color(0xFF64748B) : const Color(0xFF0D9488),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isSelectedDateFull) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Semua sesi di tanggal ${_selectedDate.day} ${_monthNames[_selectedDate.month]} sudah terisi penuh. Silakan pilih tanggal lain yang masih tersedia pada kalender.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _buildTimeSlotGrid(primaryTeal),
      ],
    );
  }

  Widget _buildCalendarCard(Color primaryTeal) {
    final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final int firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final int leadingEmpty = firstWeekday - 1;
    final int prevMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B), size: 20),
                onPressed: _prevMonth,
              ),
              Text(
                '${_monthNames[_currentMonth.month]} ${_currentMonth.year}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDayHeaders.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmpty) {
                final prevDay = prevMonthDays - leadingEmpty + index + 1;
                return Center(
                  child: Text(
                    '$prevDay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              }

              final day = index - leadingEmpty + 1;
              final dayDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isDayFull = _isDayFull(dayDate);
              final isSelected = _selectedDate.year == _currentMonth.year &&
                  _selectedDate.month == _currentMonth.month &&
                  _selectedDate.day == day &&
                  !isDayFull;
              final isToday = dayDate.year == DateTime.now().year &&
                  dayDate.month == DateTime.now().month &&
                  dayDate.day == DateTime.now().day;
              final isPast = dayDate.isBefore(
                DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
              );
              final bool isDisabled = isPast || isDayFull;

              return InkWell(
                onTap: isDisabled
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = dayDate;
                          if (_isSlotBooked(_selectedDate, _selectedTime)) {
                            for (final slot in _timeSlots) {
                              if (!_isSlotBooked(_selectedDate, slot)) {
                                _selectedTime = slot;
                                break;
                              }
                            }
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDayFull
                            ? const Color(0xFFE2E8F0)
                            : isSelected
                                ? primaryTeal
                                : isToday
                                    ? const Color(0xFFCCFBF1)
                                    : Colors.transparent,
                        border: isToday && !isSelected && !isDayFull
                            ? Border.all(color: primaryTeal, width: 1.2)
                            : isDayFull
                                ? Border.all(color: const Color(0xFFCBD5E1), width: 1.2)
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
                            color: isDayFull
                                ? const Color(0xFF94A3B8)
                                : isSelected
                                    ? Colors.white
                                    : isPast
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF0F172A),
                            decoration: isDayFull ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        bottom: 1,
                        child: Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9488),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Tersedia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF94A3B8), width: 1),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Penuh (Tutup)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Dipilih',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(Color primaryTeal) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timeSlots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, idx) {
        final slot = _timeSlots[idx];
        final bool isPastToday = _isSlotPastToday(_selectedDate, slot);
        final bool isBooked = _isSlotBooked(_selectedDate, slot);
        final bool isSelected = _selectedTime == slot && !isBooked;

        return InkWell(
          onTap: isBooked ? null : () => setState(() => _selectedTime = slot),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isBooked
                  ? const Color(0xFFF1F5F9)
                  : isSelected
                      ? primaryTeal
                      : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isBooked
                    ? const Color(0xFFCBD5E1)
                    : isSelected
                        ? primaryTeal
                        : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPastToday
                          ? Icons.history_toggle_off_rounded
                          : isBooked
                              ? Icons.lock_outline_rounded
                              : Icons.schedule_rounded,
                      size: 13,
                      color: isBooked
                          ? const Color(0xFF94A3B8)
                          : isSelected
                              ? Colors.white
                              : primaryTeal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      slot,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isBooked
                            ? const Color(0xFF94A3B8)
                            : isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                        decoration: isBooked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isPastToday
                      ? 'Waktu Lewat'
                      : isBooked
                          ? 'Sudah Dibooking'
                          : 'Durasi 2 Jam',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isBooked
                        ? const Color(0xFF94A3B8)
                        : isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(String bio, String education, String strNumber) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Profil & Keahlian',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          bio,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569), height: 1.45),
        ),
        const SizedBox(height: 14),
        Text(
          'Pendidikan & Lulusan',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        _buildInfoTile(Icons.school_rounded, education),
        const SizedBox(height: 6),
        _buildInfoTile(Icons.badge_rounded, strNumber),
        const SizedBox(height: 14),
        Text(
          'Bahasa Layanan',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        _buildInfoTile(Icons.translate_rounded, 'Bahasa Indonesia, English (Fluent)'),
      ],
    );
  }

  Widget _buildExperienceTab(Color primaryTeal) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildTimelineItem(primaryTeal, '2020 - Sekarang', 'Psikiater Klinis Senior', 'RS Mitra Sehat Jakarta & Konseling Digital'),
        _buildTimelineItem(primaryTeal, '2017 - 2020', 'Spesialis Regulasi Emosi & Depresi', 'Pusat Terapi Harmoni Jiwa'),
        _buildTimelineItem(primaryTeal, '2015 - 2017', 'Residensi Kedokteran Jiwa', 'RSUP Cipto Mangunkusumo'),
      ],
    );
  }

  Widget _buildReviewsTab(String rating, String totalReviews) {
    final List<Map<String, String>> reviews = [
      {
        'user': 'Salsabila R.',
        'rating': '5.0',
        'date': '2 hari yang lalu',
        'comment': 'Sangat mendengarkan tanpa menghakimi. Penjelasan CBT dan latihan grounding sangat membantu meredakan overthinking.',
      },
      {
        'user': 'Andi Pratama',
        'rating': '5.0',
        'date': '1 minggu yang lalu',
        'comment': 'Dokter memberikan arahan yang solutif dan praktis. Sangat direkomendasikan untuk yang sedang burnout kerja.',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: reviews.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r['user']!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        r['rating']!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                r['date']!,
                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 4),
              Text(
                r['comment']!,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF475569), height: 1.35),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF006D77)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Color primaryTeal, String year, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 36, color: const Color(0xFFCCFBF1)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(year, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: primaryTeal)),
                const SizedBox(height: 1),
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                const SizedBox(height: 1),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
