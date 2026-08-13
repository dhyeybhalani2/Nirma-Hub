import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/events_service.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final allEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final service = ref.watch(eventsServiceProvider);
  final userProfile = ref.watch(authNotifierProvider).value;
  final String userYear = userProfile?.academicYear != null ? "${userProfile!.academicYear} Year" : "";
  
  final allEvents = await service.getAllEvents();
  
  // Filter events based on targetYear
  return allEvents.where((event) {
    return event.targetYear == 'All Years' || event.targetYear == userYear;
  }).toList();
});

final semesterConfigProvider = FutureProvider<SemesterConfigModel?>((ref) async {
  final service = ref.watch(eventsServiceProvider);
  final userProfile = ref.watch(authNotifierProvider).value;
  final String userYear = userProfile?.academicYear != null ? "${userProfile!.academicYear} Year" : "1st Year";
  
  return service.getSemesterConfig(userYear);
});
