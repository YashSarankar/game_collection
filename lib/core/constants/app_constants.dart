/// App-wide constants for configuration and settings
class AppConstants {
  // App Info
  static const String appName = 'SnapPlay';
  static const String appSubtitle = 'OFFLINE COLLECTION';
  static const String packageName = 'com.offlinegames.collection';

  // Ad Configuration
  static const Duration adCooldownDuration = Duration(minutes: 2);
  static const Duration initialAdDelay = Duration(seconds: 30);
  static const int maxInterstitialAdsPerSession = 10;

  // Game Configuration
  static const int targetFPS = 60;
  static const bool enableHapticFeedback = true;
  static const bool enableSoundEffects = true;

  // Daily Rewards
  static const int dailyRewardCoins = 100;
  static const Duration dailyRewardCooldown = Duration(hours: 24);

  // Storage Keys
  static const String keyHighScores = 'high_scores';
  static const String keyDailyRewardLastClaimed = 'daily_reward_last_claimed';
  static const String keyTotalCoins = 'total_coins';
  static const String keyLastInterstitialAdTime = 'last_interstitial_ad_time';
  static const String keyAdCount = 'ad_count';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAppLaunchTime = 'app_launch_time';
}
