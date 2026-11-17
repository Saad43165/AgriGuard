import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/services/analysis/ai_analysis_service.dart';
import '../../../../core/services/severity/severity_id_service.dart';
import '../groq/groq_service.dart';
import 'advanced_symptom_lookup.dart';

class AdvancedGroqAnalyzer {
  final PlantAnalysisService _onDeviceAnalysis;
  final SeverityIdService _severityService;
  final GroqService _groqService;
  final AdvancedSymptomLookup _symptomLookup;

  AdvancedGroqAnalyzer({
    required PlantAnalysisService onDeviceAnalysis,
    required SeverityIdService severityService,
    required GroqService groqService,
    required AdvancedSymptomLookup symptomLookup,
  })  : _onDeviceAnalysis = onDeviceAnalysis,
        _severityService = severityService,
        _groqService = groqService,
        _symptomLookup = symptomLookup;

  Future<Map<String, dynamic>> analyze(File imageFile, {required bool inUrdu}) async {
    debugPrint('🌿 Starting Groq analysis (on top of on-device ML)...');

    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      // Run on-device analysis first
      final onDevice = await _onDeviceAnalysis.analyzePlant(imageFile);

      if (onDevice['success'] != true) {
        return {
          'success': false,
          'error': 'On-device analysis failed',
          'message': onDevice['error']?.toString() ?? 'Unable to analyze image on-device',
          'source': 'On-Device AI',
        };
      }

      if (onDevice['isLeaf'] == false) {
        return {
          'success': false,
          'isNonLeaf': true,
          'error': 'Not a plant leaf',
          'message': 'The image does not appear to be a plant leaf.',
          'source': 'Groq AI',
        };
      }

      final plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
      final diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
      final severity = onDevice['severity']?.toString() ??
          (diseaseName.toLowerCase() == 'healthy' ? 'None' : 'Unknown');
      final confidence = onDevice['confidence'] is num ? (onDevice['confidence'] as num) : 0;

      // Get severity from severity service
      final severityResult = await _severityService.getSeverityAndRemediation(
        diseaseName: diseaseName,
        plantName: plantName,
        confidence: confidence.toDouble(),
        imagePath: imageFile.path,
      );

      final finalSeverity = severityResult?['severity']?.toString() ?? severity;
      final remediation = severityResult?['remediation'] is List
          ? List<String>.from(severityResult!['remediation'])
          : <String>[];

      // Get Groq AI enhanced advice
      final groq = await _groqService.generateAgronomyAdvice(
        plantName: plantName,
        diseaseName: diseaseName,
        severity: finalSeverity,
        confidencePercent: confidence,
        inUrdu: inUrdu,
      );

      if (groq['success'] == true) {
        final data = (groq['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(groq['data'] as Map<String, dynamic>)
            : <String, dynamic>{};

        data['plantName'] = plantName;
        data['diseaseName'] = diseaseName;
        data['severity'] = finalSeverity;
        data['confidence'] = confidence.toString();
        data['remediation'] = remediation;

        return {
          'success': true,
          'source': 'Groq AI',
          'isRealData': true,
          'hasDiseaseInfo': diseaseName.toLowerCase() != 'healthy' &&
              diseaseName.toLowerCase() != 'unable to determine',
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
          'onDevice': onDevice,
        };
      }

      // Groq failed — return on-device result with lookup data
      final isHealthy = diseaseName.toLowerCase() == 'healthy';
      return {
        'success': true,
        'source': 'On-Device AI',
        'isRealData': true,
        'hasDiseaseInfo': !isHealthy,
        'data': {
          'plantName': plantName,
          'diseaseName': diseaseName,
          'confidence': confidence.toString(),
          'severity': finalSeverity,
          'cause': _symptomLookup.getCause(diseaseName),
          'symptoms': _symptomLookup.getSymptoms(diseaseName),
          'remediation': remediation.isNotEmpty
              ? remediation
              : ['Consult an agricultural expert', 'Remove affected leaves'],
          'precautions': const [
            'Monitor the plant daily for changes',
            'Avoid overhead watering if disease is suspected',
            'Improve air circulation around plants',
            'Disinfect tools between plants',
          ],
        },
        'timestamp': DateTime.now().toIso8601String(),
        'onDevice': onDevice,
      };
    } catch (e) {
      debugPrint('❌ Groq error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _symptomLookup.getGroqErrorMessage(e),
        'source': 'Groq AI',
      };
    }
  }
}