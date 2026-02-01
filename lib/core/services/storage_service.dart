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
  Future<int> getTotalCoins() async {
    return _prefs?.getInt(AppConstants.keyTotalCoins) ?? 0;
  }

  Future<bool> addCoins(int amount) async {
    final current = await getTotalCoins();
    return await _prefs?.setInt(AppConstants.keyTotalCoins, current + amount) ??
        false;
  }

  Future<bool> spendCoins(int amount) async {
    final current = await getTotalCoins();
    if (current >= amount) {
      return await _prefs?.setInt(
            AppConstants.keyTotalCoins,
            current - amount,
          ) ??
          false;
    }
    return false;
  }

  // Daily Reward
  Future<DateTime?> getLastDailyRewardClaim() async {
    final int? timestamp = _prefs?.getInt(
      AppConstants.keyDailyRewardLastClaimed,
    );
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<bool> setDailyRewardClaimed() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _prefs?.setInt(AppConstants.keyDailyRewardLastClaimed, now) ??
        false;
  }

  Future<bool> canClaimDailyReward() async {
    final lastClaim = await getLastDailyRewardClaim();
    if (lastClaim == null) return true;

    final difference = DateTime.now().difference(lastClaim);
    return difference >= AppConstants.dailyRewardCooldown;
  }

  Future<DateTime?> getAppLaunchTime() async {
    final int? timestamp = _prefs?.getInt(AppConstants.keyAppLaunchTime);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<bool> setAppLaunchTime() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return await _prefs?.setInt(AppConstants.keyAppLaunchTime, now) ?? false;
  }

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
