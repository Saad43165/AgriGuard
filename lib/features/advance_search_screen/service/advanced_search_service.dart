import 'dart:io';
import 'package:agriguard_fyp/features/advance_search_screen/service/RoboflowApiService.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/ai_analysis_service.dart';
import '../../../../core/services/severity_id_service.dart';
import '../../../../core/services/translation_service.dart';
import 'groq_service.dart';
import 'plant_id_api_service.dart';

class AdvancedSearchService {
  final RoboFlowApiService _roboflowApiService = RoboFlowApiService();
  final GroqService _groqService = GroqService();
  final PlantAnalysisService _onDeviceAnalysis = PlantAnalysisService();
  final SeverityIdService _severityService = SeverityIdService();
  final PlantIdService _plantIdService = PlantIdService();

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
    final roboflowAvailable = _roboflowApiService.hasApiKey;

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

    debugPrint(
      '📊 API Status: Roboflow=${roboflowAvailable ? "✅" : "❌"}, Groq=${groqTest ? "✅" : "❌"}, Plant.id=${plantIdUsable ? "✅" : "❌"}',
    );

    return {
      'success': roboflowAvailable || groqKeyPresent || plantIdUsable,
      'roboflow': {
        'available': roboflowAvailable,
        'status': roboflowAvailable ? '✅ Ready' : '⚠️ No Roboflow key',
        'message': roboflowAvailable
            ? 'Roboflow AI ready'
            : 'Set ROBOFLOW_INFER_API_KEY in .env',
      },
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
      'message': roboflowAvailable || groqKeyPresent || plantIdUsable
          ? 'At least one API is available'
          : 'No APIs are currently available',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  List<String> _lookupSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') {
      return const ['No visible symptoms', 'Normal leaf color and texture'];
    }
    if (l.contains('rust')) {
      return const [
        'Orange/yellow lesions',
        'Rust-colored pustules',
        'Premature leaf drop'
      ];
    }
    if (l.contains('blight')) {
      return const [
        'Dark lesions on leaves',
        'Yellowing around lesions',
        'Rapid spread in humidity'
      ];
    }
    if (l.contains('spot')) {
      return const [
        'Small circular spots',
        'Yellow halos',
        'Spots may merge over time'
      ];
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

  /// Roboflow official serverless API + on-device fallback
  Future<Map<String, dynamic>> analyzeWithRoboflow(File imageFile) async {
    debugPrint('🌿 Starting Roboflow API analysis...');
    try {
      final leafCheck = await _onDeviceAnalysis.checkIsLeaf(imageFile);
      if (leafCheck == false) {
        return {
          'success': false,
          'isNonLeaf': true,
          'error': 'Not a plant leaf',
          'message':
          'The image does not appear to be a plant leaf. Please take a clear photo of a plant leaf.',
          'source': 'Roboflow AI',
        };
      }

      final roboflowResult = await _roboflowApiService.identify(imageFile);
      final onDevice = await _onDeviceAnalysis.analyzePlant(imageFile);

      String plantName;
      String diseaseName;
      const scientificName = '';
      double confidence;

      if (roboflowResult['success'] == true) {
        final rfConf = (roboflowResult['confidence'] as num?)?.toDouble() ?? 0.0;
        final rfPlant = roboflowResult['plantName']?.toString() ?? '';
        final rfDisease = roboflowResult['diseaseName']?.toString() ?? '';
        final odConf =
            double.tryParse(onDevice['confidence']?.toString() ?? '0') ?? 0.0;

        if (rfConf >= odConf || rfPlant.isNotEmpty) {
          plantName =
          rfPlant.isNotEmpty ? rfPlant : (onDevice['plantName']?.toString() ?? 'Unknown Plant');
          diseaseName =
          rfDisease.isNotEmpty ? rfDisease : (onDevice['diseaseName']?.toString() ?? 'Healthy');
          confidence = rfConf;
        } else {
          plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
          diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
          confidence = odConf;
        }
      } else {
        plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
        diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
        confidence = double.tryParse(onDevice['confidence']?.toString() ?? '0') ?? 0.0;
      }

      final isHealthy = diseaseName.toLowerCase() == 'healthy';

      final severity = await _severityService.getSeverityAndRemediation(
        diseaseName: diseaseName,
        plantName: plantName,
        confidence: confidence,
        imagePath: imageFile.path,
      );

      final severityLevel =
          severity?['severity']?.toString() ?? (isHealthy ? 'None' : 'Unknown');
      final remediation = severity?['remediation'] is List
          ? List<String>.from(severity!['remediation'])
          : <String>[];

      final rfPredictions = roboflowResult['predictions'] as List? ?? [];
      final allPredictions = rfPredictions.isNotEmpty
          ? rfPredictions
          : (onDevice['allPredictions'] as List? ?? [])
          .take(5)
          .map((p) => {
        'label': '${p['plantName']} - ${p['diseaseName']}',
        'confidence': p['confidence']?.toString() ?? '0',
      })
          .toList();

      return {
        'success': true,
        'source': 'Roboflow AI',
        'isRealData': true,
        'hasDiseaseInfo': !isHealthy,
        'data': {
          'plantName': plantName,
          'scientificName': scientificName,
          'diseaseName': diseaseName,
          'confidence': confidence.toStringAsFixed(1),
          'severity': severityLevel,
          'cause': _lookupCause(diseaseName: diseaseName),
          'symptoms': _lookupSymptoms(diseaseName),
          'remediation': remediation.isNotEmpty
              ? remediation
              : [
            'Consult an agricultural expert',
            'Remove affected leaves to reduce spread'
          ],
          'precautions': const [
            'Monitor the plant daily for changes',
            'Avoid overhead watering if disease is suspected',
            'Improve air circulation around plants',
            'Disinfect tools between plants',
          ],
          'rawLabel': onDevice['rawLabel'] ?? '',
          'allPredictions': allPredictions,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Roboflow API analysis error: $e');
      return {
        'success': false,
        'error': 'Roboflow analysis failed',
        'message': e.toString(),
        'source': 'Roboflow AI',
      };
    }
  }

  /// Groq analysis on top of on-device ML
  Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    debugPrint('🌿 Starting Groq analysis (on top of on-device ML)...');

    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final onDevice = await _onDeviceAnalysis.analyzePlant(imageFile);
      if (onDevice['success'] != true) {
        return {
          'success': false,
          'error': 'On-device analysis failed',
          'message':
          onDevice['error']?.toString() ?? 'Unable to analyze image on-device',
          'source': 'On-Device AI',
        };
      }

      if (onDevice['isLeaf'] == false) {
        return {
          'success': false,
          'isNonLeaf': true,
          'error': 'Not a plant leaf',
          'message':
          'The image does not appear to be a plant leaf. Please take a clear photo of a plant leaf.',
          'source': 'Groq AI',
        };
      }

      final plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
      final diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
      final severity = onDevice['severity']?.toString() ??
          (diseaseName.toLowerCase() == 'healthy' ? 'None' : 'Unknown');
      final confidence =
      onDevice['confidence'] is num ? (onDevice['confidence'] as num) : 0;

      final groq = await _groqService.generateAgronomyAdvice(
        plantName: plantName,
        diseaseName: diseaseName,
        severity: severity,
        confidencePercent: confidence,
        inUrdu: TranslationService().isUrdu,
      );

      if (groq['success'] == true) {
        final data = (groq['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(groq['data'] as Map<String, dynamic>)
            : <String, dynamic>{};

        data['plantName'] = plantName;
        data['diseaseName'] = diseaseName;
        data['severity'] = severity;
        data['confidence'] = confidence.toString();

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

      return {
        'success': false,
        'error': groq['error'] ?? 'Groq failed',
        'message': groq['message'] ?? 'Groq analysis failed',
        'source': 'Groq AI',
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

  /// Plant.id analysis only
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

  String _getGroqErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('groq_api_key') ||
        errorStr.contains('401') ||
        errorStr.contains('403')) {
      return 'Invalid Groq API key. Check GROQ_API_KEY.';
    }
    if (errorStr.contains('429')) {
      return 'Groq rate limit reached. Try again later.';
    }
    if (errorStr.contains('timeout')) {
      return 'Groq request timed out. Check internet connection.';
    }
    if (errorStr.contains('quota')) {
      return 'Groq quota exceeded. Check usage limits.';
    }

    return 'Groq analysis failed: $errorStr';
  }

  String _getPlantIdErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('402') || errorStr.contains('credits exhausted')) {
      return 'Plant.id credits exhausted. Please use Roboflow or Groq analysis instead.';
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
    try {
      final plantIdStatus = await _plantIdService.getApiStatus();
      final groqTest = await testGroqApi();

      return {
        'success': true,
        'groq': {
          'available': groqTest,
          'status': groqTest ? '✅ Ready' : 'Unavailable',
          'message': groqTest ? 'Groq AI active' : 'Check GROQ_API_KEY',
        },
        'plantId': plantIdStatus,
        'recommendation': groqTest
            ? 'Using Groq AI (text assistant on top of on-device detection)'
            : 'Use Plant.id. ${plantIdStatus['remaining']?['total'] ?? 'Unknown'} credits left.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> isAnyApiAvailable() async {
    final roboflow = _roboflowApiService.hasApiKey;
    final groq = await testGroqApi();
    final plantId = _plantIdService.hasApiKey() ? await testPlantIdApi() : false;
    return roboflow || groq || plantId;
  }

  Map<String, dynamic> getApiRecommendations() {
    return {
      'primary': 'Roboflow',
      'status': 'Cloud vision model (requires ROBOFLOW_INFER_API_KEY)',
      'secondary': 'Plant.id',
      'secondary_status': 'Depends on key + credits',
      'tertiary': 'Groq',
      'tertiary_status': 'Text advisory on top of on-device detection',
      'action_required':
      'Ensure ROBOFLOW_INFER_API_KEY, PLANTID_API_KEY, and GROQ_API_KEY are set',
      'documentation': 'https://docs.roboflow.com/deploy/serverless',
    };
  }
}