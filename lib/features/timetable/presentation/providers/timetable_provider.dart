import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/timetable_service.dart';
import '../../domain/timetable_entry.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../services/notification_service.dart';

final timetableServiceProvider = Provider<TimetableService>((ref) {
  return TimetableService();
});

class TimetableLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => true;
}

final timetableLoadingProvider = NotifierProvider<TimetableLoadingNotifier, bool>(() {
  return TimetableLoadingNotifier();
});

class TimetableNotifier extends Notifier<List<TimetableEntry>> {
  @override
  List<TimetableEntry> build() {
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.value;
    if (profile == null) return [];

    final service = ref.read(timetableServiceProvider);

    // Fire off async fetch to keep it fresh
    Future.microtask(() async {
      ref.read(timetableLoadingProvider.notifier).state = true;
      final freshList = await service.fetchTimetableBackground(
        academicYear: profile.academicYear,
        branch: profile.branch,
        division: profile.division,
        batch: profile.batch,
      );
      if (freshList != null) {
        state = freshList;
        NotificationService().scheduleTimetableNotifications(freshList);
      }
      ref.read(timetableLoadingProvider.notifier).state = false;
    });

    // Return the synchronous cache instantly
    final cachedList = service.getCachedTimetable(
      academicYear: profile.academicYear,
      branch: profile.branch,
      division: profile.division,
      batch: profile.batch,
    );
    
    // Attempt to schedule with cached list immediately
    NotificationService().scheduleTimetableNotifications(cachedList);
    
    return cachedList;
  }

  Future<void> refresh() async {
    final authState = ref.read(authNotifierProvider);
    final profile = authState.value;
    if (profile == null) return;

    ref.read(timetableLoadingProvider.notifier).state = true;
    final service = ref.read(timetableServiceProvider);
    final freshList = await service.fetchTimetableBackground(
      academicYear: profile.academicYear,
      branch: profile.branch,
      division: profile.division,
      batch: profile.batch,
    );
    
    if (freshList != null) {
      state = freshList;
      NotificationService().scheduleTimetableNotifications(freshList);
    }
    ref.read(timetableLoadingProvider.notifier).state = false;
  }
}

final timetableProvider = NotifierProvider<TimetableNotifier, List<TimetableEntry>>(() {
  return TimetableNotifier();
});