import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<File> compressImage(String path) async {
  final compressed = await FlutterImageCompress.compressAndGetFile(
    path,
    "${path}_compressed.jpg",
    quality: 70, // Adjust quality as needed
  );
  return File(compressed!.path);
}
