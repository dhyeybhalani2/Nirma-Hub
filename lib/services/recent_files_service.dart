import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RecentFile {
  final String title;
  final String url;
  final String type; // e.g., 'Note', 'PYQ', 'Most IMP'
  final DateTime timestamp;

  RecentFile({
    required this.title,
    required this.url,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecentFile.fromMap(Map<String, dynamic> map) {
    return RecentFile(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'Material',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class RecentFilesService {
  static const String _key = 'recent_opened_files';
  static const int _maxFiles = 4;
  
  static final ValueNotifier<List<RecentFile>> recentFilesNotifier = ValueNotifier([]);

  static Future<void> init() async {
    recentFilesNotifier.value = await getRecentFiles();
  }

  static Future<void> addRecentFile(RecentFile file) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing
    final List<String> existingStrings = prefs.getStringList(_key) ?? [];
    List<RecentFile> files = existingStrings.map((s) => RecentFile.fromMap(json.decode(s))).toList();

    // Remove if exists (to move it to top)
    files.removeWhere((f) => f.url == file.url);

    // Add to top
    files.insert(0, file);

    // Trim to max
    if (files.length > _maxFiles) {
      files = files.sublist(0, _maxFiles);
    }

    // Save
    final List<String> newStrings = files.map((f) => json.encode(f.toMap())).toList();
    await prefs.setStringList(_key, newStrings);
    
    // Update notifier
    recentFilesNotifier.value = files;
  }

  static Future<List<RecentFile>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingStrings = prefs.getStringList(_key) ?? [];
    return existingStrings.map((s) => RecentFile.fromMap(json.decode(s))).toList();
  }
}
