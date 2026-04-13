// lib/core/services/leaf_detector.dart
//
// Shared leaf detection utility used by all three analysis services.
// Canonical algorithm from ai_analysis_service.dart — single source of truth.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class LeafDetector {
  /// Analyses [imageFile] and returns a map with:
  ///   isLeaf        — bool
  ///   confidence    — double (0–100+)
  ///   greenPercentage, warmPercentage, plantPercentage, edgeDensity — double
  ///   message       — String
  static Future<Map<String, dynamic>> detect(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return {
          'isLeaf': true,
          'confidence': 50.0,
          'message': 'Failed to decode image',
        };
      }

      final resized = img.copyResize(image, width: 300);
      final totalPixels = resized.width * resized.height;

      int greenPixels = 0;
      int warmPixels = 0;
      int edgeCount = 0;
      const edgeThreshold = 25;

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          // Healthy leaf — green dominant
          if (g > r * 1.2 && g > b * 1.2 && g > 30) greenPixels++;

          // Diseased leaf — rust / blight / scorch / scab colours
          if (r > 100 && g > 40 && b < 110 && r > b * 1.4) warmPixels++;

          // Edge detection
          if (y < resized.height - 1 && x < resized.width - 1) {
            final current = (r + g + b) / 3;
            final rp = resized.getPixel(x + 1, y);
            final right = (rp.r + rp.g + rp.b) / 3;
            final dp = resized.getPixel(x, y + 1);
            final down = (dp.r + dp.g + dp.b) / 3;
            if ((current - right).abs() > edgeThreshold ||
                (current - down).abs() > edgeThreshold) {
              edgeCount++;
            }
          }
        }
      }

      final greenPct = (greenPixels / totalPixels) * 100;
      final warmPct = (warmPixels / totalPixels) * 100;
      final edgeDensity = (edgeCount / totalPixels) * 100;

      // Combined plant coverage: green + discounted warm pixels
      final plantPct = greenPct + (warmPct * 0.5);

      // Canonical decision rule (from ai_analysis_service.dart)
      final isLeaf = (plantPct > 15 && edgeDensity > 4) ||
          (edgeDensity > 8 && plantPct > 8) ||
          (plantPct >= 55 && edgeDensity >= 2.5);

      // Canonical confidence formula (from ai_analysis_service.dart)
      final confidence = (plantPct * 0.7) + (edgeDensity * 0.3);

      debugPrint('🍃 LeafDetector: '
          'green=${greenPct.toStringAsFixed(1)}% '
          'warm=${warmPct.toStringAsFixed(1)}% '
          'plant=${plantPct.toStringAsFixed(1)}% '
          'edge=${edgeDensity.toStringAsFixed(1)}% '
          'isLeaf=$isLeaf');

      return {
        'isLeaf': isLeaf,
        'confidence': confidence,
        'greenPercentage': greenPct,
        'warmPercentage': warmPct,
        'plantPercentage': plantPct,
        'edgeDensity': edgeDensity,
        'message': isLeaf
            ? 'Image appears to be a plant leaf'
            : 'Image does not appear to be a plant leaf',
      };
    } catch (e) {
      debugPrint('❌ LeafDetector error: $e');
      return {
        'isLeaf': true,
        'confidence': 50.0,
        'message': 'Detection error',
      };
    }
  }
}
