/// App-wide constants for configuration and settings
class AppConstants {
  // App Info
  static const String appName = 'SnapPlay';
  static const String appSubtitle = 'OFFLINE COLLECTION';
  static const String packageName = 'com.snapplay.offline.games';

  // Daily Rewards
  static const int dailyRewardCoins = 100;
  static const Duration dailyRewardCooldown = Duration(hours: 24);

  // Storage Keys
  static const String keyHighScores = 'high_scores';
  static const String keyDailyRewardLastClaimed = 'daily_reward_last_claimed';
  static const String keyTotalCoins = 'total_coins';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAppLaunchTime = 'app_launch_time';
}
