import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Pixel-Based Damage Analyzer
///
/// Actually measures severity by counting damaged vs healthy pixels.
/// This is the REAL severity measurement system.
class SeverityPixelAnalyzer {

  static const double criticalThreshold = 50.0;  // 50%+ damage = Critical
  static const double highThreshold = 30.0;      // 30%+ damage = High
  static const double mediumThreshold = 10.0;    // 10%+ damage = Medium
  // Below 10% = Low

  /// Main analysis — returns damage percentage and severity level
  Map<String, dynamic> analyze(img.Image leafImage, String diseaseName) {
    int totalPixels = 0;
    int damagedPixels = 0;
    int healthyPixels = 0;
    int lesionPixels = 0;

    for (int y = 0; y < leafImage.height; y++) {
      for (int x = 0; x < leafImage.width; x++) {
        final pixel = leafImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        totalPixels++;

        // Count healthy green tissue
        if (g > r && g > b && g > 80) {
          healthyPixels++;
        }

        // Count damaged tissue
        if (_isDamaged(r, g, b, diseaseName)) {
          damagedPixels++;
        }

        // Count distinct lesions
        if (_isLesion(r, g, b, diseaseName)) {
          lesionPixels++;
        }
      }
    }

    final damagePercent = totalPixels > 0
        ? (damagedPixels / totalPixels) * 100
        : 0.0;

    final healthyPercent = totalPixels > 0
        ? (healthyPixels / totalPixels) * 100
        : 0.0;

    // Determine severity from damage percentage
    String severityLevel;
    if (damagePercent >= criticalThreshold) {
      severityLevel = 'Critical';
    } else if (damagePercent >= highThreshold) {
      severityLevel = 'High';
    } else if (damagePercent >= mediumThreshold) {
      severityLevel = 'Medium';
    } else {
      severityLevel = 'Low';
    }

    debugPrint('🔬 Pixel Analysis:');
    debugPrint('   Healthy: ${healthyPercent.toStringAsFixed(1)}%');
    debugPrint('   Damaged: ${damagePercent.toStringAsFixed(1)}%');
    debugPrint('   Lesions: ${((lesionPixels / (totalPixels > 0 ? totalPixels : 1)) * 100).toStringAsFixed(1)}%');
    debugPrint('   Severity: $severityLevel');

    return {
      'damagePercent': damagePercent,
      'healthyPercent': healthyPercent,
      'severityFromPixels': severityLevel,
      'totalPixels': totalPixels,
    };
  }

  /// Check if pixel represents damaged tissue
  bool _isDamaged(int r, int g, int b, String diseaseName) {
    final d = diseaseName.toLowerCase();

    // Brown/necrotic (dead tissue)
    if (r > 100 && r < 180 && g > 50 && g < 140 && b < 80 && r > g) return true;

    // Yellow/chlorotic (dying)
    if (r > 180 && g > 150 && b < 80) return true;

    // White/bleached (severe)
    if (r > 200 && g > 200 && b > 200) return true;

    // Disease-specific patterns
    if (d.contains('blight') && r < 80 && g < 60 && b < 50) return true;
    if (d.contains('rust') && r > 140 && g > 70 && g < 140 && b < 70) return true;
    if (d.contains('powdery mildew') && r > 220 && g > 220 && b > 220) return true;

    return false;
  }

  /// Check if pixel is a distinct lesion/spot
  bool _isLesion(int r, int g, int b, String diseaseName) {
    // Dark spots (common in many diseases)
    if (r < 60 && g < 50 && b < 40) return true;

    // Rust pustules
    if (diseaseName.toLowerCase().contains('rust') && r > 160 && g < 100 && b < 60) return true;

    return false;
  }
}