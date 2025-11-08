// lib/services/image_preprocessor.dart
import 'dart:io';
import 'package:image/image.dart' as img_lib;

class ImagePreprocessor {
  /// Resize and pad image to EXACT model input size
  /// modelInputSize: 230 (before pad)
  /// padSize: 2 (1 pixel on each side)
  static Future<img_lib.Image?> preprocess(
      File imageFile, {
        required int modelInputSize,  // e.g. 230
        required int padSize,         // e.g. 2 → becomes 232
      }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img_lib.decodeImage(bytes);
      if (image == null) return null;

      // 1. Resize to model input size (230×230)
      image = img_lib.copyResize(image,
          width: modelInputSize, height: modelInputSize);

      // 2. Pad to final size (232×232)
      final paddedSize = modelInputSize + padSize * 2;
      final padded = img_lib.Image(
        width: paddedSize,
        height: paddedSize,
        numChannels: 3,
      );

      // Fill with black (or mean pixel)
      img_lib.fill(padded, color: img_lib.ColorRgb8(0, 0, 0));

      // Center the resized image
      final offsetX = padSize;
      final offsetY = padSize;
      img_lib.compositeImage(
        padded,
        image,
        dstX: offsetX,
        dstY: offsetY,
      );

      return padded;
    } catch (e) {
      print('Preprocess error: $e');
      return null;
    }
  }
}