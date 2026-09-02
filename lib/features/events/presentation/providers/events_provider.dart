import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/events_service.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final allEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final service = ref.watch(eventsServiceProvider);
  final userProfile = ref.watch(authNotifierProvider).value;
  final String rawUserYear = userProfile?.academicYear?.trim() ?? "";
  final String userYear = rawUserYear.isNotEmpty && !rawUserYear.toLowerCase().contains("year")
      ? "$rawUserYear Year"
      : rawUserYear;
  
  final allEvents = await service.getAllEvents();
  
  // Filter events based on targetYear
  return allEvents.where((event) {
    final target = event.targetYear.trim().toLowerCase();
    if (target.isEmpty || target == 'all' || target == 'all years') return true;
    if (userYear.isEmpty) return true;
    final cleanTarget = target.replaceAll(' ', '');
    final cleanUser = userYear.toLowerCase().replaceAll(' ', '');
    return cleanTarget.contains(cleanUser) || cleanUser.contains(cleanTarget);
  }).toList();
});

final semesterConfigProvider = FutureProvider<SemesterConfigModel?>((ref) async {
  final service = ref.watch(eventsServiceProvider);
  final userProfile = ref.watch(authNotifierProvider).value;
  final String rawUserYear = userProfile?.academicYear?.trim() ?? "";
  final String userYear = rawUserYear.isNotEmpty && !rawUserYear.toLowerCase().contains("year")
      ? "$rawUserYear Year"
      : (rawUserYear.isNotEmpty ? rawUserYear : "1st Year");
  
  return service.getSemesterConfig(userYear);
});
