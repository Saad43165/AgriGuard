import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';
import 'plant_id_service.dart';

class AdvancedSearchService {
  final PlantIdService _plantIdService = PlantIdService();
  final GeminiService _geminiService = GeminiService();

  Future<bool> testGeminiApi() async {
    try {
      return await _geminiService.testGeminiApi();
    } catch (e) {
      debugPrint('❌ Gemini API test error: $e');
      return false;
    }
  }

  Future<bool> testPlantIdApi() async {
    try {
      return await _plantIdService.testPlantIdApi();
    } catch (e) {
      debugPrint('❌ Plant.id API test error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> testAllApis() async {
    debugPrint('🔍 Testing all APIs...');

    final geminiTest = await testGeminiApi();
    final plantIdTest = await testPlantIdApi();

    debugPrint('📊 API Status: Gemini=${geminiTest ? "✅" : "❌"}, Plant.id=${plantIdTest ? "✅" : "❌"}');

    return {
      'success': geminiTest || plantIdTest,
      'gemini': {
        'available': geminiTest,
        'status': geminiTest ? '✅ Ready' : '❌ Unavailable',
        'message': geminiTest ? 'Gemini Vision AI ready' : 'Check API key',
      },
      'plantId': {
        'available': plantIdTest,
        'status': plantIdTest ? '✅ Ready' : '❌ Unavailable',
      },
      'message': geminiTest || plantIdTest
          ? 'At least one API is available'
          : 'No APIs are currently available',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Gemini analysis only
  Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    debugPrint('🌿 Starting Gemini analysis...');

    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      // Only Gemini - no fallback
      final geminiResult = await _geminiService.analyzeWithGemini(imageFile);

      debugPrint('📊 Gemini result success: ${geminiResult['success']}');

      if (geminiResult['success'] == true) {
        debugPrint('✅ Gemini analysis successful');
        return geminiResult;
      } else {
        // If Gemini fails, return its error
        final errorMsg = geminiResult['message'] ?? geminiResult['error'] ?? 'Gemini analysis failed';
        debugPrint('❌ Gemini failed: $errorMsg');
        return {
          'success': false,
          'error': 'Gemini Analysis Failed',
          'message': errorMsg,
          'source': 'Gemini Vision AI',
        };
      }
    } catch (e) {
      debugPrint('❌ Gemini error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getGeminiErrorMessage(e),
        'source': 'Gemini Vision AI',
      };
    }
  }

  /// Plant.id analysis only
  Future<Map<String, dynamic>> analyzeWithPlantId(File imageFile) async {
    try {
      debugPrint('🌿 Starting Plant.id API analysis...');

      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final result = await _plantIdService.analyzeWithPlantId(imageFile);

      if (result['success'] == true) {
        debugPrint('✅ Plant.id success');
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          debugPrint('📊 Plant: ${data['plantName']}');
          debugPrint('🔬 Disease: ${data['diseaseName']}');
          debugPrint('⚠️ Severity: ${data['severity']}');
          debugPrint('💯 Confidence: ${data['confidence']}%');
        }
        return result;
      } else {
        final errorMsg = result['message'] ?? result['error'] ?? 'Plant.id failed';
        debugPrint('❌ Plant.id failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Plant.id error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getPlantIdErrorMessage(e),
        'source': 'Plant.id AI',
      };
    }
  }

  Future<Map<String, dynamic>> _getPlantIdCreditsInfo() async {
    try {
      return await _plantIdService.getApiStatus();
    } catch (e) {
      return {'error': 'Unable to fetch credits info'};
    }
  }

  String _getGeminiErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('api_key') || errorStr.contains('401') || errorStr.contains('403')) {
      return 'Invalid Gemini API key. Check your API key.';
    }
    if (errorStr.contains('429')) {
      return 'Gemini rate limit reached. Try again later.';
    }
    if (errorStr.contains('timeout')) {
      return 'Gemini request timed out. Check internet connection.';
    }
    if (errorStr.contains('quota')) {
      return 'Gemini API quota exceeded. Check usage limits.';
    }

    return 'Gemini analysis failed: $errorStr';
  }

  String _getPlantIdErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('402') || errorStr.contains('credits exhausted')) {
      return 'Plant.id credits exhausted. Please use Gemini analysis instead.';
    }
    if (errorStr.contains('api_key') || errorStr.contains('401')) {
      return 'Invalid Plant.id API key.';
    }
    if (errorStr.contains('timeout')) {
      return 'Plant.id request timed out.';
    }

    return 'Plant.id analysis failed: $errorStr';
  }

  Future<Map<String, dynamic>> getDetailedApiStatus() async {
    debugPrint('📊 Getting detailed API status...');

    try {
      final plantIdStatus = await _plantIdService.getApiStatus();
      final plantIdTest = await testPlantIdApi();
      final geminiTest = await testGeminiApi();

      return {
        'success': true,
        'gemini': {
          'available': geminiTest,
          'status': geminiTest ? '✅ Ready' : 'Unavailable',
          'message': geminiTest
              ? 'Gemini Vision AI active'
              : 'Check Gemini API key',
        },
        'plantId': plantIdStatus,
        'recommendation': geminiTest
            ? 'Using Gemini Vision AI (powerful image analysis)'
            : 'Use Plant.id. ${plantIdStatus['remaining']?['total'] ?? 'Unknown'} credits left.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Status error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> isAnyApiAvailable() async {
    final gemini = await testGeminiApi();
    final plantId = await testPlantIdApi();
    return gemini || plantId;
  }

  Map<String, dynamic> getApiRecommendations() {
    return {
      'primary': 'Gemini',
      'status': 'Vision AI Model (✅ if API key is valid)',
      'secondary': 'Plant.id',
      'secondary_status': '✅ Working',
      'credits': 'Gemini offers free tier with usage limits',
      'action_required': 'Ensure Gemini API key is valid',
      'documentation': 'https://ai.google.dev/gemini-api/docs/',
    };
  }
}