import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/lost_and_found_service.dart';
import '../../domain/lost_and_found_item.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import 'package:uuid/uuid.dart';

final lostAndFoundServiceProvider = Provider<LostAndFoundService>((ref) {
  return LostAndFoundService();
});

final lostAndFoundItemsProvider = AsyncNotifierProvider<LostAndFoundItemsNotifier, List<LostAndFoundItem>>(() {
  return LostAndFoundItemsNotifier();
});

class LostAndFoundItemsNotifier extends AsyncNotifier<List<LostAndFoundItem>> {
  @override
  Future<List<LostAndFoundItem>> build() async {
    final service = ref.watch(lostAndFoundServiceProvider);
    final items = await service.fetchItems();
    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    
    if (blockedUsersAsync.hasValue) {
      final blockedUsers = blockedUsersAsync.value!;
      return items.where((item) => !blockedUsers.contains(item.userId)).toList();
    }
    return items;
  }

  void filterBlockedUserLocally(String userId) {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((item) => item.userId != userId).toList()
      );
    }
  }
}

class LostAndFoundNotifier extends AsyncNotifier<void> {
  LostAndFoundService get _service => ref.read(lostAndFoundServiceProvider);

  @override
  FutureOr<void> build() {
  }

  Future<void> submitReport({
    required String title,
    required String location,
    required String date,
    required bool isLost,
    required String description,
    required String personName,
    required String contactNumber,
    required String email,
    required String userId,
    String? imagePath,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _service.uploadImage(File(imagePath));
      }

      final newItem = LostAndFoundItem(
        id: const Uuid().v4(),
        title: title,
        location: location,
        date: date,
        isLost: isLost,
        imagePath: imageUrl ?? 'https://images.unsplash.com/photo-1584972242131-7e8c3b9b4f9f?auto=format&fit=crop&q=80&w=400&h=400',
        description: description,
        personName: personName,
        contactNumber: contactNumber,
        email: email,
        userId: userId,
      );

      await _service.createItem(newItem);
      
      // Invalidate the list to refetch
      ref.invalidate(lostAndFoundItemsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> markAsSuccessful(String itemId) async {
    state = const AsyncValue.loading();
    try {
      await _service.markAsSuccessful(itemId);
      ref.invalidate(lostAndFoundItemsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final lostAndFoundNotifierProvider = AsyncNotifierProvider<LostAndFoundNotifier, void>(() {
  return LostAndFoundNotifier();
});
