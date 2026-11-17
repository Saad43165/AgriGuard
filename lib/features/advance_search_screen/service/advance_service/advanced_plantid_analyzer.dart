import 'dart:io';
import 'package:flutter/foundation.dart';
import '../plantid/plant_id_api_service.dart';
import 'advanced_symptom_lookup.dart';

class AdvancedPlantIdAnalyzer {
  final PlantIdService _plantIdService;
  final AdvancedSymptomLookup _symptomLookup = AdvancedSymptomLookup();

  AdvancedPlantIdAnalyzer({
    required PlantIdService plantIdService,
  }) : _plantIdService = plantIdService;

  Future<Map<String, dynamic>> analyze(File imageFile) async {
    try {
      debugPrint('🌿 Starting Plant.id API analysis...');

      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final result = await _plantIdService.analyzeWithPlantId(imageFile);

      if (result['success'] == true) {
        return result;
      } else {
        final errorMsg = result['message'] ?? result['error'] ?? 'Plant.id failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Plant.id error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _symptomLookup.getPlantIdErrorMessage(e),
        'source': 'Plant.id AI',
      };
    }
  }
}