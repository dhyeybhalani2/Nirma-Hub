import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _keyAppSessionStart = 'analytics_app_session_start';
  static const String _keyAppSessionLastActive = 'analytics_app_session_last';
  static const String _keyPdfSessionStart = 'analytics_pdf_session_start';
  static const String _keyPdfSessionLastActive = 'analytics_pdf_session_last';
  static const String _keyPdfSessionMetadata = 'analytics_pdf_session_metadata';
  static const String _keyImpSessionStart = 'analytics_imp_session_start';
  static const String _keyImpSessionLastActive = 'analytics_imp_session_last';
  static const String _keyImpSessionMetadata = 'analytics_imp_session_metadata';
  
  static Timer? _heartbeatTimer;

  static Future<void> initAndCheckStrandedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if there was an abruptly ended app session
    final appStartStr = prefs.getString(_keyAppSessionStart);
    final appLastStr = prefs.getString(_keyAppSessionLastActive);
    if (appStartStr != null && appLastStr != null) {
      final start = DateTime.parse(appStartStr);
      final last = DateTime.parse(appLastStr);
      final duration = last.difference(start).inSeconds;
      if (duration > 0) {
        await _sendSession('app_session', duration, null);
      }
      await prefs.remove(_keyAppSessionStart);
      await prefs.remove(_keyAppSessionLastActive);
    }

    // Check if there was an abruptly ended PDF session
    final pdfStartStr = prefs.getString(_keyPdfSessionStart);
    final pdfLastStr = prefs.getString(_keyPdfSessionLastActive);
    if (pdfStartStr != null && pdfLastStr != null) {
      final start = DateTime.parse(pdfStartStr);
      final last = DateTime.parse(pdfLastStr);
      final duration = last.difference(start).inSeconds;
      final metadataStr = prefs.getString(_keyPdfSessionMetadata);
      Map<String, dynamic>? metadata;
      if (metadataStr != null) {
        metadata = jsonDecode(metadataStr);
      }
      if (duration > 0) {
        await _sendSession('pdf_view', duration, metadata);
      }
      await prefs.remove(_keyPdfSessionStart);
      await prefs.remove(_keyPdfSessionLastActive);
      await prefs.remove(_keyPdfSessionMetadata);
    }

    // Check if there was an abruptly ended IMP session
    final impStartStr = prefs.getString(_keyImpSessionStart);
    final impLastStr = prefs.getString(_keyImpSessionLastActive);
    if (impStartStr != null && impLastStr != null) {
      final start = DateTime.parse(impStartStr);
      final last = DateTime.parse(impLastStr);
      final duration = last.difference(start).inSeconds;
      final metadataStr = prefs.getString(_keyImpSessionMetadata);
      Map<String, dynamic>? metadata;
      if (metadataStr != null) {
        metadata = jsonDecode(metadataStr);
      }
      if (duration > 0) {
        await _sendSession('imp_view', duration, metadata);
      }
      await prefs.remove(_keyImpSessionStart);
      await prefs.remove(_keyImpSessionLastActive);
      await prefs.remove(_keyImpSessionMetadata);
    }
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      final nowStr = DateTime.now().toIso8601String();
      if (prefs.getString(_keyAppSessionStart) != null) {
        await prefs.setString(_keyAppSessionLastActive, nowStr);
      }
      if (prefs.getString(_keyPdfSessionStart) != null) {
        await prefs.setString(_keyPdfSessionLastActive, nowStr);
      }
      if (prefs.getString(_keyImpSessionStart) != null) {
        await prefs.setString(_keyImpSessionLastActive, nowStr);
      }
    });
  }

  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // --- App Sessions ---
  static Future<void> startAppSession() async {
    final prefs = await SharedPreferences.getInstance();
    final nowStr = DateTime.now().toIso8601String();
    await prefs.setString(_keyAppSessionStart, nowStr);
    await prefs.setString(_keyAppSessionLastActive, nowStr);
    _startHeartbeat();
    print("Analytics: Started App Session");
  }

  static Future<void> endAppSession() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(_keyAppSessionStart);
    if (startStr != null) {
      final start = DateTime.parse(startStr);
      final now = DateTime.now();
      final duration = now.difference(start).inSeconds;
      if (duration > 0) {
        await _sendSession('app_session', duration, null);
      }
      await prefs.remove(_keyAppSessionStart);
      await prefs.remove(_keyAppSessionLastActive);
      print("Analytics: Ended App Session ($duration seconds)");
    }
    _stopHeartbeat();
  }

  // --- PDF Sessions ---
  static Future<void> startPdfSession(String pdfName) async {
    final prefs = await SharedPreferences.getInstance();
    final nowStr = DateTime.now().toIso8601String();
    await prefs.setString(_keyPdfSessionStart, nowStr);
    await prefs.setString(_keyPdfSessionLastActive, nowStr);
    await prefs.setString(_keyPdfSessionMetadata, jsonEncode({'pdf_name': pdfName}));
    if (_heartbeatTimer == null || !_heartbeatTimer!.isActive) {
      _startHeartbeat();
    }
    print("Analytics: Started PDF Session for $pdfName");
  }

  static Future<void> endPdfSession() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(_keyPdfSessionStart);
    if (startStr != null) {
      final start = DateTime.parse(startStr);
      final now = DateTime.now();
      final duration = now.difference(start).inSeconds;
      
      final metadataStr = prefs.getString(_keyPdfSessionMetadata);
      Map<String, dynamic>? metadata;
      if (metadataStr != null) {
        metadata = jsonDecode(metadataStr);
      }

      if (duration > 0) {
        await _sendSession('pdf_view', duration, metadata);
      }
      await prefs.remove(_keyPdfSessionStart);
      await prefs.remove(_keyPdfSessionLastActive);
      await prefs.remove(_keyPdfSessionMetadata);
      print("Analytics: Ended PDF Session ($duration seconds)");
    }
  }

  // --- IMP Master Guide Sessions ---
  static Future<void> startImpSession(String subjectName, {String? subjectId, String? subjectCode}) async {
    final prefs = await SharedPreferences.getInstance();
    final nowStr = DateTime.now().toIso8601String();
    await prefs.setString(_keyImpSessionStart, nowStr);
    await prefs.setString(_keyImpSessionLastActive, nowStr);
    await prefs.setString(_keyImpSessionMetadata, jsonEncode({
      'subject_name': subjectName,
      if (subjectId != null) 'subject_id': subjectId,
      if (subjectCode != null) 'subject_code': subjectCode,
    }));
    if (_heartbeatTimer == null || !_heartbeatTimer!.isActive) {
      _startHeartbeat();
    }
    print("Analytics: Started IMP Session for $subjectName");
  }

  static Future<void> endImpSession() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(_keyImpSessionStart);
    if (startStr != null) {
      final start = DateTime.parse(startStr);
      final now = DateTime.now();
      final duration = now.difference(start).inSeconds;
      
      final metadataStr = prefs.getString(_keyImpSessionMetadata);
      Map<String, dynamic>? metadata;
      if (metadataStr != null) {
        metadata = jsonDecode(metadataStr);
      }

      if (duration > 0) {
        await _sendSession('imp_view', duration, metadata);
      }
      await prefs.remove(_keyImpSessionStart);
      await prefs.remove(_keyImpSessionLastActive);
      await prefs.remove(_keyImpSessionMetadata);
      print("Analytics: Ended IMP Session ($duration seconds)");
    }
  }

  // --- Material Interactions (View, Pin, Unpin, Share) ---
  static Future<void> logMaterialInteraction({
    required String materialId,
    required String fileName,
    required String interactionType, // 'view', 'pin', 'unpin', 'share'
    String? subjectName,
    String? folderType,
  }) async {
    try {
      if (materialId.isEmpty) return;
      final user = Supabase.instance.client.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('student_device_uuid');
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('student_device_uuid', deviceId);
      }

      await Supabase.instance.client.from('material_interactions').insert({
        'material_id': materialId,
        'file_name': fileName,
        'interaction_type': interactionType,
        if (subjectName != null && subjectName.isNotEmpty) 'subject_name': subjectName,
        if (folderType != null && folderType.isNotEmpty) 'folder_type': folderType,
        'user_id': user?.id ?? deviceId,
        'user_email': user?.email,
      });
      print("Analytics: Logged material interaction ($interactionType) for $fileName");
    } catch (e) {
      print("Analytics: Material interaction logging failed: $e");
    }
  }

  // --- 📢 Ad Event Logging ---
  static Future<void> logAdEvent({
    required String adType, // 'rewarded', 'interstitial', 'app_open', 'banner'
    required String placement, // 'timetable_notification_pass', 'sgpa_calculator', 'app_launch', 'notes_list', 'pyq_list', 'imp_screen'
    required String eventType, // 'impression', 'reward_earned', 'click'
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('analytics_device_id');
      if (deviceId == null) {
        deviceId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('analytics_device_id', deviceId);
      }

      await Supabase.instance.client.from('ad_events').insert({
        'ad_type': adType,
        'placement': placement,
        'event_type': eventType,
        'user_id': user?.id ?? deviceId,
        'user_email': user?.email,
        'created_at': DateTime.now().toIso8601String(),
      });
      print("Analytics: Logged Ad Event [$adType | $placement | $eventType]");
    } catch (e) {
      print("Analytics: Ad event logging skipped: $e");
    }
  }

  // --- Internal Helper ---
  static Future<void> _sendSession(String eventType, int durationSeconds, Map<String, dynamic>? metadata) async {
    try {
      final String platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Web/Other');
      final user = Supabase.instance.client.auth.currentUser;
      
      final Map<String, dynamic> payload = {
        'event_type': eventType,
        'duration_seconds': durationSeconds,
        'metadata': {
          'platform': platform,
          if (metadata != null) ...metadata,
        }
      };

      if (user != null) {
        payload['user_id'] = user.id;
      }

      await Supabase.instance.client.from('analytics_sessions').insert(payload);
    } catch (e) {
      print("Analytics send failed: $e");
    }
  }
}
