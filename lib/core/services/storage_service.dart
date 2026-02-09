import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Service for managing local storage operations
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // High Scores
  Future<int> getHighScore(String gameId) async {
    final scores = await getAllHighScores();
    return scores[gameId] ?? 0;
  }

  Future<Map<String, int>> getAllHighScores() async {
    final String? scoresJson = _prefs?.getString(AppConstants.keyHighScores);
    if (scoresJson == null) return {};

    try {
      final Map<String, dynamic> decoded = json.decode(scoresJson);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  Future<bool> saveHighScore(String gameId, int score) async {
    final scores = await getAllHighScores();
    final currentHigh = scores[gameId] ?? 0;

    if (score > currentHigh) {
      scores[gameId] = score;
      final String scoresJson = json.encode(scores);
      return await _prefs?.setString(AppConstants.keyHighScores, scoresJson) ??
          false;
    }
    return false;
  }

  // Coins
  // REMOVED: Coins system removed from app

  // Daily Reward
  // REMOVED: Daily rewards system removed from app

  // Settings
  Future<bool> getSoundEnabled() async {
    return _prefs?.getBool(AppConstants.keySoundEnabled) ?? true;
  }

  Future<bool> setSoundEnabled(bool enabled) async {
    return await _prefs?.setBool(AppConstants.keySoundEnabled, enabled) ??
        false;
  }

  Future<bool> getVibrationEnabled() async {
    return _prefs?.getBool(AppConstants.keyVibrationEnabled) ?? true;
  }

  Future<bool> setVibrationEnabled(bool enabled) async {
    return await _prefs?.setBool(AppConstants.keyVibrationEnabled, enabled) ??
        false;
  }

  Future<String> getThemeMode() async {
    return _prefs?.getString(AppConstants.keyThemeMode) ?? 'system';
  }

  Future<bool> setThemeMode(String mode) async {
    return await _prefs?.setString(AppConstants.keyThemeMode, mode) ?? false;
  }

  // Clear all data
  Future<bool> clearAllData() async {
    return await _prefs?.clear() ?? false;
  }
}
