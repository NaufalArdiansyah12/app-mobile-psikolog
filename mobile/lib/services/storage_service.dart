import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class StorageService {
  static const String _keyUserUuid = 'mindpal_user_uuid';
  static const String _keyUserEmail = 'mindpal_user_email';
  static const String _keyUserRole = 'mindpal_user_role';
  static const String _keyDoctorId = 'mindpal_doctor_id';
  static const String _keyAuthToken = 'mindpal_auth_token';
  static const String _keyIsLoggedIn = 'mindpal_is_logged_in';
  static const String _keyNickname = 'havenly_user_nickname';
  static const String _keyPin = 'havenly_security_pin';
  static const String _keyMoods = 'havenly_local_moods';
  static const String _keyChatSessions = 'havenly_chat_sessions';
  static const String _keyLastCheckinDate = 'havenly_last_mood_checkin_date';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // User Session Management
  Future<void> saveUserSession({
    required String userId,
    required String email,
    required String nickname,
    String role = 'user',
    String? doctorId,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserUuid, userId);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyNickname, nickname);
    await prefs.setString(_keyUserRole, role);
    if (doctorId != null) {
      await prefs.setString(_keyDoctorId, doctorId);
    }
    if (token != null) {
      await prefs.setString(_keyAuthToken, token);
    }
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'user';
  }

  Future<String?> getDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorId);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final bool loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final String? uuid = prefs.getString(_keyUserUuid);
    return loggedIn && uuid != null && uuid.isNotEmpty;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserUuid);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyDoctorId);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyNickname);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  // FR-01: User UUID (dari akun yang login)
  Future<String> getOrCreateUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_keyUserUuid);
    if (uuid == null || uuid.isEmpty) {
      uuid = const Uuid().v4();
      await prefs.setString(_keyUserUuid, uuid);
    }
    return uuid;
  }

  // FR-02: Nickname
  Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNickname) ?? prefs.getString('mindpal_user_nickname') ?? 'Sobat Hevenly';
  }

  Future<void> setNickname(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, name);
  }

  static const String _keyUserAvatar = 'mindpal_user_avatar';
  static const String _keyUserPassword = 'mindpal_user_password';
  static const String _keyUserBio = 'mindpal_user_bio';

  Future<String?> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserAvatar);
  }

  Future<void> setUserAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAvatar, avatar);
  }

  Future<String?> getUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPassword) ?? '••••••';
  }

  Future<void> setUserPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPassword, password);
  }

  Future<String> getUserBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserBio) ?? 'Member Hevenly • Mental Health';
  }

  Future<void> setUserBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserBio, bio);
  }

  // FR-03: Local PIN Protection
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyPin);
  }

  // Doctor Schedule & Practice Profile
  static const String _keyDoctorDays = 'mindpal_doc_schedule_days';
  static const String _keyDoctorSlots = 'mindpal_doc_schedule_slots';
  static const String _keyDoctorPriceVal = 'mindpal_doc_price_val';
  static const String _keyDoctorAboutVal = 'mindpal_doc_about_val';
  static const String _keyDoctorExpVal = 'mindpal_doc_exp_val';
  static const String _keyDoctorHospVal = 'mindpal_doc_hosp_val';
  static const String _keyDoctorEduVal = 'mindpal_doc_edu_val';
  static const String _keyDoctorStrVal = 'mindpal_doc_str_val';

  Future<List<String>> getDoctorScheduleDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyDoctorDays) ?? ['Senin', 'Selasa', 'Rabu', 'Kamis'];
  }

  Future<void> setDoctorScheduleDays(List<String> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyDoctorDays, days);
  }

  Future<List<String>> getDoctorScheduleSlots() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyDoctorSlots) ?? [
      '09:00 - 10:00',
      '13:00 - 14:00',
      '16:00 - 17:00',
      '19:00 - 20:00',
    ];
  }

  Future<void> setDoctorScheduleSlots(List<String> slots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyDoctorSlots, slots);
  }

  Future<String> getDoctorPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorPriceVal) ?? 'Rp 250.000';
  }

  Future<void> setDoctorPrice(String price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorPriceVal, price);
  }

  Future<String> getDoctorAbout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorAboutVal) ??
        'Spesialis dalam farmakoterapi dan psikoterapi suportif untuk kasus gangguan suasana hati (mood disorder), insomnia berkepanjangan, dan pemulihan trauma psikologis.';
  }

  Future<void> setDoctorAbout(String about) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorAboutVal, about);
  }

  Future<String> getDoctorExperience() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorExpVal) ?? '8 Tahun';
  }

  Future<void> setDoctorExperience(String exp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorExpVal, exp);
  }

  Future<String> getDoctorHospital() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorHospVal) ?? 'RS Mitra Sehat Jakarta';
  }

  Future<void> setDoctorHospital(String hosp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorHospVal, hosp);
  }

  Future<String> getDoctorEducation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorEduVal) ?? 'Spesialis Kedokteran Jiwa - FK Universitas Indonesia';
  }

  Future<void> setDoctorEducation(String edu) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorEduVal, edu);
  }

  Future<String> getDoctorStr() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDoctorStrVal) ?? 'STR: 31.1.2.100.3.19.112233';
  }

  Future<void> setDoctorStr(String str) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorStrVal, str);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin) == pin;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, pin);
  }

  // FR-13: Offline Mood Storage

  // Cek apakah hari ini sudah checkin mood
  Future<bool> hasCheckedInToday() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyLastCheckinDate);
    if (saved == null) return false;
    final today = DateTime.now();
    final savedDate = DateTime.tryParse(saved);
    if (savedDate == null) return false;
    return savedDate.year == today.year &&
        savedDate.month == today.month &&
        savedDate.day == today.day;
  }

  Future<void> markCheckinToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastCheckinDate, DateTime.now().toIso8601String());
  }
  Future<List<MoodEntry>> getMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyMoods) ?? [];
      final List<MoodEntry> result = [];
      for (final item in raw) {
        try {
          result.add(MoodEntry.fromJson(jsonDecode(item)));
        } catch (_) {}
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMood(MoodEntry mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyMoods) ?? [];
      final list = List<String>.from(raw);
      list.add(jsonEncode(mood.toJson()));
      await prefs.setStringList(_keyMoods, list);
    } catch (_) {}
  }

  // Riwayat Chat Dokter per Booking ID dan Doctor ID (Bersambung)
  Future<List<Map<String, dynamic>>> getDoctorChat(String bookingId, {String? doctorId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? raw;
      if (doctorId != null && doctorId.isNotEmpty) {
        raw = prefs.getString('mindpal_doc_chat_dr_$doctorId');
      }
      if ((raw == null || raw.isEmpty) && bookingId.isNotEmpty) {
        raw = prefs.getString('mindpal_doc_chat_$bookingId');
      }
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveDoctorChat(String bookingId, List<Map<String, dynamic>> messages, {String? doctorId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(messages);
      await prefs.setString('mindpal_doc_chat_$bookingId', encoded);
      if (doctorId != null && doctorId.isNotEmpty) {
        await prefs.setString('mindpal_doc_chat_dr_$doctorId', encoded);
      }
    } catch (_) {}
  }

  // Riwayat Sesi Chat
  Future<List<ChatSession>> getChatSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyChatSessions) ?? [];
      final List<ChatSession> result = [];
      for (final item in raw) {
        try {
          result.add(ChatSession.fromJson(jsonDecode(item)));
        } catch (_) {}
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChatSession(ChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyChatSessions) ?? [];
      final list = List<String>.from(raw);
      final index = list.indexWhere((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded['id'] == session.id;
        } catch (_) {
          return false;
        }
      });
      if (index >= 0) {
        list[index] = jsonEncode(session.toJson());
      } else {
        list.add(jsonEncode(session.toJson()));
      }
      await prefs.setStringList(_keyChatSessions, list);
    } catch (_) {}
  }

  Future<void> deleteChatSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_keyChatSessions) ?? [];
      final list = List<String>.from(raw);
      list.removeWhere((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded['id'] == sessionId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_keyChatSessions, list);
    } catch (_) {}
  }

  Future<bool> hasReviewedBooking(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('havenly_reviewed_$bookingId') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setReviewedBooking(String bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('havenly_reviewed_$bookingId', true);
    } catch (_) {}
  }
  static const String _keyBookedSchedules = 'mindpal_booked_schedules_';

  Future<void> addBookedSchedule(String psychologistId, String schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyBookedSchedules$psychologistId';
      final list = prefs.getStringList(key) ?? [];
      if (!list.contains(schedule)) {
        list.add(schedule);
        await prefs.setStringList(key, list);
      }
    } catch (_) {}
  }

  Future<void> syncBookedSchedules(String psychologistId, List<String> schedules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyBookedSchedules$psychologistId';
      await prefs.setStringList(key, schedules);
    } catch (_) {}
  }

  Future<void> clearBookedSchedules([String? psychologistId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (psychologistId != null) {
        await prefs.remove('$_keyBookedSchedules$psychologistId');
      } else {
        final keys = prefs.getKeys().where((k) => k.startsWith(_keyBookedSchedules));
        for (final k in keys) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}
  }

  Future<List<String>> getBookedSchedules(String psychologistId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyBookedSchedules$psychologistId';
      return prefs.getStringList(key) ?? [];
    } catch (_) {
      return [];
    }
  }

  // FR-04: Panic Clear Data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
