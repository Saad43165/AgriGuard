import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/services/analysis/ai_analysis_service.dart';
import '../../../core/services/severity/severity_id_service.dart';
import 'groq_service.dart';
import 'plant_id_api_service.dart';

class AdvancedSearchService {
  final GroqService _groqService = GroqService();
  final PlantAnalysisService _onDeviceAnalysis = PlantAnalysisService();
  final SeverityIdService _severityService = SeverityIdService();
  final PlantIdService _plantIdService = PlantIdService();

  // ── API Testing ──────────────────────────────────────────────────────────

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
            ? (groqTest
            ? 'Groq AI ready'
            : 'Groq key is set. If requests fail, check internet/network.')
            : 'Set GROQ_API_KEY in .env',
      },
      'plantId': {
        'available': plantIdUsable,
        'status': plantIdUsable ? '✅ Ready' : '❌ Unavailable',
        'message': plantIdUsable
            ? 'Plant.id ready'
            : (plantIdKeyPresent
            ? (plantIdReason?.isNotEmpty == true
            ? plantIdReason
            : 'Plant.id credits unavailable')
            : 'Set PLANTID_API_KEY in .env'),
        'details': plantIdStatus?['details'],
      },
      'message': groqKeyPresent || plantIdUsable
          ? 'At least one API is available'
          : 'No APIs are currently available',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<String> _lookupSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') {
      return const ['No visible symptoms', 'Normal leaf color and texture'];
    }
    if (l.contains('rust')) {
      return const ['Orange/yellow lesions', 'Rust-colored pustules', 'Premature leaf drop'];
    }
    if (l.contains('blight')) {
      return const ['Dark lesions on leaves', 'Yellowing around lesions', 'Rapid spread in humidity'];
    }
    if (l.contains('spot')) {
      return const ['Small circular spots', 'Yellow halos', 'Spots may merge over time'];
    }
    return const ['Leaf discoloration', 'Spots or lesions', 'Reduced plant vigor'];
  }

  String _lookupCause({required String diseaseName}) {
    final l = diseaseName.toLowerCase();
    if (l.contains('blight')) return 'Fungal or bacterial infection';
    if (l.contains('spot')) return 'Bacterial or fungal pathogens';
    if (l.contains('rust')) return 'Fungal rust disease';
    if (l.contains('mildew')) return 'Fungal mildew infection';
    if (l == 'healthy') return 'No disease detected';
    return 'Environmental factors or pathogen infection';
  }

  // ── Groq Analysis (on top of on-device ML) ──────────────────────────────

  Future<Map<String, dynamic>> analyzePlant(
      File imageFile, {
        required bool inUrdu,
      }) async {
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
          'cause': _lookupCause(diseaseName: diseaseName),
          'symptoms': _lookupSymptoms(diseaseName),
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
        'message': _getGroqErrorMessage(e),
        'source': 'Groq AI',
      };
    }
  }

  // ── Plant.id Analysis ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeWithPlantId(File imageFile) async {
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
        'message': _getPlantIdErrorMessage(e),
        'source': 'Plant.id AI',
      };
    }
  }

  // ── Error Messages ──────────────────────────────────────────────────────

  String _getGroqErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('groq_api_key') || errorStr.contains('401') || errorStr.contains('403')) {
      return 'Invalid Groq API key. Check GROQ_API_KEY.';
    }
    if (errorStr.contains('429')) return 'Groq rate limit reached. Try again later.';
    if (errorStr.contains('timeout')) return 'Groq request timed out. Check internet connection.';
    if (errorStr.contains('quota')) return 'Groq quota exceeded. Check usage limits.';
    return 'Groq analysis failed: $errorStr';
  }

  String _getPlantIdErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('402') || errorStr.contains('credits exhausted')) {
      return 'Plant.id credits exhausted. Please use Groq analysis instead.';
    }
    if (errorStr.contains('api_key') || errorStr.contains('401')) return 'Invalid Plant.id API key.';
    if (errorStr.contains('timeout')) return 'Plant.id request timed out.';
    return 'Plant.id analysis failed: $errorStr';
  }
}