import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../domain/sgpa_subject.dart';
import '../../../../../main.dart'; // Import sharedPrefs

class SgpaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKey = 'sgpa_json_cache';

  Map<String, dynamic>? getCachedSgpaData() {
    String? cachedJson = sharedPrefs.getString(_cacheKey);
    if (cachedJson != null) {
      return json.decode(cachedJson);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchSgpaDataBackground() async {
    try {
      final publicUrl = _supabase.storage.from('config').getPublicUrl('master_sgpa.json');
      // Append timestamp to bypass CDN cache completely
      final urlWithCacheBuster = "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      
      final response = await http.get(Uri.parse(urlWithCacheBuster));
      
      if (response.statusCode == 200) {
        final remoteJsonStr = response.body;
        String? cachedJson = sharedPrefs.getString(_cacheKey);
        
        if (remoteJsonStr != cachedJson) {
          // Cache the new version
          await sharedPrefs.setString(_cacheKey, remoteJsonStr);
          // Return the fresh data!
          return json.decode(remoteJsonStr);
        }
      } else {
        // Fallback to supabase SDK if publicUrl fails for some reason
        final bytes = await _supabase.storage.from('config').download('master_sgpa.json');
        final remoteJsonStr = utf8.decode(bytes);
        String? cachedJson = sharedPrefs.getString(_cacheKey);
        
        if (remoteJsonStr != cachedJson) {
          await sharedPrefs.setString(_cacheKey, remoteJsonStr);
          return json.decode(remoteJsonStr);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extracts the specific subjects for a given academic year, branch, and semester
  List<SgpaSubject> parseSubjects(Map<String, dynamic>? data, String academicYear, String branch, String semester) {
    if (data == null) return [];
    
    // Normalize user strings
    String cleanYear = academicYear.toLowerCase().contains("1st") ? "1st Year" : "2nd Year"; 
    // ^ Assuming only 1st and 2nd year for now, based on provided schema
    
    String cleanBranch = cleanYear == "1st Year" ? "Common" : branch;

    try {
      final yearData = data[cleanYear] as Map<String, dynamic>?;
      if (yearData == null) return [];

      final branchData = yearData[cleanBranch] as Map<String, dynamic>?;
      if (branchData == null) return [];

      final semData = branchData[semester] as List<dynamic>?;
      if (semData == null) return [];

      return semData.map((json) => SgpaSubject.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches saved marks for a specific user from Supabase
  Future<Map<String, dynamic>> fetchUserMarks(String userId) async {
    try {
      final response = await _supabase
          .from('user_marks')
          .select('semester, subject_name, marks_data')
          .eq('user_id', userId);
          
      // Convert to Map: { "semester": { "subjectName": { "Sessional": "23", ... } } }
      Map<String, dynamic> userMarks = {};
      for (var row in response) {
        String sem = row['semester'].toString();
        String subj = row['subject_name'].toString();
        if (userMarks[sem] == null) {
          userMarks[sem] = <String, dynamic>{};
        }
        
        // Ensure marks_data is correctly casted to Map<String, dynamic>
        Map<String, dynamic> marksData = {};
        if (row['marks_data'] is Map) {
          (row['marks_data'] as Map).forEach((key, value) {
            marksData[key.toString()] = value;
          });
        }
        userMarks[sem][subj] = marksData;
      }
      return userMarks;
    } catch (e) {
      return {};
    }
  }

  /// Saves or updates marks for a specific subject
  Future<void> saveSubjectMarks({
    required String userId,
    required String semester,
    required String subjectName,
    required Map<String, String> marks,
  }) async {
    try {
      await _supabase.from('user_marks').upsert({
        'user_id': userId,
        'semester': semester,
        'subject_name': subjectName,
        'marks_data': marks,
      }, onConflict: 'user_id, semester, subject_name');
    } catch (e) {
      // Ignore save errors silently
    }
  }
}
