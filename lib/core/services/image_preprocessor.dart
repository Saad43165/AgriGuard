// lib/services/image_preprocessor.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img_lib;

class ImagePreprocessor {
  /// Resize image to exact model input size (224x224)
  /// Returns properly formatted image ready for TFLite
  static Future<img_lib.Image?> preprocess(
    File imageFile, {
    int modelInputSize = 224,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img_lib.decodeImage(bytes);
      if (image == null) {
        debugPrint('❌ Failed to decode image');
        return null;
      }

      debugPrint('📸 Original image: ${image.width}x${image.height}');

      // Fix orientation if needed
      image = img_lib.bakeOrientation(image);

      // Resize to exact model input size
      final resized = img_lib.copyResize(
        image,
        width: modelInputSize,
        height: modelInputSize,
        interpolation: img_lib.Interpolation.linear,
      );

      debugPrint('✓ Resized to: ${resized.width}x${resized.height}');

      return resized;
    } catch (e) {
      debugPrint('❌ Preprocess error: $e');
      return null;
    }
  }

  /// Convert image to Uint8List for TFLite uint8 input
  /// Returns flat array: [R,G,B, R,G,B, ...] for all pixels
  static Uint8List imageToUint8List(img_lib.Image image) {
    final int width = image.width;
    final int height = image.height;
    final int totalBytes = width * height * 3; // RGB

    final Uint8List bytes = Uint8List(totalBytes);
    int byteIndex = 0;

    // Convert pixel by pixel in row-major order
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Extract RGB values (0-255)
        bytes[byteIndex++] = pixel.r.toInt();
        bytes[byteIndex++] = pixel.g.toInt();
        bytes[byteIndex++] = pixel.b.toInt();
      }
    }

    return bytes;
  }

  /// Convert image to Float32List for TFLite float32 input
  /// Applies MobileNetV3 preprocessing: scales to [-1, 1]
  static Float32List imageToFloat32List(img_lib.Image image) {
    final int width = image.width;
    final int height = image.height;
    final int totalValues = width * height * 3; // RGB

    final Float32List floats = Float32List(totalValues);
    int floatIndex = 0;

    // Convert pixel by pixel with normalization
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        
        // MobileNetV3 preprocessing: (pixel / 127.5) - 1.0
        // This scales from [0, 255] to [-1, 1]
        floats[floatIndex++] = (pixel.r.toInt() / 127.5) - 1.0;
        floats[floatIndex++] = (pixel.g.toInt() / 127.5) - 1.0;
        floats[floatIndex++] = (pixel.b.toInt() / 127.5) - 1.0;
      }
    }

    return floats;
  }

  /// Debug helper: print sample pixel values
  static void debugPixels(img_lib.Image image, {int samples = 5}) {
    debugPrint('🔍 Sample pixel values:');
    for (int i = 0; i < samples && i < image.width; i++) {
      final pixel = image.getPixel(i, i);
      debugPrint('  Pixel($i,$i): R=${pixel.r.toInt()}, G=${pixel.g.toInt()}, B=${pixel.b.toInt()}');
    }

    // Calculate basic stats
    int sumR = 0, sumG = 0, sumB = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        sumR += pixel.r.toInt();
        sumG += pixel.g.toInt();
        sumB += pixel.b.toInt();
      }
    }
    
    final totalPixels = image.width * image.height;
    debugPrint('  Average RGB: (${sumR ~/ totalPixels}, ${sumG ~/ totalPixels}, ${sumB ~/ totalPixels})');
  }
}