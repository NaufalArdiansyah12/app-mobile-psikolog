import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class StorageService {
  static const String _keyUserUuid = 'mindpal_user_uuid';
  static const String _keyNickname = 'mindpal_user_nickname';
  static const String _keyPin = 'mindpal_security_pin';
  static const String _keyMoods = 'mindpal_local_moods';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // FR-01: Zero-KYC Random UUID
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
    return prefs.getString(_keyNickname) ?? 'Sobat MindPal';
  }

  Future<void> setNickname(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, name);
  }

  // FR-03: Local PIN Protection
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyPin);
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
  Future<List<MoodEntry>> getMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyMoods) ?? [];
    return raw.map((item) => MoodEntry.fromJson(jsonDecode(item))).toList();
  }

  Future<void> saveMood(MoodEntry mood) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyMoods) ?? [];
    list.add(jsonEncode(mood.toJson()));
    await prefs.setStringList(_keyMoods, list);
  }

  // FR-04: Panic Clear Data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
