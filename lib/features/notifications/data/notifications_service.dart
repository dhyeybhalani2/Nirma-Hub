import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_notification.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _dismissedKey = 'dismissed_notifications';

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await _supabase
          .from('app_notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50); // Keep it to latest 50 for performance

      final List<AppNotification> allNotifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      final dismissedIds = await _getDismissedIds();
      
      // Filter out the ones that are dismissed
      return allNotifications.where((note) => !dismissedIds.contains(note.id)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<List<String>> _getDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_dismissedKey) ?? [];
  }

  Future<void> dismissNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    if (!dismissed.contains(id)) {
      dismissed.add(id);
      await prefs.setStringList(_dismissedKey, dismissed);
    }
  }

  Future<void> restoreNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    if (dismissed.contains(id)) {
      dismissed.remove(id);
      await prefs.setStringList(_dismissedKey, dismissed);
    }
  }

  Future<void> clearAllNotifications(List<String> currentIds) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    // Add all currently visible to dismissed
    for (final id in currentIds) {
      if (!dismissed.contains(id)) dismissed.add(id);
    }
    await prefs.setStringList(_dismissedKey, dismissed);
  }
}
