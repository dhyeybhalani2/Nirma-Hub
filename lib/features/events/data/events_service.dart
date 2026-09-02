import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsServiceProvider = Provider((ref) => EventsService());

class EventModel {
  final String id;
  final String title;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final String time;
  final String location;
  final String classNo;
  final String totalMarks;
  final String duration;
  final String subject;
  final String targetYear;

  EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.time,
    required this.location,
    required this.classNo,
    required this.totalMarks,
    required this.duration,
    required this.subject,
    required this.targetYear,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      time: json['time'] ?? 'All Day',
      location: json['location'] ?? '',
      classNo: json['class_no'] ?? '',
      totalMarks: json['total_marks'] ?? '',
      duration: json['duration'] ?? '',
      subject: json['subject'] ?? '',
      targetYear: json['target_year'] ?? 'All Years',
    );
  }
}

class SemesterConfigModel {
  final String id;
  final String semesterName;
  final DateTime startDate;
  final DateTime endDate;

  SemesterConfigModel({
    required this.id,
    required this.semesterName,
    required this.startDate,
    required this.endDate,
  });

  factory SemesterConfigModel.fromJson(Map<String, dynamic> json) {
    return SemesterConfigModel(
      id: json['id'],
      semesterName: json['semester_name'] ?? '3rd Semester',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}

class EventsService {
  final _supabase = Supabase.instance.client;

  Future<List<EventModel>> getAllEvents() async {
    try {
      final response = await _supabase.from('events').select();
      
      return (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all events: $e');
      return [];
    }
  }

  Future<SemesterConfigModel?> getSemesterConfig(String targetYear) async {
    try {
      final response = await _supabase.from('semester_config').select().eq('target_year', targetYear).limit(1);
      if (response.isNotEmpty) {
        return SemesterConfigModel.fromJson(response.first);
      }
      return null;
    } catch (e) {
      print('Error fetching semester config: $e');
      return null;
    }
  }
}
