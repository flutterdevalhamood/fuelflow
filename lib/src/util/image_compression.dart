import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionHelper {
  /// Compress image to reduce file size before upload
  /// Targets ~500KB per image for faster upload
  static Future<File?> compressImage(File file) async {
    try {
      debugPrint('📸 Original file size: ${await file.length()} bytes');

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 60, // Reduced from 85 to 60
        minWidth: 1024, // Max width 1024px
        minHeight: 1024, // Max height 1024px
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        debugPrint(
          '✅ Compressed file size: ${await compressedFile.length()} bytes',
        );
        return compressedFile;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Compression failed: $e');
      return null;
    }
  }

  /// Compress multiple images
  static Future<List<File>> compressMultipleImages(List<File> files) async {
    final compressedFiles = <File>[];

    for (var file in files) {
      final compressed = await compressImage(file);
      if (compressed != null) {
        compressedFiles.add(compressed);
      } else {
        // Fallback to original if compression fails
        compressedFiles.add(file);
      }
    }

    return compressedFiles;
  }

  /// Check if file size is acceptable (max 2MB)
  static Future<bool> isFileSizeAcceptable(File file) async {
    final bytes = await file.length();
    const maxSizeInBytes = 2 * 1024 * 1024; // 2MB
    return bytes <= maxSizeInBytes;
  }
}
