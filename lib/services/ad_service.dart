import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/notifications/domain/notification_preferences.dart';
import 'analytics_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  // Remote Config Dynamic States
  bool _isAdsGloballyEnabled = true;
  bool _isAppOpenEnabled = true;
  bool _isRewardedTimetableEnabled = true;
  bool _isInterstitialSgpaEnabled = true;
  bool _isBannerEnabled = true;
  bool _isNativeAdsEnabled = true;
  bool _isExamMode = false;

  int _sgpaClickThreshold = 10;
  int _appOpenCooldownHours = 4;
  int _appOpenAttemptThreshold = 2;
  int _timetablePassDays = 3;
  int _nativeAdInterval = 4;
  int _sgpaNativeInterval = 2;

  String? _remoteRewardedAdId;
  String? _remoteInterstitialAdId;
  String? _remoteBannerAdId;
  String? _remoteAppOpenAdId;
  String? _remoteNativeAdId;

  Map<String, bool> _nativePlacements = {
    'home_below_most_imp': true,
    'home_below_recent_files': true,
    'services_below_codeforces': true,
    'updates_below_latest': true,
    'subjects_in_between': true,
    'pyq_papers_in_between': true,
    'notes_folders_in_between': true,
    'notes_materials_in_between': true,
    'notifications_below_reminders': true,
    'sgpa_in_between_subjects': true,
    'timetable_below_full_schedule': true,
  };

  Map<String, bool> _bannerPlacements = {
    'home_below_semester_progress': true,
    'notes_screen': true,
    'pyq_screen': true,
    'most_imp_screen': true,
    'sgpa_calculator': true,
    'notification_settings': true,
    'notifications_screen': true,
    'help_center': true,
    'university_updates': true,
    'lost_and_found': true,
    'coding_leaderboard': true,
  };

  // Timetable notification unlock keys
  static const String _keyTimetableUnlockedUntil = 'timetable_notifications_unlocked_until';
  static const String _keyAppOpenLastShownAt = 'app_open_last_shown_timestamp';
  static const String _keyAppOpenLaunchCount = 'app_open_launch_attempt_count';
  static const String _keySgpaCalculationAdClicks = 'sgpa_calc_ad_clicks';

  // Getters for public state
  bool get isAdsGloballyEnabled => _isAdsGloballyEnabled && !_isExamMode;
  bool get isBannerEnabled => _isAdsGloballyEnabled && _isBannerEnabled;
  bool get isNativeAdsEnabled => _isAdsGloballyEnabled && _isNativeAdsEnabled && !_isExamMode;
  bool get isRewardedTimetableEnabled => _isAdsGloballyEnabled && _isRewardedTimetableEnabled && !_isExamMode;
  bool get isTimetableAdRequired => _isAdsGloballyEnabled && _isRewardedTimetableEnabled && !_isExamMode;
  int get timetablePassDays => _timetablePassDays;
  int get nativeAdInterval => _nativeAdInterval > 0 ? _nativeAdInterval : 4;
  int get sgpaNativeInterval => _sgpaNativeInterval > 0 ? _sgpaNativeInterval : 2;

  /// Check if a specific native ad placement is active
  bool isNativePlacementEnabled(String placementKey) {
    if (!_isAdsGloballyEnabled || !_isNativeAdsEnabled || _isExamMode) return false;
    return _nativePlacements[placementKey] ?? true;
  }

  /// Check if a specific banner ad placement is active
  bool isBannerPlacementEnabled(String placementKey) {
    if (!_isAdsGloballyEnabled || !_isBannerEnabled || _isExamMode) return false;
    if (placementKey == 'default') return true;
    return _bannerPlacements[placementKey] ?? true;
  }

  // AdMob Ad Unit IDs (Google Official Test IDs in Debug Mode, Production IDs in Release Mode)
  String get rewardedAdUnitId {
    if (_remoteRewardedAdId != null && _remoteRewardedAdId!.isNotEmpty) {
      return _remoteRewardedAdId!;
    }
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Official Google Test Rewarded Ad
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8688840473183021/6196767868'
        : 'ca-app-pub-3940256099942544/1712485313';
  }

  String get interstitialAdUnitId {
    if (_remoteInterstitialAdId != null && _remoteInterstitialAdId!.isNotEmpty) {
      return _remoteInterstitialAdId!;
    }
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Official Google Test Interstitial Ad
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8688840473183021/8796218924'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  static String get bannerAdUnitId {
    final s = AdService();
    if (s._remoteBannerAdId != null && s._remoteBannerAdId!.isNotEmpty) {
      return s._remoteBannerAdId!;
    }
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Official Google Test Banner Ad
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8688840473183021/2182709116'
        : 'ca-app-pub-3940256099942544/2934735716';
  }

  String get appOpenAdUnitId {
    if (_remoteAppOpenAdId != null && _remoteAppOpenAdId!.isNotEmpty) {
      return _remoteAppOpenAdId!;
    }
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/9257390408'; // Official Google Test App Open Ad
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8688840473183021/2171104393'
        : 'ca-app-pub-3940256099942544/5662855259';
  }

  static String get nativeAdUnitId {
    final s = AdService();
    if (s._remoteNativeAdId != null && s._remoteNativeAdId!.isNotEmpty) {
      return s._remoteNativeAdId!;
    }
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/2247696110'; // Official Google Test Native Ad
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8688840473183021/9105117757'
        : 'ca-app-pub-3940256099942544/3986624511';
  }

  // Preloaded Ads Cache
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdLoading = false;

  /// Automatically grants a 24-hour free welcome pass for new signups or migrating students
  static Future<void> checkAndGrantFirstTimeWelcomePass() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final userWelcomeKey = 'welcome_pass_granted_${user.id}';
      final hasReceivedWelcome = prefs.getBool(userWelcomeKey) ?? false;
      
      // Also check remote user_timetable_passes in Supabase
      bool hasRemotePass = false;
      DateTime? remoteExpiry;
      try {
        final configRow = await Supabase.instance.client
            .from('app_config')
            .select('value')
            .eq('key', 'user_timetable_passes')
            .maybeSingle();
        if (configRow != null && configRow['value'] != null) {
          final raw = configRow['value'];
          final passesMap = raw is Map
              ? Map<String, dynamic>.from(raw)
              : (raw is String ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : {});
          if (passesMap.containsKey(user.id)) {
            hasRemotePass = true;
            final userPass = passesMap[user.id];
            if (userPass is Map && userPass['pass_expires_at'] != null) {
              remoteExpiry = DateTime.tryParse(userPass['pass_expires_at'].toString());
            }
          }
        }
      } catch (_) {}

      final now = DateTime.now();

      // If user has not received welcome pass and has no valid pass record in Supabase:
      if (!hasReceivedWelcome && (!hasRemotePass || remoteExpiry == null)) {
        final welcomeExpiry = now.add(const Duration(hours: 24));
        await prefs.setString(_keyTimetableUnlockedUntil, welcomeExpiry.toIso8601String());
        await prefs.setBool(userWelcomeKey, true);

        // Update in-memory cached pass status immediately
        _cachedPassStatus = TimetablePassStatus(
          isAdRequired: true,
          isUnlocked: true,
          remainingText: '24h left',
          expiresAt: welcomeExpiry,
        );

        debugPrint("AdService: 🎉 Granted 24-Hour Free Welcome Notification Pass for User ${user.id} (Expires: $welcomeExpiry)");

        // Ensure default settings are active
        final settings = await TimetableNotificationSettings.loadFromPrefs();
        if (!settings.isEnabled) {
          final newSettings = settings.copyWith(isEnabled: true);
          await newSettings.saveToPrefs();
        }

        // Sync to Supabase app_config user_timetable_passes
        await syncUserNotificationPassStatus(isEnabled: true);
      } else if (remoteExpiry != null) {
        // If remote pass exists, load remote expiry
        await prefs.setString(_keyTimetableUnlockedUntil, remoteExpiry.toIso8601String());
        await prefs.setBool(userWelcomeKey, true);
      }
    } catch (e) {
      debugPrint("AdService: checkAndGrantFirstTimeWelcomePass error: $e");
    }
  }

  /// Clears local user-scoped pass data when student logs out
  static Future<void> onSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTimetableUnlockedUntil);
      _cachedPassStatus = const TimetablePassStatus(
        isAdRequired: true,
        isUnlocked: false,
        remainingText: 'Expired',
      );
    } catch (_) {}
  }

  /// Initialize Mobile Ads SDK and check Supabase remote config
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      // 1. Load instantly from local cached prefs
      await _loadCachedConfig();

      await MobileAds.instance.initialize();
      if (kDebugMode) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['kGADSimulatorID'],
          ),
        );
      }
      _isInitialized = true;
      debugPrint("AdService: Google Mobile Ads initialized successfully in ${kDebugMode ? 'DEBUG TEST MODE' : 'RELEASE PROD MODE'}.");

      // 2. Fetch latest remote config from Supabase in background
      await _fetchRemoteConfig();

      // 3. Grant 24-hr welcome pass on first launch / transfer
      await checkAndGrantFirstTimeWelcomePass();

      // 4. Preload initial ads
      preloadRewardedAd();
      preloadInterstitialAd();
      preloadAppOpenAd();
    } catch (e) {
      debugPrint("AdService: Mobile Ads init failed: $e");
    }
  }

  Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('cached_ads_globally_enabled')) {
        _isAdsGloballyEnabled = prefs.getBool('cached_ads_globally_enabled') ?? true;
      }
      if (prefs.containsKey('cached_app_open_enabled')) {
        _isAppOpenEnabled = prefs.getBool('cached_app_open_enabled') ?? true;
      }
      if (prefs.containsKey('cached_rewarded_timetable_enabled')) {
        _isRewardedTimetableEnabled = prefs.getBool('cached_rewarded_timetable_enabled') ?? true;
      }
      if (prefs.containsKey('cached_rewarded_sgpa_enabled')) {
        _isInterstitialSgpaEnabled = prefs.getBool('cached_rewarded_sgpa_enabled') ?? true;
      } else if (prefs.containsKey('cached_interstitial_sgpa_enabled')) {
        _isInterstitialSgpaEnabled = prefs.getBool('cached_interstitial_sgpa_enabled') ?? true;
      }
      if (prefs.containsKey('cached_banner_enabled')) {
        _isBannerEnabled = prefs.getBool('cached_banner_enabled') ?? true;
      }
      if (prefs.containsKey('cached_native_enabled')) {
        _isNativeAdsEnabled = prefs.getBool('cached_native_enabled') ?? true;
      }
      if (prefs.containsKey('cached_native_interval')) {
        _nativeAdInterval = prefs.getInt('cached_native_interval') ?? 4;
      }
      if (prefs.containsKey('cached_sgpa_native_interval')) {
        _sgpaNativeInterval = prefs.getInt('cached_sgpa_native_interval') ?? 2;
      }
      if (prefs.containsKey('cached_native_placements')) {
        try {
          final str = prefs.getString('cached_native_placements');
          if (str != null) {
            final map = jsonDecode(str) as Map<String, dynamic>;
            _nativePlacements = map.map((k, v) => MapEntry(k, v == true));
          }
        } catch (_) {}
      }
      if (prefs.containsKey('cached_banner_placements')) {
        try {
          final str = prefs.getString('cached_banner_placements');
          if (str != null) {
            final map = jsonDecode(str) as Map<String, dynamic>;
            _bannerPlacements = map.map((k, v) => MapEntry(k, v == true));
          }
        } catch (_) {}
      }
      if (prefs.containsKey('cached_exam_mode')) {
        _isExamMode = prefs.getBool('cached_exam_mode') ?? false;
      }
      if (prefs.containsKey('cached_app_open_cooldown_hours')) {
        _appOpenCooldownHours = prefs.getInt('cached_app_open_cooldown_hours') ?? 4;
      }
      if (prefs.containsKey('cached_app_open_attempt_threshold')) {
        _appOpenAttemptThreshold = prefs.getInt('cached_app_open_attempt_threshold') ?? 2;
      }
      if (prefs.containsKey('cached_timetable_pass_days')) {
        _timetablePassDays = prefs.getInt('cached_timetable_pass_days') ?? 3;
      }
    } catch (_) {}
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'ads_settings')
          .maybeSingle();

      if (res != null && res['value'] != null) {
        final dynamic raw = res['value'];
        final Map<String, dynamic> val = raw is Map
            ? Map<String, dynamic>.from(raw)
            : (raw is String ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : {});

        if (val.containsKey('is_enabled')) {
          _isAdsGloballyEnabled = val['is_enabled'] == true || val['is_enabled'] == 'true';
        }
        if (val.containsKey('is_app_open_enabled')) {
          _isAppOpenEnabled = val['is_app_open_enabled'] == true || val['is_app_open_enabled'] == 'true';
        }
        if (val.containsKey('is_rewarded_timetable_enabled')) {
          _isRewardedTimetableEnabled = val['is_rewarded_timetable_enabled'] == true || val['is_rewarded_timetable_enabled'] == 'true';
        }
        if (val.containsKey('is_rewarded_sgpa_enabled')) {
          _isInterstitialSgpaEnabled = val['is_rewarded_sgpa_enabled'] == true || val['is_rewarded_sgpa_enabled'] == 'true';
        } else if (val.containsKey('is_interstitial_sgpa_enabled')) {
          _isInterstitialSgpaEnabled = val['is_interstitial_sgpa_enabled'] == true || val['is_interstitial_sgpa_enabled'] == 'true';
        }
        if (val.containsKey('is_banner_enabled')) {
          _isBannerEnabled = val['is_banner_enabled'] == true || val['is_banner_enabled'] == 'true';
        }
        if (val.containsKey('is_native_enabled')) {
          _isNativeAdsEnabled = val['is_native_enabled'] == true || val['is_native_enabled'] == 'true';
        }
        if (val.containsKey('native_ad_interval') && val['native_ad_interval'] is num) {
          _nativeAdInterval = (val['native_ad_interval'] as num).toInt();
        }
        if (val.containsKey('sgpa_native_interval') && val['sgpa_native_interval'] is num) {
          _sgpaNativeInterval = (val['sgpa_native_interval'] as num).toInt();
        }
        if (val.containsKey('native_placements') && val['native_placements'] is Map) {
          final pMap = val['native_placements'] as Map;
          _nativePlacements = pMap.map((k, v) => MapEntry(k.toString(), v == true || v == 'true'));
        }
        if (val.containsKey('banner_placements') && val['banner_placements'] is Map) {
          final bMap = val['banner_placements'] as Map;
          _bannerPlacements = bMap.map((k, v) => MapEntry(k.toString(), v == true || v == 'true'));
        }
        if (val.containsKey('is_exam_mode')) {
          _isExamMode = val['is_exam_mode'] == true || val['is_exam_mode'] == 'true';
        }

        if (val.containsKey('sgpa_click_threshold') && val['sgpa_click_threshold'] is num) {
          _sgpaClickThreshold = (val['sgpa_click_threshold'] as num).toInt();
        }
        if (val.containsKey('app_open_cooldown_hours') && val['app_open_cooldown_hours'] is num) {
          _appOpenCooldownHours = (val['app_open_cooldown_hours'] as num).toInt();
        }
        if (val.containsKey('app_open_attempt_threshold') && val['app_open_attempt_threshold'] is num) {
          _appOpenAttemptThreshold = (val['app_open_attempt_threshold'] as num).toInt();
        }
        if (val.containsKey('timetable_pass_days') && val['timetable_pass_days'] is num) {
          _timetablePassDays = (val['timetable_pass_days'] as num).toInt();
        }

        if (val['rewarded_ad_id'] is String && (val['rewarded_ad_id'] as String).isNotEmpty) {
          _remoteRewardedAdId = val['rewarded_ad_id'];
        }
        if (val['interstitial_ad_id'] is String && (val['interstitial_ad_id'] as String).isNotEmpty) {
          _remoteInterstitialAdId = val['interstitial_ad_id'];
        }
        if (val['banner_ad_id'] is String && (val['banner_ad_id'] as String).isNotEmpty) {
          _remoteBannerAdId = val['banner_ad_id'];
        }
        if (val['native_ad_id'] is String && (val['native_ad_id'] as String).isNotEmpty) {
          _remoteNativeAdId = val['native_ad_id'];
        }
        if (val['app_open_ad_id'] is String && (val['app_open_ad_id'] as String).isNotEmpty) {
          _remoteAppOpenAdId = val['app_open_ad_id'];
        }

        // Cache to local prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('cached_ads_globally_enabled', _isAdsGloballyEnabled);
        await prefs.setBool('cached_app_open_enabled', _isAppOpenEnabled);
        await prefs.setBool('cached_rewarded_timetable_enabled', _isRewardedTimetableEnabled);
        await prefs.setBool('cached_rewarded_sgpa_enabled', _isInterstitialSgpaEnabled);
        await prefs.setBool('cached_interstitial_sgpa_enabled', _isInterstitialSgpaEnabled);
        await prefs.setBool('cached_banner_enabled', _isBannerEnabled);
        await prefs.setBool('cached_native_enabled', _isNativeAdsEnabled);
        await prefs.setInt('cached_native_interval', _nativeAdInterval);
        await prefs.setInt('cached_sgpa_native_interval', _sgpaNativeInterval);
        await prefs.setString('cached_native_placements', jsonEncode(_nativePlacements));
        await prefs.setString('cached_banner_placements', jsonEncode(_bannerPlacements));
        await prefs.setBool('cached_exam_mode', _isExamMode);
        await prefs.setInt('cached_app_open_cooldown_hours', _appOpenCooldownHours);
        await prefs.setInt('cached_app_open_attempt_threshold', _appOpenAttemptThreshold);
        await prefs.setInt('cached_timetable_pass_days', _timetablePassDays);

        debugPrint("AdService: Remote config applied & cached successfully. (Global: $_isAdsGloballyEnabled, Native: $_isNativeAdsEnabled, AppOpen: $_isAppOpenEnabled, Cooldown: ${_appOpenCooldownHours}h)");
      }
    } catch (e) {
      debugPrint("AdService: Remote config fetch skipped: $e");
    }
  }

  // =========================================================================
  // 1️⃣ REWARDED AD: TIMETABLE NOTIFICATION UNLOCK
  // =========================================================================

  /// Checks if timetable notification schedule is currently unlocked
  static Future<bool> isTimetableNotificationUnlocked() async {
    try {
      final s = AdService();
      await s._loadCachedConfig();
      await s._fetchRemoteConfig();
      if (!s.isTimetableAdRequired) {
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final unlockStr = prefs.getString(_keyTimetableUnlockedUntil);
      if (unlockStr == null || unlockStr.isEmpty) return false;

      final expiry = DateTime.tryParse(unlockStr);
      if (expiry == null) return false;

      // Clean up stale >14 day values from older versions
      if (expiry.difference(DateTime.now()).inDays > 14) {
        final newExpiry = DateTime.now().add(const Duration(hours: 24));
        await prefs.setString(_keyTimetableUnlockedUntil, newExpiry.toIso8601String());
        return true;
      }

      return DateTime.now().isBefore(expiry);
    } catch (e) {
      debugPrint("AdService: isTimetableNotificationUnlocked error: $e");
      return true; // fail-open for user convenience
    }
  }

  /// Formatted time string remaining until timetable pass expiration
  static Future<String> getTimetableUnlockRemainingText() async {
    try {
      final s = AdService();
      await s._loadCachedConfig();
      await s._fetchRemoteConfig();
      if (!s.isTimetableAdRequired) return "Active (Free Mode)";

      final prefs = await SharedPreferences.getInstance();
      final unlockStr = prefs.getString(_keyTimetableUnlockedUntil);
      if (unlockStr == null) return "Expired";

      final expiry = DateTime.tryParse(unlockStr);
      if (expiry == null || DateTime.now().isAfter(expiry)) return "Expired";

      final diff = expiry.difference(DateTime.now());
      if (diff.inDays >= 1) {
        return "${diff.inDays}d ${diff.inHours % 24}h remaining";
      } else if (diff.inHours >= 1) {
        return "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
      } else {
        return "${diff.inMinutes}m remaining";
      }
    } catch (_) {
      return "Expired";
    }
  }

  static TimetablePassStatus _cachedPassStatus = const TimetablePassStatus(
    isAdRequired: false,
    isUnlocked: true,
    remainingText: '',
  );

  /// Synchronous in-memory pass status for instant 0ms UI rendering
  static TimetablePassStatus getCachedPassStatus() => _cachedPassStatus;

  /// Real-time pass status evaluation with remote synchronization
  static Future<TimetablePassStatus> getTimetablePassStatus({bool forceRemote = false}) async {
    try {
      final s = AdService();
      await s._loadCachedConfig();

      // Fetch remote config and user overrides directly
      try {
        await s._fetchRemoteConfig();
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final configRow = await Supabase.instance.client
              .from('app_config')
              .select('value')
              .eq('key', 'user_timetable_passes')
              .maybeSingle();

          if (configRow != null && configRow['value'] != null) {
            final raw = configRow['value'];
            final passesMap = raw is Map
                ? Map<String, dynamic>.from(raw)
                : (raw is String ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : {});
            if (passesMap.containsKey(user.id)) {
              final userPass = passesMap[user.id];
              if (userPass is Map && userPass['pass_expires_at'] != null) {
                final remoteExpiry = DateTime.tryParse(userPass['pass_expires_at'].toString());
                if (remoteExpiry != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(_keyTimetableUnlockedUntil, remoteExpiry.toIso8601String());
                }
              }
            } else {
              // Account has no pass record in Supabase yet -> Grant 24h welcome pass!
              await checkAndGrantFirstTimeWelcomePass();
            }
          } else {
            await checkAndGrantFirstTimeWelcomePass();
          }
        }
      } catch (_) {}

      if (!s.isTimetableAdRequired) {
        _cachedPassStatus = const TimetablePassStatus(
          isAdRequired: false,
          isUnlocked: true,
          remainingText: '',
        );
        return _cachedPassStatus;
      }

      final prefs = await SharedPreferences.getInstance();
      final unlockStr = prefs.getString(_keyTimetableUnlockedUntil);

      if (unlockStr == null || unlockStr.isEmpty) {
        _cachedPassStatus = const TimetablePassStatus(
          isAdRequired: true,
          isUnlocked: false,
          remainingText: 'Expired',
        );
      } else {
        final expiry = DateTime.tryParse(unlockStr);
        if (expiry == null || DateTime.now().isAfter(expiry)) {
          _cachedPassStatus = TimetablePassStatus(
            isAdRequired: true,
            isUnlocked: false,
            remainingText: 'Expired',
            expiresAt: expiry,
          );
        } else {
          final diff = expiry.difference(DateTime.now());
          String text;
          if (diff.inDays >= 1) {
            text = "${diff.inDays}d ${diff.inHours % 24}h left";
          } else if (diff.inHours >= 1) {
            text = "${diff.inHours}h ${diff.inMinutes % 60}m left";
          } else {
            text = "${diff.inMinutes}m left";
          }

          _cachedPassStatus = TimetablePassStatus(
            isAdRequired: true,
            isUnlocked: true,
            remainingText: text,
            expiresAt: expiry,
          );
        }
      }

      return _cachedPassStatus;
    } catch (_) {
      return _cachedPassStatus;
    }
  }

  /// Extends the timetable notification unlock by configured days
  static Future<void> grantTimetable3DayUnlock() async {
    try {
      final s = AdService();
      final days = s.timetablePassDays > 0 ? s.timetablePassDays : 3;
      final prefs = await SharedPreferences.getInstance();
      
      DateTime baseDate = DateTime.now();
      final currentUnlock = prefs.getString(_keyTimetableUnlockedUntil);
      if (currentUnlock != null) {
        final existingExpiry = DateTime.tryParse(currentUnlock);
        if (existingExpiry != null && existingExpiry.isAfter(DateTime.now())) {
          baseDate = existingExpiry;
        }
      }

      final newExpiry = baseDate.add(Duration(days: days));
      await prefs.setString(_keyTimetableUnlockedUntil, newExpiry.toIso8601String());

      // Update in-memory cached pass status immediately for instant 0ms UI reactivity
      final diff = newExpiry.difference(DateTime.now());
      String text;
      if (diff.inDays >= 1) {
        text = "${diff.inDays}d ${diff.inHours % 24}h left";
      } else if (diff.inHours >= 1) {
        text = "${diff.inHours}h ${diff.inMinutes % 60}m left";
      } else {
        text = "${diff.inMinutes}m left";
      }

      _cachedPassStatus = TimetablePassStatus(
        isAdRequired: true,
        isUnlocked: true,
        remainingText: text,
        expiresAt: newExpiry,
      );

      debugPrint("AdService: Timetable Notification pass extended to: $newExpiry (+$days days)");

      // Sync pass to Supabase
      await syncUserNotificationPassStatus();
    } catch (e) {
      debugPrint("AdService: grantTimetable3DayUnlock failed: $e");
    }
  }

  /// Syncs user's timetable notification status and pass expiry to Supabase
  static Future<void> syncUserNotificationPassStatus({
    bool? isEnabled,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final unlockStr = prefs.getString(_keyTimetableUnlockedUntil);
      final expiry = unlockStr != null ? DateTime.tryParse(unlockStr) : null;
      
      final s = AdService();
      final bool isAdReq = s.isTimetableAdRequired;
      final bool isPassActive = !isAdReq || (expiry != null && DateTime.now().isBefore(expiry));
      
      String passState;
      if (!isAdReq) {
        passState = 'FREE_MODE';
      } else if (isPassActive) {
        passState = 'ACTIVE';
      } else {
        passState = 'EXPIRED';
      }

      // Fetch profile details if available
      String fullName = '';
      String rollNo = '';
      String branch = '';
      try {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('full_name, roll_no, branch')
            .eq('id', user.id)
            .maybeSingle();
        if (profileRes != null) {
          fullName = profileRes['full_name'] ?? '';
          rollNo = profileRes['roll_no'] ?? '';
          branch = profileRes['branch'] ?? '';
        }
      } catch (_) {}

      // Save to app_config table key: user_timetable_passes
      try {
        final configRow = await Supabase.instance.client
            .from('app_config')
            .select('value')
            .eq('key', 'user_timetable_passes')
            .maybeSingle();

        Map<String, dynamic> currentPasses = {};
        if (configRow != null && configRow['value'] != null) {
          final raw = configRow['value'];
          currentPasses = raw is Map
              ? Map<String, dynamic>.from(raw)
              : (raw is String ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : {});
        }

        currentPasses[user.id] = {
          'pass_status': passState,
          'pass_expires_at': expiry?.toIso8601String(),
          'is_enabled': isEnabled ?? true,
          'user_name': fullName.isNotEmpty ? fullName : (user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? ''),
          'roll_no': rollNo,
          'branch': branch,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await Supabase.instance.client
            .from('app_config')
            .upsert({
              'key': 'user_timetable_passes',
              'value': currentPasses,
            }, onConflict: 'key');
        debugPrint("AdService: Synced user timetable notification status to app_config successfully.");
      } catch (e) {
        debugPrint("AdService: Sync user notification status skipped: $e");
      }
    } catch (e) {
      debugPrint("AdService: Sync user notification status skipped: $e");
    }
  }

  /// Preload Rewarded Video Ad
  void preloadRewardedAd() {
    if (!_isAdsGloballyEnabled || !_isRewardedTimetableEnabled || _isExamMode || _isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint("AdService: Rewarded Ad loaded successfully.");
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          debugPrint("AdService: Rewarded Ad failed to load: $error");
        },
      ),
    );
  }

  void _showNoAdsSnackBar(BuildContext? context, {String message = "⚠️ No ads available right now. Please try again later."}) {
    if (context == null || !context.mounted) return;
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {}
  }

  /// Show Rewarded Ad with custom callback on reward earned
  Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
    VoidCallback? onAdNotAvailable,
  }) async {
    if (!_isAdsGloballyEnabled || !_isRewardedTimetableEnabled || _isExamMode) {
      onRewardEarned();
      return;
    }

    if (_rewardedAd != null) {
      bool userEarnedReward = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          preloadRewardedAd();
          if (onAdClosed != null) onAdClosed();
          if (userEarnedReward) {
            onRewardEarned();
          } else {
            _showNoAdsSnackBar(context, message: "⚠️ Please complete the video to unlock your pass.");
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("AdService: Rewarded Ad failed to show: $error");
          ad.dispose();
          _rewardedAd = null;
          preloadRewardedAd();
          _showNoAdsSnackBar(context, message: "⚠️ No ads available right now. Please try again later.");
          if (onAdNotAvailable != null) onAdNotAvailable();
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint("AdService: Student earned reward: ${reward.amount} ${reward.type}");
          userEarnedReward = true;
          AnalyticsService.logAdEvent(
            adType: 'rewarded',
            placement: 'timetable_notification_pass',
            eventType: 'reward_earned',
          );
        },
      );
      AnalyticsService.logAdEvent(
        adType: 'rewarded',
        placement: 'timetable_notification_pass',
        eventType: 'impression',
      );
    } else {
      // Ad not loaded or unavailable (due to network, frequency capping, or ad limit)
      preloadRewardedAd();
      _showNoAdsSnackBar(context, message: "⚠️ No ads available right now. Please try again later.");
      if (onAdNotAvailable != null) onAdNotAvailable();
    }
  }

  // =========================================================================
  // 2️⃣ REWARDED & INTERSTITIAL AD: SGPA CALCULATOR
  // =========================================================================

  /// Preload Interstitial Ad (for backward compatibility)
  void preloadInterstitialAd() {
    if (!_isAdsGloballyEnabled || !_isInterstitialSgpaEnabled || _isExamMode || _isInterstitialAdLoading || _interstitialAd != null) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint("AdService: Interstitial Ad loaded.");
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
          debugPrint("AdService: Interstitial Ad failed to load: $error");
        },
      ),
    );
  }

  /// Processes SGPA calculation click with strict Anti-Bypass Protection.
  /// If the click reaches the threshold (e.g. 10th calculation):
  /// 1. Shows the Rewarded Ad FIRST.
  /// 2. Executes [onProceed] (which calculates, reveals, and persists the SGPA result) ONLY when the ad is completed/dismissed.
  /// 3. Resets the persistent click counter to 0 ONLY upon completion.
  /// If the user force-closes the app during the ad, the result was NEVER revealed, and the counter remains at the threshold (>=10).
  /// When they reopen and calculate, they will be required to watch the ad to unlock their result.
  Future<void> processSgpaCalculation({
    BuildContext? context,
    required Future<void> Function() onProceed,
  }) async {
    if (!_isAdsGloballyEnabled || !_isInterstitialSgpaEnabled || _isExamMode) {
      await onProceed();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      int currentClicks = prefs.getInt(_keySgpaCalculationAdClicks) ?? 0;
      currentClicks++;
      await prefs.setInt(_keySgpaCalculationAdClicks, currentClicks);

      final threshold = _sgpaClickThreshold > 0 ? _sgpaClickThreshold : 10;
      debugPrint("AdService: SGPA Calculation Persistent Click #$currentClicks (Threshold: $threshold)");

      if (currentClicks >= threshold) {
        if (_rewardedAd != null) {
          // Show rewarded ad BEFORE revealing the result
          await showSgpaRewardedAd(
            context: (context != null && context.mounted) ? context : null,
            onAdCompleted: () async {
              // 1. Reset persisted clicks ONLY upon completed ad view
              final p = await SharedPreferences.getInstance();
              await p.setInt(_keySgpaCalculationAdClicks, 0);
              debugPrint("AdService: SGPA Rewarded Ad completed. Click counter reset to 0.");
              // 2. Reveal and save the calculation result
              await onProceed();
            },
          );
        } else {
          // Ad was not ready yet / no fill
          preloadRewardedAd();
          if (context != null && context.mounted) {
            _showNoAdsSnackBar(context, message: "⚠️ No ads available right now. Please try again in a few moments.");
          }
        }
      } else {
        // Normal click (1..9) -> proceed immediately
        await onProceed();
      }
    } catch (e) {
      debugPrint("AdService processSgpaCalculation error: $e");
      await onProceed();
    }
  }

  /// Call this every time a student calculates an SGPA/SEE target (legacy wrapper).
  Future<void> recordSgpaCalculationClick() async {
    await processSgpaCalculation(onProceed: () async {});
  }

  /// Show Direct Rewarded Ad for SGPA Calculator
  Future<void> showSgpaRewardedAd({
    BuildContext? context,
    required VoidCallback onAdCompleted,
    VoidCallback? onAdNotAvailable,
  }) async {
    if (!_isAdsGloballyEnabled || !_isInterstitialSgpaEnabled || _isExamMode) {
      onAdCompleted();
      return;
    }

    if (_rewardedAd != null) {
      bool userEarnedReward = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          preloadRewardedAd();
          if (userEarnedReward) {
            onAdCompleted();
          } else {
            if (context != null && context.mounted) {
              _showNoAdsSnackBar(context, message: "⚠️ Please complete the video to calculate.");
            }
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("AdService: SGPA Rewarded Ad failed to show: $error");
          ad.dispose();
          _rewardedAd = null;
          preloadRewardedAd();
          if (context != null && context.mounted) {
            _showNoAdsSnackBar(context, message: "⚠️ No ads available right now. Please try again later.");
          }
          if (onAdNotAvailable != null) onAdNotAvailable();
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint("AdService: Student earned SGPA Rewarded view: ${reward.amount} ${reward.type}");
          userEarnedReward = true;
          AnalyticsService.logAdEvent(
            adType: 'rewarded',
            placement: 'sgpa_calculator',
            eventType: 'reward_earned',
          );
        },
      );
      AnalyticsService.logAdEvent(
        adType: 'rewarded',
        placement: 'sgpa_calculator',
        eventType: 'impression',
      );
    } else {
      preloadRewardedAd();
      if (context != null && context.mounted) {
        _showNoAdsSnackBar(context, message: "⚠️ No ads available right now. Please try again in a few moments.");
      }
      if (onAdNotAvailable != null) onAdNotAvailable();
    }
  }

  /// Show Interstitial Ad smoothly (fallback)
  Future<void> showInterstitialAd() async {
    if (!_isAdsGloballyEnabled || !_isInterstitialSgpaEnabled || _isExamMode) return;

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          preloadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          preloadInterstitialAd();
        },
      );
      await _interstitialAd!.show();
      AnalyticsService.logAdEvent(
        adType: 'interstitial',
        placement: 'sgpa_calculator',
        eventType: 'impression',
      );
    } else {
      preloadInterstitialAd();
    }
  }

  // =========================================================================
  // 3️⃣ APP OPEN AD: COLD LAUNCH
  // =========================================================================

  void preloadAppOpenAd() {
    if (!_isAdsGloballyEnabled || !_isAppOpenEnabled || _isExamMode || _isAppOpenAdLoading || _appOpenAd != null) return;
    _isAppOpenAdLoading = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          debugPrint("AdService: App Open Ad loaded.");
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _isAppOpenAdLoading = false;
          debugPrint("AdService: App Open Ad failed to load: $error");
        },
      ),
    );
  }

  Future<void> showAppOpenAdIfAvailable() async {
    if (!_isAdsGloballyEnabled || !_isAppOpenEnabled || _isExamMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cooldownHours = _appOpenCooldownHours > 0 ? _appOpenCooldownHours : 4;

      // 1. Check if we are within the cooldown window from the last shown ad
      final lastShownStr = prefs.getString(_keyAppOpenLastShownAt);
      if (lastShownStr != null) {
        final lastShown = DateTime.tryParse(lastShownStr);
        if (lastShown != null && now.difference(lastShown).inHours < cooldownHours) {
          debugPrint("AdService: App Open Ad in cooldown (${now.difference(lastShown).inMinutes}m elapsed of ${cooldownHours}h). Skipping.");
          return;
        }
      }

      // 2. Cooldown is satisfied; increment the launch attempt counter
      int launchCount = (prefs.getInt(_keyAppOpenLaunchCount) ?? 0) + 1;
      await prefs.setInt(_keyAppOpenLaunchCount, launchCount);

      final threshold = _appOpenAttemptThreshold > 0 ? _appOpenAttemptThreshold : 2;
      debugPrint("AdService: App Open Launch Attempt #$launchCount (Target Threshold: #$threshold)");

      if (launchCount < threshold) {
        // Has not reached the attempt threshold yet (e.g. attempt 1)
        preloadAppOpenAd();
        return;
      }

      // 3. Reached the required attempt (e.g. 2nd attempt)! Show ad
      if (_appOpenAd != null) {
        _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _appOpenAd = null;
            prefs.setString(_keyAppOpenLastShownAt, DateTime.now().toIso8601String());
            prefs.setInt(_keyAppOpenLaunchCount, 0); // Reset attempt counter for next cooldown cycle
            preloadAppOpenAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _appOpenAd = null;
            preloadAppOpenAd();
          },
        );
        await _appOpenAd!.show();
        AnalyticsService.logAdEvent(
          adType: 'app_open',
          placement: 'cold_launch',
          eventType: 'impression',
        );
      } else {
        preloadAppOpenAd();
      }
    } catch (e) {
      debugPrint("AdService: showAppOpenAdIfAvailable error: $e");
    }
  }
}

class TimetablePassStatus {
  final bool isAdRequired;
  final bool isUnlocked;
  final String remainingText;
  final DateTime? expiresAt;

  const TimetablePassStatus({
    required this.isAdRequired,
    required this.isUnlocked,
    required this.remainingText,
    this.expiresAt,
  });
}

