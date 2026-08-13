import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_service.dart';
import '../../domain/app_notification.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final service = ref.read(notificationsServiceProvider);
    return service.fetchNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final service = ref.read(notificationsServiceProvider);
    final freshList = await service.fetchNotifications();
    state = AsyncValue.data(freshList);
  }

  Future<void> dismissNotification(String id) async {
    final service = ref.read(notificationsServiceProvider);
    await service.dismissNotification(id);
    
    // Update local state without re-fetching
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((note) => note.id != id).toList());
  }

  Future<void> restoreNotification(AppNotification note, int originalIndex) async {
    final service = ref.read(notificationsServiceProvider);
    await service.restoreNotification(note.id);
    
    final currentList = List<AppNotification>.from(state.value ?? []);
    // Ensure we don't go out of bounds
    final insertIndex = (originalIndex >= 0 && originalIndex <= currentList.length) 
        ? originalIndex 
        : currentList.length;
        
    currentList.insert(insertIndex, note);
    state = AsyncValue.data(currentList);
  }

  Future<void> clearAll() async {
    final service = ref.read(notificationsServiceProvider);
    final currentList = state.value ?? [];
    final ids = currentList.map((n) => n.id).toList();
    await service.clearAllNotifications(ids);
    state = const AsyncValue.data([]);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(() {
  return NotificationsNotifier();
});
