import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sgpa_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final sgpaServiceProvider = Provider<SgpaService>((ref) {
  return SgpaService();
});

class SgpaNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() {
    final service = ref.read(sgpaServiceProvider);

    // Fire off async fetch to keep it fresh
    service.fetchSgpaDataBackground().then((freshData) {
      if (freshData != null) {
        state = freshData;
      } else if (service.getCachedSgpaData() == null) {
        // If fetch fails and there's no cache, emit an empty map so it doesn't spin forever
        state = {};
      }
    });

    // Return the synchronous cache instantly (0 latency)
    return service.getCachedSgpaData();
  }

  void refresh() {
    final service = ref.read(sgpaServiceProvider);
    service.fetchSgpaDataBackground().then((freshData) {
      if (freshData != null) {
        state = freshData;
      }
    });
  }
}

final sgpaProvider = NotifierProvider<SgpaNotifier, Map<String, dynamic>?>(() {
  return SgpaNotifier();
});

final userMarksProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Wait for the auth provider to have a valid user
  final userProfileAsync = ref.watch(authNotifierProvider);
  final userProfile = userProfileAsync.value;
  
  if (userProfile == null) return {};

  final service = ref.read(sgpaServiceProvider);
  return await service.fetchUserMarks(userProfile.id);
});
