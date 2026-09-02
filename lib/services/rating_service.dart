import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _sgpaClickCountKey = 'sgpa_calc_click_count';

  /// Call this whenever an SGPA calculation is performed.
  /// Triggers Google Play In-App Review at 15 total clicks, and every 30 clicks after that (15, 45, 75, 105, etc.).
  Future<void> onSgpaCalculationDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(_sgpaClickCountKey) ?? 0;
      currentCount++;
      await prefs.setInt(_sgpaClickCountKey, currentCount);

      debugPrint("RatingService: SGPA Calculation count is $currentCount");

      // Trigger condition: at exactly 15 clicks, then at 45, 75, 105, 135...
      if (currentCount == 15 || (currentCount > 15 && (currentCount - 15) % 30 == 0)) {
        debugPrint("RatingService: Triggering Google Play In-App Review (Count: $currentCount)");
        await requestInAppReview();
      }
    } catch (e) {
      debugPrint("RatingService onSgpaCalculationDone error: $e");
    }
  }

  /// Triggers Google Play's official native in-app review bottom sheet
  Future<void> requestInAppReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint("RatingService requestInAppReview error: $e");
    }
  }

  /// Directly opens the Google Play Store app listing page (for the Profile Screen "Rate on Play Store" button)
  Future<void> openPlayStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      debugPrint("RatingService openPlayStoreListing error: $e");
    }
  }
}
