import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/lost_and_found_item.dart';
import 'package:path/path.dart' as path;

class LostAndFoundService {
  final _supabase = Supabase.instance.client;

  /// Fetches all items from the database ordered by creation date descending.
  Future<List<LostAndFoundItem>> fetchItems() async {
    try {
      final response = await _supabase
          .from('lost_and_found_items')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => LostAndFoundItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }

  /// Uploads an image to Supabase storage and returns the public URL.
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'uploads/$fileName';

      await _supabase.storage.from('lost_and_found_images').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from('lost_and_found_images').getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Inserts a new lost and found item into the database.
  Future<void> createItem(LostAndFoundItem item) async {
    try {
      await _supabase.from('lost_and_found_items').insert(item.toJson());
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }

    try {
      // Insert notification
      final String action = item.isLost ? 'lost' : 'found';
      final String itemTypeStr = item.isLost ? 'Lost' : 'Found';
      await _supabase.from('app_notifications').insert({
        'title': 'New $itemTypeStr Item!',
        'message': '${item.personName} $action: ${item.title}',
        'type': 'lost_and_found',
      });
    } catch (e) {
      print('Failed to create notification: $e');
    }
  }

  /// Updates an item to mark it as successful.
  Future<void> markAsSuccessful(String itemId) async {
    try {
      await _supabase
          .from('lost_and_found_items')
          .update({'is_successful': true})
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to mark as successful: $e');
    }
  }
}
