// roboflow_service.dart (replaces plantnet_api_service.dart)
//
// Calls Roboflow Serverless Inference API directly from Flutter.
// Model: plant-disease-detection-v2-2nclk/1
// API:   https://serverless.roboflow.com
//
// No server needed — Roboflow handles inference in the cloud.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PlantNetApiService {
  static const String _baseUrl = 'https://serverless.roboflow.com';

  String? get _apiKey => dotenv.env['ROBOFLOW_INFER_API_KEY']?.trim();
  String get _modelId =>
      dotenv.env['ROBOFLOW_MODEL_ID']?.trim() ??
      'plant-disease-detection-v2-2nclk/1';

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Identify plant disease from image using Roboflow Serverless API.
  Future<Map<String, dynamic>> identify(File imageFile) async {
    if (!hasApiKey) {
      return {
        'success': false,
        'error': 'Missing ROBOFLOW_INFER_API_KEY',
        'message': 'Roboflow API key not configured.',
        'source': 'Roboflow AI',
      };
    }

    try {
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'error': 'Image file not found',
          'source': 'Roboflow AI',
        };
      }

      // Roboflow serverless: POST image as base64 to /model_id?api_key=KEY
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final uri = Uri.parse('$_baseUrl/$_modelId?api_key=$_apiKey');
      debugPrint('🌿 Calling Roboflow API: $uri');

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      ).timeout(const Duration(seconds: 30));

      debugPrint('🌿 Roboflow response: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List? ?? [];

        if (predictions.isEmpty) {
          return {
            'success': false,
            'error': 'No predictions',
            'message': 'Roboflow could not detect any disease in this image.',
            'source': 'Roboflow AI',
          };
        }

        // Sort by confidence descending
        predictions.sort((a, b) =>
            ((b['confidence'] as num?) ?? 0)
                .compareTo((a['confidence'] as num?) ?? 0));

        final top = predictions.first as Map<String, dynamic>;
        final disease = top['class']?.toString() ?? 'Unknown';
        final confidence = ((top['confidence'] as num?)?.toDouble() ?? 0.0) * 100;

        debugPrint('✅ Roboflow raw label: "$disease" (${confidence.toStringAsFixed(1)}%)');

        // Parse plant name from disease label
        // Roboflow labels can be: "Tomato___Early_blight", "Tomato Early blight",
        // "Tomato_Early_blight", or just "Early_blight"
        String plantName = 'Unknown Plant';
        String diseaseName = disease;

        if (disease.contains('___')) {
          // PlantVillage format: "Tomato___Early_blight"
          final parts = disease.split('___');
          plantName = parts[0].replaceAll('_', ' ').trim();
          diseaseName = parts.length > 1
              ? parts[1].replaceAll('_', ' ').trim()
              : 'Unknown';
        } else {
          // Try to match known plant names at the start of the label
          const knownPlants = [
            'Tomato', 'Apple', 'Grape', 'Corn', 'Potato', 'Strawberry',
            'Peach', 'Cherry', 'Pepper', 'Soybean', 'Squash', 'Raspberry',
            'Orange', 'Blueberry', 'Wheat', 'Bean', 'Apricot', 'Fig',
            'Walnut', 'Pear', 'Persimmon', 'Loquat',
          ];
          final diseaseLower = disease.toLowerCase();
          String? matchedPlant;
          for (final p in knownPlants) {
            if (diseaseLower.startsWith(p.toLowerCase())) {
              matchedPlant = p;
              break;
            }
          }
          if (matchedPlant != null) {
            plantName = matchedPlant;
            diseaseName = disease.substring(matchedPlant.length)
                .replaceAll('_', ' ')
                .replaceAll('-', ' ')
                .trim();
            if (diseaseName.isEmpty) diseaseName = 'Healthy';
          } else {
            // No plant prefix found — treat whole label as disease
            plantName = 'Plant';
            diseaseName = disease.replaceAll('_', ' ').trim();
          }
        }

        if (diseaseName.toLowerCase() == 'healthy' ||
            diseaseName.toLowerCase() == 'normal') {
          diseaseName = 'Healthy';
        }

        // Build all predictions
        final allPreds = predictions.take(5).map((p) => {
          'label': p['class']?.toString() ?? '',
          'confidence':
              (((p['confidence'] as num?)?.toDouble() ?? 0.0) * 100)
                  .toStringAsFixed(1),
        }).toList();

        return {
          'success': true,
          'source': 'Roboflow AI',
          'plantName': plantName,
          'scientificName': '',
          'diseaseName': diseaseName,
          'confidence': confidence,
          'predictions': allPreds,
          'rawData': data,
        };
      }

      debugPrint('❌ Roboflow error body: ${resp.body}');

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return {
          'success': false,
          'error': 'Invalid API key',
          'message': 'Roboflow API key is invalid. Check ROBOFLOW_INFER_API_KEY.',
          'source': 'Roboflow AI',
        };
      }

      if (resp.statusCode == 429) {
        return {
          'success': false,
          'error': 'Rate limit',
          'message': 'Roboflow rate limit reached. Try again later.',
          'source': 'Roboflow AI',
        };
      }

      return {
        'success': false,
        'error': 'HTTP ${resp.statusCode}',
        'message': 'Roboflow error: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
        'source': 'Roboflow AI',
      };
    } catch (e) {
      debugPrint('❌ Roboflow error: $e');
      return {
        'success': false,
        'error': 'Request failed',
        'message': e.toString().contains('TimeoutException')
            ? 'Roboflow request timed out. Check internet connection.'
            : 'Roboflow error: $e',
        'source': 'Roboflow AI',
      };
    }
  }
}
