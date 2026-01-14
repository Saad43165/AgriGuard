// lib/services/ai_analysis_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'plant_id_service.dart';
import 'disease_id_service.dart';

class AIAnalysisService {
  final PlantIdService _plantIdService;
  final DiseaseIdService _diseaseIdService;

  AIAnalysisService(this._plantIdService, this._diseaseIdService);

  Future<Map<String, dynamic>> analyzePlantImage(File imageFile) async {
    try {
      debugPrint('🔬 Starting comprehensive plant analysis...');
      final stopwatch = Stopwatch()..start();

      // Run both analyses in parallel
      final results = await Future.wait([
        _plantIdService.predict(imageFile),
        _diseaseIdService.predict(imageFile),
      ]);

      final plantResult = results[0];
      final diseaseResult = results[1];

      stopwatch.stop();

      // Extract key information
      final plantName = plantResult['label'] as String? ?? 'Unknown';
      final plantConfidence = plantResult['confidence'] as double? ?? 0.0;
      final plantIsUnknown = plantResult['isUnknown'] as bool? ?? true;

      final diseasePlantName = diseaseResult['plantName'] as String? ?? 'Unknown';
      final diseaseName = diseaseResult['diseaseName'] as String? ?? 'Unknown';
      final diseaseConfidence = double.tryParse(diseaseResult['confidence']?.toString() ?? '0') ?? 0.0;
      final isHealthy = diseaseResult['isHealthy'] as bool? ?? false;

      debugPrint('\n📊 ANALYSIS RESULTS:');
      debugPrint('  Plant ID: $plantName (${(plantConfidence * 100).toStringAsFixed(1)}%)');
      debugPrint('  Disease Model Plant: $diseasePlantName');
      debugPrint('  Disease: $diseaseName (${diseaseConfidence.toStringAsFixed(1)}%)');

      // Check for plant name mismatch
      final hasMismatch = _checkPlantMismatch(plantName, diseasePlantName, plantIsUnknown);

      if (hasMismatch) {
        debugPrint('⚠️ MISMATCH DETECTED: Plant ID says "$plantName", Disease model says "$diseasePlantName"');
      }

      // Determine final plant name with confidence-based priority
      final finalPlantName = _resolvePlantName(
        plantName,
        diseasePlantName,
        plantConfidence,
        diseaseConfidence / 100.0, // Convert percentage back to decimal
        plantIsUnknown,
      );

      debugPrint('✅ Final plant determination: $finalPlantName');

      // Build comprehensive result
      final result = {
        // Primary identification
        'plantName': finalPlantName,
        'diseaseName': diseaseName,
        'isHealthy': isHealthy,

        // Confidence metrics
        'plantConfidence': plantConfidence,
        'diseaseConfidence': diseaseConfidence,
        'confidenceGap': plantResult['confidenceGap'] ?? 0.0,

        // Status flags
        'isUnknown': plantIsUnknown,
        'hasMismatch': hasMismatch,
        'lowConfidence': plantConfidence < 0.40 || diseaseConfidence < 40.0,

        // Detailed predictions
        'plantPredictions': plantResult['allPredictions'] ?? [],
        'diseasePredictions': diseaseResult['allPredictions'] ?? [],

        // Disease information
        'severity': diseaseResult['severity'] ?? 'Unknown',
        'cause': diseaseResult['cause'] ?? '',
        'symptoms': diseaseResult['symptoms'] ?? [],
        'remediation': diseaseResult['remediation'] ?? [],
        'precautions': diseaseResult['precautions'] ?? [],

        // Metadata
        'totalInferenceTime': stopwatch.elapsedMilliseconds,
        'plantInferenceTime': plantResult['inferenceTime'] ?? 0,
        'diseaseInferenceTime': diseaseResult['inferenceTime'] ?? 0,
        'normalizationScheme': plantResult['normalizationScheme'] ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),

        // Raw results for debugging
        'rawPlantResult': plantResult,
        'rawDiseaseResult': diseaseResult,

        // Warnings
        'warnings': _generateWarnings(
          hasMismatch,
          plantConfidence,
          diseaseConfidence / 100.0,
          plantIsUnknown,
          plantName,
          diseasePlantName,
        ),

        'success': true,
      };

      debugPrint('⏱️ Total analysis time: ${stopwatch.elapsedMilliseconds}ms');

      return result;

    } catch (e, stackTrace) {
      debugPrint('❌ Analysis failed: $e');
      debugPrint('Stack trace: $stackTrace');

      return {
        'success': false,
        'plantName': 'Analysis Failed',
        'diseaseName': 'Unable to Analyze',
        'error': e.toString(),
        'isHealthy': false,
        'isUnknown': true,
        'warnings': ['Analysis encountered an error: ${e.toString()}'],
      };
    }
  }

  bool _checkPlantMismatch(String plantIdResult, String diseaseModelPlant, bool plantIsUnknown) {
    // Don't flag mismatch if plant ID is unknown/uncertain
    if (plantIsUnknown || plantIdResult == 'Unknown') {
      return false;
    }

    // Normalize names for comparison
    final normalizedPlantId = _normalizePlantName(plantIdResult);
    final normalizedDisease = _normalizePlantName(diseaseModelPlant);

    // Check if they match
    return normalizedPlantId != normalizedDisease &&
        normalizedDisease != 'unknown' &&
        normalizedDisease.isNotEmpty;
  }

  String _normalizePlantName(String name) {
    return name.toLowerCase()
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('_', ' ')
        .trim();
  }

  String _resolvePlantName(
      String plantIdName,
      String diseaseModelPlant,
      double plantConfidence,
      double diseaseConfidence,
      bool plantIsUnknown,
      ) {
    // If plant ID is unknown or very low confidence, use disease model's plant name
    if (plantIsUnknown || plantConfidence < 0.35) {
      if (diseaseModelPlant != 'Unknown' && diseaseModelPlant.isNotEmpty) {
        debugPrint('🔄 Using disease model plant name (plant ID is uncertain)');
        return diseaseModelPlant;
      }
      return 'Unknown Plant';
    }

    // If disease model plant is unknown, use plant ID
    if (diseaseModelPlant == 'Unknown' || diseaseModelPlant.isEmpty) {
      return plantIdName;
    }

    // Both models agree - great!
    if (_normalizePlantName(plantIdName) == _normalizePlantName(diseaseModelPlant)) {
      return plantIdName; // Use the cleaner formatted version from plant ID
    }

    // They disagree - use confidence to decide
    if (plantConfidence > diseaseConfidence + 0.15) {
      // Plant ID model is significantly more confident
      debugPrint('🔄 Using plant ID result (higher confidence: ${(plantConfidence * 100).toStringAsFixed(1)}% vs ${(diseaseConfidence * 100).toStringAsFixed(1)}%)');
      return plantIdName;
    } else if (diseaseConfidence > plantConfidence + 0.15) {
      // Disease model is significantly more confident
      debugPrint('🔄 Using disease model result (higher confidence: ${(diseaseConfidence * 100).toStringAsFixed(1)}% vs ${(plantConfidence * 100).toStringAsFixed(1)}%)');
      return diseaseModelPlant;
    } else {
      // Confidences are similar - disease model is usually more reliable for species
      // since it's trained on specific plant diseases
      debugPrint('🔄 Using disease model result (similar confidence, disease model more specific)');
      return diseaseModelPlant;
    }
  }

  List<String> _generateWarnings(
      bool hasMismatch,
      double plantConfidence,
      double diseaseConfidence,
      bool plantIsUnknown,
      String plantIdResult,
      String diseaseModelPlant,
      ) {
    final warnings = <String>[];

    if (hasMismatch) {
      warnings.add(
          'Plant identification mismatch detected: Plant ID suggests "$plantIdResult" '
              'but disease model suggests "$diseaseModelPlant". Using higher confidence result.'
      );
    }

    if (plantConfidence < 0.40 && !plantIsUnknown) {
      warnings.add(
          'Plant identification confidence is low (${(plantConfidence * 100).toStringAsFixed(1)}%). '
              'Consider taking a clearer photo or capturing different angles.'
      );
    }

    if (diseaseConfidence < 40.0) {
      warnings.add(
          'Disease detection confidence is low (${diseaseConfidence.toStringAsFixed(1)}%). '
              'The disease diagnosis may not be accurate.'
      );
    }

    if (plantIsUnknown) {
      warnings.add(
          'Plant species could not be identified with confidence. '
              'This may be a species outside the model\'s training data.'
      );
    }

    // Special warning for Cedar_Apple_Rust (it's a disease, not a plant)
    if (plantIdResult.toLowerCase().contains('rust') ||
        plantIdResult.toLowerCase().contains('cedar_apple_rust')) {
      warnings.add(
          'Model confusion detected: "$plantIdResult" is a disease name, not a plant species. '
              'The plant identification model may need retraining.'
      );
    }

    return warnings;
  }

  // Helper method to get user-friendly explanation
  String getAnalysisSummary(Map<String, dynamic> result) {
    if (result['success'] != true) {
      return 'Analysis failed: ${result['error'] ?? 'Unknown error'}';
    }

    final plantName = result['plantName'] as String;
    final diseaseName = result['diseaseName'] as String;
    final isHealthy = result['isHealthy'] as bool;
    final severity = result['severity'] as String?;
    final warnings = result['warnings'] as List? ?? [];

    final buffer = StringBuffer();

    // Plant identification
    if (result['isUnknown'] == true) {
      buffer.writeln('🔍 Unable to identify plant species with confidence.');
    } else {
      buffer.writeln('🌱 Identified as: $plantName');
      final confidence = ((result['plantConfidence'] as double) * 100).toStringAsFixed(1);    }

    // Health status
    buffer.writeln();
    if (isHealthy) {
      buffer.writeln('✅ Plant appears healthy!');
    } else {
      buffer.writeln('⚠️ Disease detected: $diseaseName');
      if (severity != null && severity != 'Unknown') {
        buffer.writeln('   Severity: $severity');
      }
      final diseaseConf = result['diseaseConfidence']?.toString() ?? '0';
      buffer.writeln('   Confidence: $diseaseConf%');
    }

    // Warnings
    if (warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚠️ Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  • $warning');
      }
    }

    return buffer.toString();
  }
}