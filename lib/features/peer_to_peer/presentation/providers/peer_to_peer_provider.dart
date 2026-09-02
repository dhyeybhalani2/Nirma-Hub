import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/peer_to_peer_item.dart';
import '../../data/peer_to_peer_service.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';

final peerToPeerServiceProvider = Provider((ref) => PeerToPeerService());

final peerToPeerItemsProvider = AsyncNotifierProvider<PeerToPeerNotifier, List<PeerToPeerItem>>(() {
  return PeerToPeerNotifier();
});

class PeerToPeerNotifier extends AsyncNotifier<List<PeerToPeerItem>> {
  PeerToPeerService get _service => ref.read(peerToPeerServiceProvider);

  @override
  Future<List<PeerToPeerItem>> build() async {
    final blockedUsers = await ref.watch(blockedUsersProvider.future);
    final items = await ref.watch(peerToPeerServiceProvider).getItems();
    
    return items.where((item) => !blockedUsers.contains(item.userId)).toList();
  }

  void filterBlockedUserLocally(String userId) {
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((item) => item.userId != userId).toList()
      );
    }
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getItems();
      final blockedUsersAsync = ref.read(blockedUsersProvider);
      final blockedUsers = blockedUsersAsync.value ?? {};
      state = AsyncValue.data(items.where((item) => !blockedUsers.contains(item.userId)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem({
    required String title,
    required String description,
    required double price,
    required String condition,
    required String category,
    required String imagePath,
    required String contactNumber,
    required String sellerName,
  }) async {
    try {
      await _service.addItem(
        title: title,
        description: description,
        price: price,
        condition: condition,
        category: category,
        imagePath: imagePath,
        contactNumber: contactNumber,
        sellerName: sellerName,
      );
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsSold(String id) async {
    try {
      await _service.markAsSold(id);
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      await loadItems();
    } catch (e) {
      rethrow;
    }
  }
}
