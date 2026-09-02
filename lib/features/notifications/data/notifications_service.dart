import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_notification.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _getDismissedKey() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid != null && uid.isNotEmpty) {
      return 'dismissed_notifications_$uid';
    }
    return 'dismissed_notifications_guest';
  }

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await _supabase
          .from('app_notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(100); // Fetch recent 100 notifications for rich history

      final List<AppNotification> allNotifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      final dismissedIds = await _getDismissedIds();

      final prefs = await SharedPreferences.getInstance();
      final userYear = prefs.getString('academic_year');

      // Filter out dismissed notifications and ensure year compatibility
      return allNotifications.where((note) {
        if (dismissedIds.contains(note.id)) return false;
        
        // If notification is targeted to a specific year, match against student's year
        if (note.targetYear != 'All' && userYear != null && userYear.isNotEmpty) {
          if (note.targetYear.toLowerCase() != userYear.toLowerCase()) {
            return false;
          }
        }
        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<List<String>> _getDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDismissedKey();
    return prefs.getStringList(key) ?? [];
  }

  Future<void> dismissNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDismissedKey();
    final dismissed = prefs.getStringList(key) ?? [];
    if (!dismissed.contains(id)) {
      dismissed.add(id);
      await prefs.setStringList(key, dismissed);
    }
  }

  Future<void> restoreNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDismissedKey();
    final dismissed = prefs.getStringList(key) ?? [];
    if (dismissed.contains(id)) {
      dismissed.remove(id);
      await prefs.setStringList(key, dismissed);
    }
  }

  Future<void> clearAllNotifications(List<String> currentIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDismissedKey();
    final dismissed = prefs.getStringList(key) ?? [];
    // Add all currently visible to dismissed
    for (final id in currentIds) {
      if (!dismissed.contains(id)) dismissed.add(id);
    }
    await prefs.setStringList(key, dismissed);
  }
}
