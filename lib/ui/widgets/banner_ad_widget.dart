import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isAdFailed = false;
  late AdService _adService;
  AdSize? _adSize;
  int _retryAttempts = 0;
  Timer? _refreshTimer;
  double? _lastWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBanner();

    // Periodically check if we can show ads now (e.g. if the 5-min buffer ended)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isLoaded && !_isAdFailed) {
        _initBanner();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload ad when returning to app to ensure freshness
    if (state == AppLifecycleState.resumed && _isAdFailed) {
      _retryAttempts = 0;
      _initBanner();
    }
  }

  Future<void> _initBanner() async {
    _adService = await AdService.getInstance();
    if (_adService.shouldShowAds) {
      if (!mounted) return;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    final double width = MediaQuery.of(context).size.width;

    // Don't reload if width hasn't changed significantly (prevents flickering)
    if (_isLoaded && _lastWidth == width) return;
    _lastWidth = width;

    // Get adaptive size for the current screen width
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          width.truncate(),
        );

    if (size == null) {
      _loadStandardBanner();
      return;
    }

    _adSize = size;

    // Dispose old ad before creating a new one
    await _bannerAd?.dispose();

    _bannerAd = BannerAd(
      adUnitId: _adService.bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded: ${ad.adUnitId}');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isAdFailed = false;
              _retryAttempts = 0;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load ($err). Retry: $_retryAttempts');
          ad.dispose();
          _bannerAd = null;

          if (mounted) {
            setState(() {
              _isLoaded = false;
              _isAdFailed = true;
            });

            // Retry with exponential backoff (max 3 times, up to 1 minute)
            if (_retryAttempts < 3) {
              _retryAttempts++;
              Future.delayed(Duration(seconds: _retryAttempts * 20), () {
                if (mounted) _initBanner();
              });
            }
          }
        },
      ),
    )..load();
  }

  void _loadStandardBanner() {
    _adSize = AdSize.banner;
    _bannerAd = BannerAd(
      adUnitId: _adService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isAdFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          if (mounted) setState(() => _isAdFailed = true);
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    // If orientation changes, check if we need to reload the adaptive banner
    final double currentWidth = MediaQuery.of(context).size.width;
    if (_lastWidth != null && (currentWidth - _lastWidth!).abs() > 20) {
      // Small delay to allow layout to settle
      Future.microtask(() => _loadAd());
    }

    if (_isLoaded && _bannerAd != null && _adSize != null) {
      return Container(
        alignment: Alignment.center,
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Return a small space while loading, but nothing if failed after retries
    return (_isAdFailed && _retryAttempts >= 3)
        ? const SizedBox.shrink()
        : const SizedBox(height: 50);
  }
}
