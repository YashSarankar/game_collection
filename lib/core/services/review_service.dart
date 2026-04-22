import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'storage_service.dart';

class ReviewService {
  static ReviewService? _instance;
  final InAppReview _inAppReview = InAppReview.instance;
  late final StorageService _storage;

  ReviewService._();

  static Future<ReviewService> getInstance() async {
    if (_instance == null) {
      _instance = ReviewService._();
      _instance!._storage = await StorageService.getInstance();
    }
    return _instance!;
  }

  /// The "Smart Trigger" logic:
  /// 1. Check if the device supports in-app reviews.
  /// 2. Check if at least 3 sessions have passed.
  /// 3. Check if at least 30 days have passed since the last request.
  Future<void> requestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) return;

      final sessionCount = _storage.getSessionCount();
      final lastRequest = _storage.getLastReviewRequest();
      final now = DateTime.now();

      // --- TEMPORARY TEST MODE ---
      bool isTesting = false;
      if (!isTesting) {
        // Rule 1: Wait for at least 3 sessions
        if (sessionCount < 3) {
          debugPrint('Review blocked: Only session $sessionCount');
          return;
        }

        // Rule 2: Frequency capping (30 days between requests)
        if (lastRequest != null) {
          final daysSinceLast = now.difference(lastRequest).inDays;
          if (daysSinceLast < 30) {
            debugPrint('Review blocked: Only $daysSinceLast days since last request');
            return;
          }
        }
      }

      // If all rules pass, show the review popup
      debugPrint('Triggering In-App Review!');
      await _inAppReview.requestReview();
      
      // Update the last request time
      await _storage.setLastReviewRequest(now);
      
    } catch (e) {
      debugPrint('Error requesting review: $e');
    }
  }

  /// Force a review request (e.g., from a "Rate Us" button in settings)
  Future<void> forceReview() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      // Fallback: Open Play Store page directly
      await _inAppReview.openStoreListing();
    }
  }
}
