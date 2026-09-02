import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/timetable_entry.dart';
import '../../../../../main.dart'; // Import sharedPrefs

class TimetableService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKey = 'timetable_json_cache';

  List<TimetableEntry> getCachedTimetable({
    required String academicYear,
    required String branch,
    required String division,
    required String batch,
  }) {
    String? cachedJson = sharedPrefs.getString(_cacheKey);
    if (cachedJson != null) {
      return _parseTimetable(cachedJson, academicYear, branch, division, batch);
    }
    return [];
  }

  Future<List<TimetableEntry>?> fetchTimetableBackground({
    required String academicYear,
    required String branch,
    required String division,
    required String batch,
  }) async {
    try {
      final publicUrl = _supabase.storage.from('config').getPublicUrl('master_timetable.json');
      final urlWithCacheBuster = "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      
      final response = await http.get(Uri.parse(urlWithCacheBuster));
      
      if (response.statusCode == 200) {
        final remoteJsonStr = response.body;
        String? cachedJson = sharedPrefs.getString(_cacheKey);
        if (remoteJsonStr != cachedJson) {
          await sharedPrefs.setString(_cacheKey, remoteJsonStr);
          return _parseTimetable(remoteJsonStr, academicYear, branch, division, batch);
        }
      } else {
        // Fallback to supabase SDK
        final bytes = await _supabase.storage.from('config').download('master_timetable.json');
        final remoteJsonStr = utf8.decode(bytes);

        String? cachedJson = sharedPrefs.getString(_cacheKey);
        if (remoteJsonStr != cachedJson) {
          await sharedPrefs.setString(_cacheKey, remoteJsonStr);
          return _parseTimetable(remoteJsonStr, academicYear, branch, division, batch);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  List<TimetableEntry> _parseTimetable(String jsonStr, String academicYear, String branch, String division, String batch) {
    try {
      final Map<String, dynamic> data = json.decode(jsonStr);
      final List<dynamic> schedules = data['schedules'] ?? [];

      return schedules.map((json) => TimetableEntry.fromJson(json)).where((entry) {
        // Robust cleanup to handle variations like "A devison" or "A 1"
        String cleanUserYear = academicYear.toLowerCase().replaceAll(' ', '').replaceAll('year', '');
        String cleanEntryYear = entry.academicYear.toLowerCase().replaceAll(' ', '').replaceAll('year', '');
        
        String cleanUserBranch = branch.toLowerCase().replaceAll(' ', '');
        String cleanEntryBranch = entry.branch.toLowerCase().replaceAll(' ', '');

        String cleanUserDiv = division.toLowerCase().replaceAll(' ', '').replaceAll('division', '').replaceAll('devison', '');
        String cleanEntryDiv = entry.division.toLowerCase().replaceAll(' ', '').replaceAll('division', '').replaceAll('devison', '');
        
        String cleanUserBatch = batch.toLowerCase().replaceAll(' ', '').replaceAll('batch', '');
        String cleanEntryBatch = entry.batch?.toLowerCase().replaceAll(' ', '').replaceAll('batch', '') ?? '';

        // Match academic year
        if (!cleanUserYear.contains(cleanEntryYear) && !cleanEntryYear.contains(cleanUserYear)) return false;
        
        // Match branch (If 1st year, branch check is less strict, but if user explicitly chose it, we enforce it)
        if (cleanUserYear.contains('1st') && cleanEntryBranch.contains('common')) {
          // Allow common for 1st year
        } else if (!cleanUserBranch.contains(cleanEntryBranch) && !cleanEntryBranch.contains(cleanUserBranch)) {
          return false;
        }

        // Match division
        if (!cleanUserDiv.contains(cleanEntryDiv) && !cleanEntryDiv.contains(cleanUserDiv)) return false;
        
        // Match batch (if entry.batch is null, it means it applies to all batches in that division)
        if (entry.batch != null && cleanEntryBatch.isNotEmpty) {
          if (!cleanUserBatch.contains(cleanEntryBatch) && !cleanEntryBatch.contains(cleanUserBatch)) return false;
        }

        return true;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}