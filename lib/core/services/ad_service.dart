import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

/// Centralized Ad Service for managing all ad operations
class AdService {
  static AdService? _instance;
  final StorageService _storage;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  AdService._(this._storage);

  static Future<AdService> getInstance() async {
    if (_instance == null) {
      final storage = await StorageService.getInstance();
      _instance = AdService._(storage);
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    // Ads disabled by user request
    // await MobileAds.instance.initialize();
    // _loadBannerAd();
    // _loadInterstitialAd();
    // _loadRewardedAd();
  }

  // Ad Unit IDs - REPLACE WITH YOUR ACTUAL AD UNIT IDs
  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      // Test Ad Unit ID - Replace with your actual ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Test Ad Unit ID - Replace with your actual ID
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      // Test Ad Unit ID - Replace with your actual ID
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Banner Ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          // Retry loading after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            _loadBannerAd();
          });
        },
      ),
    );
    _bannerAd?.load();
  }

  BannerAd? getBannerAd() {
    return _isBannerAdLoaded ? _bannerAd : null;
  }

  // Interstitial Ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  _loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          // Retry loading after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  Future<bool> showInterstitialAd() async {
    // Check if app was launched recently (within 30 seconds)
    final launchTime = await _storage.getAppLaunchTime();
    if (launchTime != null) {
      final timeSinceLaunch = DateTime.now().difference(launchTime);
      if (timeSinceLaunch < AppConstants.initialAdDelay) {
        return false;
      }
    }

    // Check cooldown
    final lastAdTime = await _storage.getLastInterstitialAdTime();
    if (lastAdTime != null) {
      final timeSinceLastAd = DateTime.now().difference(lastAdTime);
      if (timeSinceLastAd < AppConstants.adCooldownDuration) {
        return false;
      }
    }

    // Check ad count limit
    final adCount = await _storage.getAdCount();
    if (adCount >= AppConstants.maxInterstitialAdsPerSession) {
      return false;
    }

    // Show ad if loaded
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd?.show();
      await _storage.setLastInterstitialAdTime();
      await _storage.incrementAdCount();
      return true;
    }

    return false;
  }

  // Rewarded Ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;

          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          // Retry loading after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            _loadRewardedAd();
          });
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
  }) async {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward(reward);
        },
      );
      return true;
    }
    return false;
  }

  bool get isRewardedAdReady => _isRewardedAdLoaded;

  // Dispose
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
