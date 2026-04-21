import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DataParsers {
  static List<String> parseStringToList(dynamic input) {
    if (input == null) return [];
    if (input is List) return List<String>.from(input);
    if (input is String) {
      return input
          .split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static double parseConfidence(dynamic confidence) {
    if (confidence is double) return confidence;
    if (confidence is int) return confidence.toDouble();
    if (confidence is String) {
      return double.tryParse(confidence.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }

  static Future<String?> getImageBase64(String? imagePath, String? imageBase64) async {
    if (imageBase64 != null) return imageBase64;

    if (imagePath != null) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to convert image: $e');
      }
    }
    return null;
  }

  static String generateScanId(Map<String, dynamic> data, String prefix) {
    final hash = jsonEncode({
      'plant': data['plantName'],
      'disease': data['diseaseName'],
      'confidence': data['confidence'],
      'image': data['imagePath']?.hashCode ?? 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).hashCode.abs();

    return '$prefix${hash}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool isDuplicateError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('duplicate') ||
        errorString.contains('already exists');
  }
}