import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ChatStreamChunk {
  final String delta;
  final bool isCrisis;
  final List<String> suggestedChips;
  final String? triggerExercise;

  ChatStreamChunk({
    required this.delta,
    required this.isCrisis,
    required this.suggestedChips,
    this.triggerExercise,
  });

  factory ChatStreamChunk.fromJson(Map<String, dynamic> json) => ChatStreamChunk(
        delta: json['delta'] ?? '',
        isCrisis: json['is_crisis'] ?? false,
        suggestedChips: List<String>.from(json['suggested_chips'] ?? []),
        triggerExercise: json['trigger_exercise'],
      );
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static final RegExp _clientCrisisPattern = RegExp(
    r'\b(bunuh\s*diri|suicide|akhiri\s*hidup|mau\s*mati|ingin\s*mati|self[\s-]*harm|sayat\s*tangan)\b',
    caseSensitive: false,
  );

  static bool checkCrisisLocally(String text) {
    return _clientCrisisPattern.hasMatch(text);
  }

  Stream<ChatStreamChunk> streamChatMessage({
    required String userUuid,
    required String message,
    required List<ChatMessage> history,
  }) async* {
    if (checkCrisisLocally(message)) {
      yield ChatStreamChunk(
        delta: "Keselamatanmu adalah hal paling berharga. Aku adalah AI dan tidak bisa memberikan bantuan darurat. Segera hubungi bantuan krisis resmi.",
        isCrisis: true,
        suggestedChips: ["Telepon 119", "Latihan Napas"],
        triggerExercise: "breathing",
      );
      return;
    }

    final url = Uri.parse('$baseUrl/api/chat/stream');
    final client = http.Client();
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    request.body = jsonEncode({
      'user_uuid': userUuid,
      'message': message,
      'history': history.map((e) => e.toJson()).toList(),
    });

    http.StreamedResponse response;
    try {
      response = await client.send(request);
    } catch (e) {
      yield ChatStreamChunk(
        delta: "Koneksi terputus ke $baseUrl. Pastikan backend aktif. Detail: $e",
        isCrisis: false,
        suggestedChips: ["Mulai Latihan Napas", "Coba Lagi"],
        triggerExercise: "breathing",
      );
      return;
    }

    if (response.statusCode != 200) {
      yield ChatStreamChunk(
        delta: "Maaf, terjadi gangguan server (${response.statusCode}). Coba lagi sebentar.",
        isCrisis: false,
        suggestedChips: ["Coba Lagi"],
      );
      return;
    }

    // Stream per byte chunk agar teks mengalir seketika tanpa nunggu newline buffer
    String buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final lineEnd = buffer.indexOf('\n');
        final line = buffer.substring(0, lineEnd).trim();
        buffer = buffer.substring(lineEnd + 1);

        if (line.startsWith('data:')) {
          final rawData = line.substring(5).trim();
          if (rawData.isEmpty) continue;
          try {
            final parsed = jsonDecode(rawData);
            yield ChatStreamChunk.fromJson(parsed);
          } catch (_) {}
        }
      }
    }
  }

  // Sync Mood ke Backend / Supabase
  Future<bool> syncMood(MoodEntry mood, String userUuid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/mood'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_uuid': userUuid,
          'score': mood.score,
          'label': mood.label,
          'triggers': mood.triggers,
          'notes': mood.notes,
          'timestamp': mood.timestamp.toIso8601String(),
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Ambil daftar psikolog
  Future<List<Map<String, dynamic>>> getPsychologists() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/consultation/psychologists'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['psychologists'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  // Booking sesi konsultasi
  Future<bool> createBooking({
    required String userUuid,
    required String psychologistId,
    required String scheduleTime,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/consultation/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_uuid': userUuid,
          'psychologist_id': psychologistId,
          'schedule_time': scheduleTime,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Panic Hard Delete
  Future<bool> purgeUserData(String userUuid) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/user/$userUuid/data'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
