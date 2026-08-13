import 'package:supabase_flutter/supabase_flutter.dart';

class ModerationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Reports a specific item or user
  Future<void> reportItem({
    required String reportedUserId,
    required String itemType,
    required String itemId,
    required String reason,
  }) async {
    final reporterId = _supabase.auth.currentUser?.id;
    if (reporterId == null) throw Exception('User not logged in');

    await _supabase.from('reports').insert({
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'item_type': itemType,
      'item_id': itemId,
      'reason': reason,
    });
  }

  /// Blocks a specific user
  Future<void> blockUser(String blockedUserId) async {
    final blockerId = _supabase.auth.currentUser?.id;
    if (blockerId == null) throw Exception('User not logged in');
    if (blockerId == blockedUserId) throw Exception('You cannot block yourself');

    try {
      await _supabase.from('blocked_users').insert({
        'blocker_id': blockerId,
        'blocked_id': blockedUserId,
      });
    } catch (e) {
      // Ignore if already blocked (unique constraint violation)
      if (!e.toString().contains('duplicate key value')) {
        rethrow;
      }
    }
  }

  /// Gets the list of user IDs blocked by the current user
  Future<List<String>> getBlockedUserIds() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final data = await _supabase
        .from('blocked_users')
        .select('blocked_id')
        .eq('blocker_id', currentUserId);

    return (data as List).map((row) => row['blocked_id'] as String).toList();
  }
}
