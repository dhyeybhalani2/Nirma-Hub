import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/moderation_service.dart';

final moderationServiceProvider = Provider<ModerationService>((ref) {
  return ModerationService();
});

final blockedUsersProvider = AsyncNotifierProvider<BlockedUsersNotifier, Set<String>>(() {
  return BlockedUsersNotifier();
});

class BlockedUsersNotifier extends AsyncNotifier<Set<String>> {
  ModerationService get _service => ref.read(moderationServiceProvider);

  @override
  Future<Set<String>> build() async {
    final blockedIds = await _service.getBlockedUserIds();
    return blockedIds.toSet();
  }

  Future<void> blockUser(String userId) async {
    try {
      await _service.blockUser(userId);
      // Optimistically update the state
      if (state.hasValue) {
        final currentSet = state.value!;
        state = AsyncValue.data({...currentSet, userId});
      } else {
        ref.invalidateSelf(); // Re-fetch if it wasn't loaded properly
      }
    } catch (e) {
      rethrow;
    }
  }
}
