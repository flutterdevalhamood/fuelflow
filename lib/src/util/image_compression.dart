import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionHelper {
  static Future<File?> compressImage(File file) async {
    try {
      final originalSize = await file.length();
      debugPrint('📸 Original: $originalSize bytes');

      // ✅ Skip compression if already small enough (under 300KB)
      if (originalSize < 300 * 1024) {
        debugPrint('⏭ Skipping compression — already small');
        return file;
      }

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_c.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50, // ✅ Lowered from 60 — faster + smaller upload
        minWidth: 800, // ✅ Reduced from 1024 — meter photos don't need high res
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        debugPrint('✅ Compressed: ${await compressedFile.length()} bytes');
        return compressedFile;
      }
      return file; // fallback to original
    } catch (e) {
      debugPrint('❌ Compression failed: $e');
      return file; // fallback to original, never return null
    }
  }

  // ✅ FIX: Run all compressions in parallel, not sequentially
  static Future<List<File>> compressMultipleImages(List<File> files) async {
    if (files.isEmpty) return [];
    // Future.wait runs all compressions at the same time
    final results = await Future.wait(files.map((f) => compressImage(f)));
    return results.whereType<File>().toList();
  }

  static Future<bool> isFileSizeAcceptable(File file) async {
    final bytes = await file.length();
    const maxSizeInBytes = 2 * 1024 * 1024;
    return bytes <= maxSizeInBytes;
  }
}
