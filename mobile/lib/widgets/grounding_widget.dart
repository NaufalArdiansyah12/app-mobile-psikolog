import 'package:flutter/material.dart';

class GroundingExerciseWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const GroundingExerciseWidget({super.key, this.onComplete});

  @override
  State<GroundingExerciseWidget> createState() => _GroundingExerciseWidgetState();
}

class _GroundingExerciseWidgetState extends State<GroundingExerciseWidget> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      "count": "5",
      "action": "Benda yang Dilihat",
      "desc": "Sebutkan atau cari 5 benda di sekelilingmu (misal: meja, jam dinding, sepatu, jendela, buku).",
      "icon": Icons.visibility_outlined,
      "color": const Color(0xFF0284C7),
    },
    {
      "count": "4",
      "action": "Benda yang Disentuh",
      "desc": "Rasakan tekstur 4 benda di dekatmu (misal: kain baju, permukaan meja, rambut, case HP).",
      "icon": Icons.touch_app_outlined,
      "color": const Color(0xFF0D9488),
    },
    {
      "count": "3",
      "action": "Suara yang Didengar",
      "desc": "Dengarkan 3 suara berbeda (misal: desir AC/kipas, suara kendaraan, detak jam dinding).",
      "icon": Icons.hearing_outlined,
      "color": const Color(0xFFD97706),
    },
    {
      "count": "2",
      "action": "Aroma yang Tercium",
      "desc": "Fokus pada 2 aroma yang bisa kamu hirup (misal: sabun, kopi/teh, udara sekitar).",
      "icon": Icons.air_outlined,
      "color": const Color(0xFF7C3AED),
    },
    {
      "count": "1",
      "action": "Rasa di Lidah",
      "desc": "Sadari 1 rasa yang ada di mulutmu (misal: rasa air putih atau sensasi netral).",
      "icon": Icons.restaurant_outlined,
      "color": const Color(0xFFDB2777),
    },
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final color = step['color'] as Color;
    final progress = (_currentStep + 1) / _steps.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grounding 5-4-3-2-1",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(step['icon'] as IconData, size: 40, color: color),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "${step['count']} • ${step['action']}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step['desc'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.45),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _nextStep,
            child: Text(
              _currentStep == _steps.length - 1 ? "Selesai • Pikiran Kembali Hadir" : "Lanjut (${_currentStep + 1}/5)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
