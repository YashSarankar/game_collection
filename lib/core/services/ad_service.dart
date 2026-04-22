import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:game_collection/core/services/storage_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AdService {
  static AdService? _instance;
  late final StorageService _storage;

  AdService._();

  static Future<AdService> getInstance() async {
    if (_instance == null) {
      _instance = AdService._();
      _instance!._storage = await StorageService.getInstance();
      await _instance!._init();
    }
    return _instance!;
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  DateTime? _lastInterstitialTime;
  int _gamesPlayedThisSession = 0;

  Future<void> _init() async {
    if (Platform.isIOS) {
      // Request tracking authorization for iOS 14.5+
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  // ... (Banner getters and method can remain or be removed, keeping getters for safety)

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      if (kReleaseMode) {
        return 'ca-app-pub-9441953606119572/9508534984'; // Real Home_Banner
      } else {
        return 'ca-app-pub-3940256099942544/6300978111'; // Sample Android Banner
      }
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Sample iOS Banner
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (kReleaseMode) {
        return 'ca-app-pub-9441953606119572/7373326237'; // Real Game_Exit_Interstitial
      } else {
        return 'ca-app-pub-3940256099942544/1033173712'; // Sample Android Interstitial
      }
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Sample iOS Interstitial
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Helper to load interstitial
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!
              .fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              debugPrint('$ad onAdDismissedFullScreenContent.');
              ad.dispose();
              _loadInterstitialAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
                  debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
                  ad.dispose();
                  _loadInterstitialAd(); // Reload for next time
                },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Implements "Engagement Based" Logic:
  /// 1. No ads in first 2 sessions.
  /// 2. Frequency cap: Show ad after every 3 games played.
  bool get _shouldShowAd {
    // --- TEMPORARY TEST MODE ---
    bool isTesting = false;
    if (isTesting) return true;

    // RULE 0: Permanent Ad Removal
    if (_storage.isAdsRemoved()) {
      debugPrint('Ad blocked: User has purchased Remove Ads');
      return false;
    }

    final sessionCount = _storage.getSessionCount();

    // RULE 1: First session is ad-free for better retention
    if (sessionCount <= 1) {
      debugPrint('Ad blocked: User in session $sessionCount (First session buffer)');
      return false;
    }

    // RULE 2: Sweet Spot Frequency (Every 2 games)
    if (_gamesPlayedThisSession < 2) {
      debugPrint('Ad blocked: Only $_gamesPlayedThisSession game(s) played (Need 2)');
      return false;
    }

    return true;
  }

  /// Public check to see if ads should be shown
  bool get shouldShowAds => _shouldShowAd;

  /// Call this whenever a game is finished
  void recordGamePlayed() {
    _gamesPlayedThisSession++;
    debugPrint('Games played this session: $_gamesPlayedThisSession');
  }

  void showInterstitialAd() {
    if (!_shouldShowAd) return;

    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _lastInterstitialTime = DateTime.now();
      _gamesPlayedThisSession = 0; // Reset counter after showing ad
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    } else {
      debugPrint('Interstitial ad not ready yet.');
      _loadInterstitialAd();
    }
  }
}
