import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Kindwise Crop Health API client (PlantHealth).
/// Base URL: https://crop.kindwise.com/api/v1
class PlantHealthApiService {
  static const String _baseUrl = 'https://crop.kindwise.com/api/v1';

  String? get _apiKey => dotenv.env['PLANTHEALTH_API_KEY']?.trim();

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<Map<String, dynamic>> identify(File imageFile) async {
    if (!hasApiKey) {
      return {
        'success': false,
        'error': 'Missing PLANTHEALTH_API_KEY',
        'message': 'PlantHealth API key not configured.',
        'source': 'PlantHealth AI',
      };
    }

    try {
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'error': 'Image file not found',
          'source': 'PlantHealth AI',
        };
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      debugPrint('🌿 Calling PlantHealth API: POST $_baseUrl/identification');

      final resp = await http
          .post(
        Uri.parse('$_baseUrl/identification'),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _apiKey!,
        },
        body: jsonEncode({
          'images': [base64Image],
          'similar_images': true,
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;

        if (accessToken == null) {
          // Try parsing immediate result
          return _parseImmediateResult(data);
        }

        return await _pollForResult(accessToken);
      }

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        return {
          'success': false,
          'error': 'Invalid API key',
          'message': 'PlantHealth API key is invalid. Check PLANTHEALTH_API_KEY.',
          'source': 'PlantHealth AI',
        };
      }

      if (resp.statusCode == 429) {
        return {
          'success': false,
          'error': 'Rate limit',
          'message': 'PlantHealth rate limit reached. Try again later.',
          'source': 'PlantHealth AI',
        };
      }

      return {
        'success': false,
        'error': 'HTTP ${resp.statusCode}',
        'message':
        'PlantHealth error: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
        'source': 'PlantHealth AI',
      };
    } catch (e) {
      debugPrint('❌ PlantHealth error: $e');
      return {
        'success': false,
        'error': 'Request failed',
        'message': e.toString().contains('TimeoutException')
            ? 'PlantHealth request timed out. Check internet connection.'
            : 'PlantHealth error: $e',
        'source': 'PlantHealth AI',
      };
    }
  }

  Future<Map<String, dynamic>> _pollForResult(String accessToken) async {
    const maxAttempts = 20;
    int delaySeconds = 1;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint('🔄 PlantHealth polling attempt $attempt/$maxAttempts (wait: ${delaySeconds}s)...');

      try {
        final uri = Uri.parse('$_baseUrl/identification/$accessToken').replace(
          queryParameters: {
            'language': 'en',
            'details': 'treatment,symptoms,wiki_description',
          },
        );

        final response = await http.get(
          uri,
          headers: {'Api-Key': _apiKey!},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final status = data['status'] as String?;
          final isFinished = data['finished'] as bool? ?? false;

          if (isFinished || status == 'COMPLETED' || status == 'completed') {
            return _parseImmediateResult(data);
          }

          if (status == 'FAILED' || status == 'failed' || status == 'ERROR' || status == 'error') {
            final errorMsg = data['error'] as String? ?? data['message'] as String? ?? 'Unknown error';
            throw Exception('Identification failed: $errorMsg');
          }
        }
      } catch (e) {
        if (attempt >= maxAttempts) {
          return {
            'success': false,
            'error': 'Poll failed',
            'message': e.toString(),
            'source': 'PlantHealth AI',
          };
        }
      }

      await Future.delayed(Duration(seconds: delaySeconds));
      if (attempt < 3) {
        delaySeconds = 2;
      } else if (attempt < 7) {
        delaySeconds = 3;
      } else if (attempt < 12) {
        delaySeconds = 4;
      } else {
        delaySeconds = 5;
      }
    }

    return {
      'success': false,
      'error': 'Timeout',
      'message': 'PlantHealth identification timeout after $maxAttempts attempts.',
      'source': 'PlantHealth AI',
    };
  }

  Map<String, dynamic> _parseImmediateResult(Map<String, dynamic> data) {
    try {
      final result = data['result'] as Map<String, dynamic>? ?? {};

      // Plant identification from crop.suggestions
      final crop = result['crop'] as Map<String, dynamic>? ?? {};
      final cropSuggestions = crop['suggestions'] as List<dynamic>? ?? [];

      String plantName = 'Unknown Plant';
      double plantConfidence = 0.0;
      String scientificName = '';

      if (cropSuggestions.isNotEmpty) {
        final topCrop = cropSuggestions.first as Map<String, dynamic>;
        plantName = topCrop['name'] as String? ?? 'Unknown Plant';
        plantConfidence = (topCrop['probability'] as num?)?.toDouble() ?? 0.0;

        final details = topCrop['details'] as Map<String, dynamic>? ?? {};
        final commonNames = (details['common_names'] as List<dynamic>?)?.cast<String>() ?? [];
        if (commonNames.isNotEmpty) {
          plantName = commonNames.first;
        }
        scientificName = topCrop['name'] as String? ?? '';
      }

      // Disease detection from disease.suggestions
      final disease = result['disease'] as Map<String, dynamic>? ?? {};
      final diseaseSuggestions = disease['suggestions'] as List<dynamic>? ?? [];

      String diseaseName = 'Healthy';
      double diseaseConfidence = 0.0;

      if (diseaseSuggestions.isNotEmpty) {
        final topDisease = diseaseSuggestions.first as Map<String, dynamic>;
        diseaseName = topDisease['name'] as String? ?? 'Unknown Disease';
        diseaseConfidence = (topDisease['probability'] as num?)?.toDouble() ?? 0.0;
      }

      if (diseaseName.toLowerCase() == 'healthy' || diseaseName.toLowerCase() == 'normal') {
        diseaseName = 'Healthy';
      }

      final isHealthy = diseaseName.toLowerCase() == 'healthy';
      final overallConfidence = ((isHealthy ? plantConfidence : diseaseConfidence) * 100).round();

      // Build predictions list
      final allPreds = diseaseSuggestions.take(5).map((p) {
        final dName = (p['name'] as String? ?? '');
        final dProb = ((p['probability'] as num?)?.toDouble() ?? 0.0) * 100;
        return {
          'label': '$plantName - $dName',
          'confidence': dProb.toStringAsFixed(1),
        };
      }).toList();

      if (allPreds.isEmpty && !isHealthy) {
        allPreds.add({
          'label': '$plantName - $diseaseName',
          'confidence': overallConfidence.toStringAsFixed(1),
        });
      }

      return {
        'success': true,
        'source': 'PlantHealth AI',
        'plantName': plantName,
        'scientificName': scientificName,
        'diseaseName': diseaseName,
        'confidence': overallConfidence.toDouble(),
        'predictions': allPreds,
        'rawData': data,
      };
    } catch (e, st) {
      debugPrint('❌ PlantHealth parse error: $e\n$st');
      return {
        'success': false,
        'error': 'Parse error',
        'message': 'Failed to parse PlantHealth response: $e',
        'source': 'PlantHealth AI',
      };
    }
  }

  /// Test if PlantHealth API is working
  Future<bool> testApi() async {
    try {
      debugPrint('🌿 Testing PlantHealth API connectivity...');
      final apiKey = _apiKey;
      if (apiKey == null || apiKey.isEmpty) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl/usage_info'),
        headers: {'Api-Key': apiKey},
      ).timeout(const Duration(seconds: 10));

      debugPrint('🌿 PlantHealth Connectivity Test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ PlantHealth connectivity test error: $e');
      return false;
    }
  }
}
