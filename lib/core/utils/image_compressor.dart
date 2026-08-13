import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static Future<String?> compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileSize = await file.length();
      
      // If file is already small (< 300KB), don't compress
      if (fileSize < 300 * 1024) {
        return imagePath;
      }

      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 60, // Aggressive compression
        minWidth: 1080,
        minHeight: 1080,
      );

      return result?.path ?? imagePath;
    } catch (e) {
      print("Error compressing image: $e");
      return imagePath;
    }
  }
}
