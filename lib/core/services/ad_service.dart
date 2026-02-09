import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static AdService? _instance;

  AdService._();

  static Future<AdService> getInstance() async {
    if (_instance == null) {
      _instance = AdService._();
      await _instance!._init();
    }
    return _instance!;
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  Future<void> _init() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  // ... (Banner getters and method can remain or be removed, keeping getters for safety)

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (kReleaseMode) {
        return 'ca-app-pub-5747718526576102/1274647391';
      } else {
        return 'ca-app-pub-3940256099942544/1033173712'; // Test Android Interstitial
      }
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
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

  void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    } else {
      debugPrint('Interstitial ad not ready yet.');
      _loadInterstitialAd(); // Attempt to load if not ready
    }
  }
}
