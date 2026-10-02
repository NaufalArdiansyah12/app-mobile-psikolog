import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'doctor_consultation_chat_screen.dart';

class PaymentInstructionScreen extends StatefulWidget {
  final Map<String, dynamic> chargeData;
  final Map<String, dynamic> doctor;
  final String formattedSchedule;

  const PaymentInstructionScreen({
    super.key,
    required this.chargeData,
    required this.doctor,
    required this.formattedSchedule,
  });

  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  bool _isChecking = false;
  bool _isSimulating = false;
  bool _isPaid = false;
  Timer? _countdownTimer;
  int _secondsLeft = 86400; // 24 jam

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 250.000';
    final int val = int.tryParse(amount.toString()) ?? 250000;
    final str = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke papan klip!', style: GoogleFonts.plusJakartaSans()),
        backgroundColor: const Color(0xFF0D9488),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _simulateInstantPayment() async {
    if (_isSimulating || _isPaid) return;
    setState(() => _isSimulating = true);

    final orderId = widget.chargeData['order_id'] ?? '';
    final bookingId = widget.chargeData['booking_id'] ?? '';
    final success = await _apiService.simulatePayment(
      orderId,
      bookingId: bookingId,
      chargeData: widget.chargeData,
    );

    if (!mounted) return;
    setState(() => _isSimulating = false);

    if (success) {
      final docId = widget.doctor['id']?.toString() ?? 'psy_1';
      await _storage.addBookedSchedule(docId, widget.formattedSchedule);
      if (!mounted) return;
      setState(() => _isPaid = true);
      _showPaymentSuccessModal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memproses simulasi pembayaran.", style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
  }

  void _checkStatus() async {
    if (_isChecking || _isPaid) return;
    setState(() => _isChecking = true);

    final bookingId = widget.chargeData['booking_id'] ?? '';
    final orderId = widget.chargeData['order_id'] ?? '';
    final status = await _apiService.checkBookingStatus(bookingId, orderId: orderId);

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (status == 'confirmed' || status == 'completed') {
      final docId = widget.doctor['id']?.toString() ?? 'psy_1';
      await _storage.addBookedSchedule(docId, widget.formattedSchedule);
      if (!mounted) return;
      setState(() => _isPaid = true);
      _showPaymentSuccessModal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pembayaran belum terdeteksi. Silakan transfer atau coba simulasi.", style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
  }

  void _showPaymentSuccessModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCCFBF1),
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF0D9488), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              "Pembayaran Berhasil!",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Sesi konsultasi 1-on-1 dengan ${widget.doctor['name']} telah aktif dan siap dimulai.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: Text(
                  "Mulai Sesi Chat Dokter",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => DoctorConsultationChatScreen(
                        bookingId: widget.chargeData['booking_id'] ?? '',
                        doctor: widget.doctor,
                        scheduleTime: widget.formattedSchedule,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.chargeData;
    final String paymentType = data['payment_type'] ?? 'bank_transfer';
    final String bank = data['bank'] ?? 'BCA';
    final String vaNumber = data['va_number'] ?? '';
    final String billKey = data['bill_key'] ?? '';
    final String billerCode = data['biller_code'] ?? '70012';
    final dynamic amount = data['gross_amount'];
    final String orderId = data['order_id'] ?? '';

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
          'Instruksi Pembayaran',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // 1. Countdown Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF0D9488), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Selesaikan Dalam',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTimer(_secondsLeft),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Card Nomor Virtual Account / QRIS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      paymentType == 'qris' ? 'QRIS Pembayaran' : '$bank Virtual Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Menunggu Bayar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (paymentType == 'qris') ...[
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 160, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Pindai QR ini melalui aplikasi GoPay, OVO, ShopeePay, atau BCA Mobile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                  ),
                ] else if (bank.toUpperCase() == 'MANDIRI') ...[
                  Text('Kode Perusahaan (Biller Code)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(billerCode, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      TextButton.icon(
                        onPressed: () => _copyToClipboard(billerCode, 'Biller Code'),
                        icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0D9488)),
                        label: Text('Salin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF0D9488))),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  Text('Nomor Tagihan (Bill Key)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(billKey, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      TextButton.icon(
                        onPressed: () => _copyToClipboard(billKey, 'Bill Key'),
                        icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0D9488)),
                        label: Text('Salin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF0D9488))),
                      ),
                    ],
                  ),
                ] else ...[
                  Text('Nomor Rekening Virtual Account', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vaNumber,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(vaNumber, 'Nomor Virtual Account'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF0D9488)),
                                const SizedBox(width: 4),
                                Text(
                                  'Salin',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF64748B))),
                    Text(
                      _formatRupiah(amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                    Text(orderId, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Petunjuk Pembayaran Singkat
          Text(
            'Cara Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildInstructionTile('1. Buka aplikasi Mobile Banking atau ATM bank pilihanmu.'),
          _buildInstructionTile('2. Pilih menu Transfer > Virtual Account / Pembayaran Tagihan.'),
          _buildInstructionTile('3. Masukkan nomor Virtual Account di atas dan pastikan nominal sesuai.'),
          _buildInstructionTile('4. Konfirmasi transaksi dan simpan bukti pembayaran.'),

          const SizedBox(height: 24),

          // 4. Tombol Simulasi Sandbox Bayar Instan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFF0D9488), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Simulator Midtrans Sandbox',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Uji coba alur verifikasi lunas seketika tanpa perlu transfer uang asli.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSimulating ? null : _simulateInstantPayment,
                    child: _isSimulating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : Text(
                            'Simulasi Bayar Berhasil Sekarang',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isChecking ? null : _checkStatus,
              child: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF0D9488))),
                    )
                  : Text(
                      'Cek Status Pembayaran',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionTile(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              step,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
