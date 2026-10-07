import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'payment_instruction_screen.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final DateTime selectedDate;
  final String selectedTime;
  final bool isRebooking;

  const CheckoutPaymentScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
    this.isRebooking = false,
  });

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  String _selectedPaymentMethod = 'bca'; // bca, bri, bni, mandiri, qris
  bool _isLoading = false;

  final List<String> _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  int _parsePrice(dynamic priceStr) {
    if (priceStr == null) return 250000;
    final digits = priceStr.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 250000;
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  void _processPayment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final userUuid = await _storage.getOrCreateUserUuid();
    final doctorId = widget.doctor['id']?.toString() ?? 'psy_1';
    final formattedSchedule =
        '${widget.selectedDate.day} ${_months[widget.selectedDate.month]} ${widget.selectedDate.year}, ${widget.selectedTime}';
    final int amount = _parsePrice(widget.doctor['fee'] ?? widget.doctor['price']);

    String paymentType = 'bank_transfer';
    String bank = _selectedPaymentMethod;

    if (_selectedPaymentMethod == 'qris') {
      paymentType = 'qris';
      bank = '';
    }

    final chargeResult = await _apiService.createMidtransCharge(
      userUuid: userUuid,
      psychologistId: doctorId,
      scheduleTime: formattedSchedule,
      paymentType: paymentType,
      bank: bank,
      grossAmount: amount,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (chargeResult != null && chargeResult['status'] == 'success') {
      if (!mounted) return;
      if (widget.isRebooking) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentInstructionScreen(
              chargeData: chargeResult,
              doctor: widget.doctor,
              formattedSchedule: formattedSchedule,
              isRebooking: true,
            ),
          ),
        );
        if (result != null && mounted) {
          Navigator.of(context).pop(result);
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentInstructionScreen(
              chargeData: chargeResult,
              doctor: widget.doctor,
              formattedSchedule: formattedSchedule,
              isRebooking: false,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal membuat transaksi Midtrans. Silakan coba lagi.",
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final String name = doc['name'] ?? 'dr. Nadia S., Sp.KJ';
    final String role = doc['role'] ?? 'Psikiater Klinis Dewasa';
    final String hospital = doc['hospital'] ?? 'Praktek Online Hevenly';
    final int sessionFee = _parsePrice(doc['fee'] ?? doc['price']);
    const int adminFee = 0;
    final int totalAmount = sessionFee + adminFee;

    final String formattedDate =
        '${widget.selectedDate.day} ${_months[widget.selectedDate.month]} ${widget.selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Pembayaran Konsultasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // 1. Doctor Card Ringkas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.medical_services_rounded, color: Color(0xFF0D9488), size: 28),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Schedule Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0D9488), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Sesi',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$formattedDate, ${widget.selectedTime}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '2 Jam',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 3. Pilihan Metode Pembayaran (Midtrans Custom UI)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Metode Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Midtrans Secure',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildPaymentOption(
            id: 'bca',
            title: 'BCA Virtual Account',
            subtitle: 'Otomatis terverifikasi 24/7',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            id: 'bri',
            title: 'BRI Virtual Account (BRIVA)',
            subtitle: 'Bayar via BRImo / ATM BRI',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            id: 'bni',
            title: 'BNI Virtual Account',
            subtitle: 'Bayar via BNI Mobile / ATM',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            id: 'mandiri',
            title: 'Mandiri Bill Payment',
            subtitle: 'Bayar via Livin by Mandiri',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            id: 'qris',
            title: 'QRIS (GoPay, OVO, ShopeePay, DANA)',
            subtitle: 'Scan QR instan dari semua e-wallet',
            icon: Icons.qr_code_scanner_rounded,
          ),

          const SizedBox(height: 24),

          // 4. Rincian Pembayaran
          Text(
            'Rincian Biaya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildPriceRow('Biaya Konsultasi 1 Sesi', _formatRupiah(sessionFee)),
                const SizedBox(height: 10),
                _buildPriceRow('Biaya Layanan Platform', 'Gratis (Promo)', isGreen: true),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      _formatRupiah(totalAmount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Bayar ${_formatRupiah(totalAmount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedPaymentMethod,
              activeColor: const Color(0xFF0D9488),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B)),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
