import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableNotificationSettings {
  static const String _prefsKey = 'timetable_notification_settings_v1';

  final bool isEnabled;
  
  // First class of the day
  final int firstClassReminder1Minutes; // Default: 20 mins before
  final bool firstClassReminder2Enabled; // Default: false
  final int firstClassReminder2Minutes; // Default: 5 mins before

  // Subsequent classes
  final bool subsequentUsePreviousEnd; // Default: true (10 mins before previous class ends)
  final int subsequentReminder1Minutes; // If not using previous end, minutes before class (e.g. 10)
  final bool subsequentReminder2Enabled; // Default: false
  final int subsequentReminder2Minutes; // Default: 5 mins before

  final bool enableVibration;

  const TimetableNotificationSettings({
    this.isEnabled = true,
    this.firstClassReminder1Minutes = 20,
    this.firstClassReminder2Enabled = false,
    this.firstClassReminder2Minutes = 5,
    this.subsequentUsePreviousEnd = true,
    this.subsequentReminder1Minutes = 10,
    this.subsequentReminder2Enabled = false,
    this.subsequentReminder2Minutes = 5,
    this.enableVibration = true,
  });

  factory TimetableNotificationSettings.defaultSettings() {
    return const TimetableNotificationSettings();
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'firstClassReminder1Minutes': firstClassReminder1Minutes,
      'firstClassReminder2Enabled': firstClassReminder2Enabled,
      'firstClassReminder2Minutes': firstClassReminder2Minutes,
      'subsequentUsePreviousEnd': subsequentUsePreviousEnd,
      'subsequentReminder1Minutes': subsequentReminder1Minutes,
      'subsequentReminder2Enabled': subsequentReminder2Enabled,
      'subsequentReminder2Minutes': subsequentReminder2Minutes,
      'enableVibration': enableVibration,
    };
  }

  factory TimetableNotificationSettings.fromJson(Map<String, dynamic> json) {
    return TimetableNotificationSettings(
      isEnabled: json['isEnabled'] as bool? ?? true,
      firstClassReminder1Minutes: json['firstClassReminder1Minutes'] as int? ?? 20,
      firstClassReminder2Enabled: json['firstClassReminder2Enabled'] as bool? ?? false,
      firstClassReminder2Minutes: json['firstClassReminder2Minutes'] as int? ?? 5,
      subsequentUsePreviousEnd: json['subsequentUsePreviousEnd'] as bool? ?? true,
      subsequentReminder1Minutes: json['subsequentReminder1Minutes'] as int? ?? 10,
      subsequentReminder2Enabled: json['subsequentReminder2Enabled'] as bool? ?? false,
      subsequentReminder2Minutes: json['subsequentReminder2Minutes'] as int? ?? 5,
      enableVibration: json['enableVibration'] as bool? ?? true,
    );
  }

  TimetableNotificationSettings copyWith({
    bool? isEnabled,
    int? firstClassReminder1Minutes,
    bool? firstClassReminder2Enabled,
    int? firstClassReminder2Minutes,
    bool? subsequentUsePreviousEnd,
    int? subsequentReminder1Minutes,
    bool? subsequentReminder2Enabled,
    int? subsequentReminder2Minutes,
    bool? enableVibration,
  }) {
    return TimetableNotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      firstClassReminder1Minutes: firstClassReminder1Minutes ?? this.firstClassReminder1Minutes,
      firstClassReminder2Enabled: firstClassReminder2Enabled ?? this.firstClassReminder2Enabled,
      firstClassReminder2Minutes: firstClassReminder2Minutes ?? this.firstClassReminder2Minutes,
      subsequentUsePreviousEnd: subsequentUsePreviousEnd ?? this.subsequentUsePreviousEnd,
      subsequentReminder1Minutes: subsequentReminder1Minutes ?? this.subsequentReminder1Minutes,
      subsequentReminder2Enabled: subsequentReminder2Enabled ?? this.subsequentReminder2Enabled,
      subsequentReminder2Minutes: subsequentReminder2Minutes ?? this.subsequentReminder2Minutes,
      enableVibration: enableVibration ?? this.enableVibration,
    );
  }

  static Future<TimetableNotificationSettings> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(jsonString);
        return TimetableNotificationSettings.fromJson(data);
      }
    } catch (e) {
      // Fallback to default
    }
    return TimetableNotificationSettings.defaultSettings();
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(toJson());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      // Ignore
    }
  }
}
