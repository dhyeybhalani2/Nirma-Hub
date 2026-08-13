import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/peer_to_peer_item.dart';

class PeerToPeerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PeerToPeerItem>> getItems() async {
    final response = await _supabase
        .from('peer_to_peer_items')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => PeerToPeerItem.fromJson(json)).toList();
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    String finalImagePath = imagePath;
    
    // Upload image to Supabase Storage if it's a local file
    if (!imagePath.startsWith('http')) {
      final file = File(imagePath);
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from('peer_to_peer_images').upload(
        filePath,
        file,
      );

      finalImagePath = _supabase.storage.from('peer_to_peer_images').getPublicUrl(filePath);
    }

    await _supabase.from('peer_to_peer_items').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'category': category,
      'image_path': finalImagePath,
      'contact_number': contactNumber,
      'seller_name': sellerName,
    });

    try {
      await _supabase.from('app_notifications').insert({
        'title': 'New Item in Marketplace!',
        'message': '$sellerName just posted: $title for ₹$price',
        'type': 'peer_to_peer',
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  Future<void> markAsSold(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    await _supabase
        .from('peer_to_peer_items')
        .update({'is_sold': true})
        .eq('id', itemId)
        .eq('user_id', userId);
  }
  
  Future<void> deleteItem(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    await _supabase
        .from('peer_to_peer_items')
        .delete()
        .eq('id', itemId)
        .eq('user_id', userId);
  }
}
