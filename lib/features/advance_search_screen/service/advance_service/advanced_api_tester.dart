import 'package:flutter/foundation.dart';

import '../groq/groq_service.dart';
import '../plantid/plant_id_api_service.dart';

class AdvancedApiTester {
  final GroqService _groqService;
  final PlantIdService _plantIdService;

  AdvancedApiTester({
    required GroqService groqService,
    required PlantIdService plantIdService,
  })  : _groqService = groqService,
        _plantIdService = plantIdService;

  Future<bool> testGroqApi() async {
    try {
      return await _groqService.testGroqApi();
    } catch (e) {
      debugPrint('❌ Groq API test error: $e');
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

    final groqKeyPresent = _groqService.hasApiKey();
    final groqTest = groqKeyPresent ? await testGroqApi() : false;

    final plantIdKeyPresent = _plantIdService.hasApiKey();
    Map<String, dynamic>? plantIdStatus;
    bool plantIdUsable = false;
    String? plantIdReason;

    if (plantIdKeyPresent) {
      plantIdStatus = await _plantIdService.getApiStatus();
      final details = plantIdStatus['details'];
      if (details is Map && details['can_use_credits'] is Map) {
        final cuc = details['can_use_credits'] as Map;
        plantIdUsable = cuc['value'] == true;
        plantIdReason = cuc['reason']?.toString();
      } else {
        plantIdUsable = await testPlantIdApi();
      }
    }

    debugPrint('📊 API Status: Groq=${groqTest ? "✅" : "❌"}, Plant.id=${plantIdUsable ? "✅" : "❌"}');

    return {
      'success': groqKeyPresent || plantIdUsable,
      'groq': {
        'available': groqKeyPresent,
        'status': groqKeyPresent
            ? (groqTest ? '✅ Ready' : '⚠️ Key set (network/API check failed)')
            : '❌ Unavailable',
        'message': groqKeyPresent
            ? (groqTest ? 'Groq AI ready' : 'Groq key is set. Check internet/network.')
            : 'Set GROQ_API_KEY in .env',
      },
      'plantId': {
        'available': plantIdUsable,
        'status': plantIdUsable ? '✅ Ready' : '❌ Unavailable',
        'message': plantIdUsable
            ? 'Plant.id ready'
            : (plantIdKeyPresent
            ? (plantIdReason?.isNotEmpty == true ? plantIdReason : 'Plant.id credits unavailable')
            : 'Set PLANTID_API_KEY in .env'),
        'details': plantIdStatus?['details'],
      },
      'message': groqKeyPresent || plantIdUsable
          ? 'At least one API is available'
          : 'No APIs are currently available',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}