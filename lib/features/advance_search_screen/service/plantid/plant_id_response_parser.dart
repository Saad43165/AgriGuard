import 'package:flutter/foundation.dart';
import 'plant_id_client.dart';
import 'plant_id_health_parser.dart';
import 'plant_id_results.dart';
import 'plant_id_helpers.dart';

class PlantIdResponseParser {
  final PlantIdHealthParser _healthParser = PlantIdHealthParser();
  final PlantIdResults _results = PlantIdResults();
  final PlantIdHelpers _helpers = PlantIdHelpers();

  Map<String, dynamic> parse(Map<String, dynamic> data) {
    try {
      debugPrint('🌿 Parsing Plant.id v3 response...');

      final result = data['result'] as Map<String, dynamic>? ?? {};

      // Check if plant detected
      final isPlant = result['is_plant'] as Map<String, dynamic>?;
      final isPlantBinary = isPlant?['binary'] as bool? ?? false;
      final isPlantProb = (isPlant?['probability'] as num?)?.toDouble() ?? 0.0;

      debugPrint('🔍 Is plant: $isPlantBinary (${(isPlantProb * 100).toStringAsFixed(1)}%)');

      if (!isPlantBinary) return _results.noPlantDetected();

      // Extract plant classification
      final classification = result['classification'] as Map<String, dynamic>? ?? {};
      final suggestions = classification['suggestions'] as List<dynamic>? ?? [];

      if (suggestions.isEmpty) return _results.unknownPlant();

      final topSuggestion = suggestions.first as Map<String, dynamic>;
      final plantName = topSuggestion['name'] as String? ?? 'Unknown Plant';
      final probability = (topSuggestion['probability'] as num?)?.toDouble() ?? 0.0;
      final confidence = (probability * 100).round();

      // Extract plant details
      final details = topSuggestion['details'] as Map<String, dynamic>? ?? {};
      final commonNames = (details['common_names'] as List<dynamic>?)?.cast<String>() ?? [];

      String description = 'Plant identified successfully';
      final desc = details['description'];
      if (desc is Map) description = desc['value']?.toString() ?? description;
      else if (desc is String) description = desc;

      debugPrint('✅ Plant: $plantName (${commonNames.isNotEmpty ? commonNames.first : "no common name"})');

      // Extract health assessment
      final health = _healthParser.extract(result);

      // Build result
      final analysisResult = {
        'plantName': commonNames.isNotEmpty ? commonNames.first : plantName,
        'scientificName': plantName,
        'diseaseName': health['diseaseName'],
        'severity': health['severity'],
        'confidence': confidence,
        'diseaseConfidence': ((health['diseaseProbability'] as double) * 100).round(),
        'symptoms': health['symptoms'],
        'remediation': health['treatments'],
        'precautions': health['precautions'],
        'additionalInfo': _helpers.buildAdditionalInfo(
          plantName: plantName,
          commonNames: commonNames,
          confidence: confidence,
          hasDiseaseInfo: health['hasDiseaseInfo'] as bool,
          diseaseName: health['diseaseName'] as String,
          diseaseProbability: health['diseaseProbability'] as double,
          description: description,
        ),
      };

      return {
        'success': true,
        'source': 'Plant.id AI',
        'data': analysisResult,
        'timestamp': DateTime.now().toIso8601String(),
        'isRealData': true,
        'hasDiseaseInfo': health['hasDiseaseInfo'],
        'hasHealthAssessment': true,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Parse error: $e');
      return _tryFallbackParse(data);
    }
  }

  Map<String, dynamic> _tryFallbackParse(Map<String, dynamic> data) {
    try {
      final result = data['result'] as Map<String, dynamic>? ?? {};
      final classification = result['classification'] as Map<String, dynamic>? ?? {};
      final suggestions = classification['suggestions'] as List<dynamic>? ?? [];

      if (suggestions.isNotEmpty) {
        final plantName = (suggestions.first as Map)['name']?.toString() ?? 'Unknown Plant';
        return _results.partialSuccess(plantName);
      }
    } catch (_) {}

    return _results.fallback();
  }
}