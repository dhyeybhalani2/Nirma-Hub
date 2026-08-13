import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static Future<void> logAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Prevent logging multiple times in a single session by tracking last log time
      final lastLogStr = prefs.getString('last_app_open_log');
      if (lastLogStr != null) {
        final lastLog = DateTime.parse(lastLogStr);
        // Only log once every 5 minutes minimum to avoid spam
        if (DateTime.now().difference(lastLog).inMinutes < 5) {
          return;
        }
      }

      final String platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Web/Other');
      final user = Supabase.instance.client.auth.currentUser;
      
      await Supabase.instance.client.from('app_opens').insert({
        'user_id': user?.id, // Can be null if not logged in
        'platform': platform,
      });

      await prefs.setString('last_app_open_log', DateTime.now().toIso8601String());
      print("Analytics: Logged app open.");
    } catch (e) {
      print("Analytics logging failed: $e");
    }
  }
}
