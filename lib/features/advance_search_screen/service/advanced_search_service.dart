import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/ai_analysis_service.dart';
import '../../../../core/services/severity_id_service.dart';
import '../../../../core/services/translation_service.dart';
import 'groq_service.dart';
import 'plantnet_api_service.dart';
import 'plant_id_api_service.dart';

class AdvancedSearchService {
  final PlantNetApiService _plantNetApiService = PlantNetApiService();
  final GroqService _groqService = GroqService();
  final PlantAnalysisService _onDeviceAnalysis = PlantAnalysisService();
  final SeverityIdService _severityService = SeverityIdService();
  final PlantIdService _plantIdService = PlantIdService();
  Map<String, dynamic>? _mapping;
  Map<String, dynamic>? _diseaseCauses;

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
    final plantNetAvailable = _plantNetApiService.hasApiKey;
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
        // Fallback: if we can't parse credits, do a simple connectivity test.
        plantIdUsable = await testPlantIdApi();
      }
    }

    debugPrint('📊 API Status: PlantNet=${plantNetAvailable ? "✅" : "❌"}, Groq=${groqTest ? "✅" : "❌"}, Plant.id=${plantIdUsable ? "✅" : "❌"}');

    return {
      'success': plantNetAvailable || groqKeyPresent || plantIdUsable,
      'huggingface': {
        'available': plantNetAvailable,
        'status': plantNetAvailable ? '✅ Ready' : '⚠️ No Roboflow key',
        'message': plantNetAvailable ? 'Roboflow AI ready' : 'Set ROBOFLOW_INFER_API_KEY in .env',
      },
      'groq': {
        'available': groqKeyPresent,
        'status': groqKeyPresent
            ? (groqTest ? '✅ Ready' : '⚠️ Key set (network/API check failed)')
            : '❌ Unavailable',
        'message': groqKeyPresent
            ? (groqTest ? 'Groq AI ready' : 'Groq key is set. If requests fail, check internet/network.')
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
      'message': plantNetAvailable || groqKeyPresent || plantIdUsable
          ? 'At least one API is available'
          : 'No APIs are currently available',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _ensureReferenceDataLoaded() async {
    if (_mapping != null && _diseaseCauses != null) return;
    final mappingStr = await rootBundle.loadString('assets/data/mapping.json');
    final causesStr = await rootBundle.loadString('assets/data/disease_causes.json');
    _mapping = jsonDecode(mappingStr) as Map<String, dynamic>;
    _diseaseCauses = jsonDecode(causesStr) as Map<String, dynamic>;
  }

  Map<String, String> _parseLabelToPlantDisease(String rawLabel) {
    // Expected formats from many plant-disease models:
    // "Apple___Apple_scab", "Tomato___healthy", etc.
    if (rawLabel.contains('___')) {
      final parts = rawLabel.split('___');
      final plant = parts[0].replaceAll('_', ' ').trim();
      final diseasePart = parts.length > 1 ? parts[1] : 'Unknown';
      final disease = diseasePart.replaceAll('_', ' ').trim();
      return {'plant': plant, 'disease': disease.toLowerCase() == 'healthy' ? 'Healthy' : _titleCase(disease)};
    }
    return {'plant': 'Unknown Plant', 'disease': rawLabel};
  }

  String _titleCase(String s) {
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  String _mapToCanonicalKey(String plantName, String diseaseName) {
    // Build common key shape: Plant___Disease_with_underscores
    final p = plantName.replaceAll(' ', '_').trim();
    final d = diseaseName.replaceAll(' ', '_').trim();
    return '${p}___$d';
  }

  String _lookupCause(String canonicalKey, {required String diseaseName}) {
    try {
      final root = _diseaseCauses?['plant_disease_causes'];
      if (root is Map && root[canonicalKey] is Map) {
        final entry = root[canonicalKey] as Map;
        final causes = entry['causes'];
        if (causes is List && causes.isNotEmpty) return causes.first.toString();
      }
    } catch (_) {}
    // fallback
    final l = diseaseName.toLowerCase();
    if (l.contains('blight')) return 'Fungal or bacterial infection';
    if (l.contains('spot')) return 'Bacterial or fungal pathogens';
    if (l.contains('rust')) return 'Fungal rust disease';
    if (l.contains('mildew')) return 'Fungal mildew infection';
    return 'Environmental factors or pathogen infection';
  }

  List<String> _lookupSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') return const ['No visible symptoms', 'Normal leaf color and texture'];
    if (l.contains('rust')) return const ['Orange/yellow lesions', 'Rust-colored pustules', 'Premature leaf drop'];
    if (l.contains('blight')) return const ['Dark lesions on leaves', 'Yellowing around lesions', 'Rapid spread in humidity'];
    if (l.contains('spot')) return const ['Small circular spots', 'Yellow halos', 'Spots may merge over time'];
    return const ['Leaf discoloration', 'Spots or lesions', 'Reduced plant vigor'];
  }

  /// PlantNet official API (my.plantnet.org) — plant species identification
  /// Combined with on-device disease detection for full diagnosis.
  Future<Map<String, dynamic>> analyzeWithHuggingFace(File imageFile) async {
    debugPrint('🌿 Starting PlantNet API analysis...');
    try {
      await _ensureReferenceDataLoaded();

      // Leaf detection gate — block non-leaf images before calling API
      final leafCheck = await _onDeviceAnalysis.checkIsLeaf(imageFile);
      if (leafCheck == false) {
        return {
          'success': false,
          'isNonLeaf': true,
          'error': 'Not a plant leaf',
          'message': 'The image does not appear to be a plant leaf. Please take a clear photo of a plant leaf.',
          'source': 'PlantNet AI',
        };
      }

      // Step 1: Roboflow API — detect plant disease
      final roboflowResult = await _plantNetApiService.identify(imageFile);

      // Step 2: On-device disease detection as fallback/supplement
      final onDevice = await _onDeviceAnalysis.analyzePlant(imageFile);

      // Determine plant name and disease — prefer Roboflow if successful
      String plantName;
      String diseaseName;
      String scientificName = '';
      double confidence;

      if (roboflowResult['success'] == true) {
        final rfConf = (roboflowResult['confidence'] as num?)?.toDouble() ?? 0.0;
        final rfPlant = roboflowResult['plantName']?.toString() ?? '';
        final rfDisease = roboflowResult['diseaseName']?.toString() ?? '';
        final odConf = double.tryParse(onDevice['confidence']?.toString() ?? '0') ?? 0.0;

        // Use Roboflow if it has higher confidence or on-device is unknown
        if (rfConf >= odConf || rfPlant.isEmpty == false) {
          plantName = rfPlant.isNotEmpty ? rfPlant : (onDevice['plantName']?.toString() ?? 'Unknown Plant');
          diseaseName = rfDisease.isNotEmpty ? rfDisease : (onDevice['diseaseName']?.toString() ?? 'Healthy');
          confidence = rfConf;
        } else {
          plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
          diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
          confidence = odConf;
        }
      } else {
        // Roboflow failed — use on-device
        plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
        diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
        confidence = double.tryParse(onDevice['confidence']?.toString() ?? '0') ?? 0.0;
      }

      final isHealthy = diseaseName.toLowerCase() == 'healthy';

      // Step 3: Severity & remediation
      final severity = await _severityService.getSeverityAndRemediation(
        diseaseName: diseaseName,
        plantName: plantName,
        confidence: confidence,
        imagePath: imageFile.path,
      );
      final severityLevel = severity?['severity']?.toString() ?? (isHealthy ? 'None' : 'Unknown');
      final remediation = severity?['remediation'] is List
          ? List<String>.from(severity!['remediation'])
          : <String>[];

      // Build predictions list
      final rfPredictions = roboflowResult['predictions'] as List? ?? [];
      final allPredictions = rfPredictions.isNotEmpty
          ? rfPredictions
          : (onDevice['allPredictions'] as List? ?? []).take(5).map((p) => {
              'label': '${p['plantName']} - ${p['diseaseName']}',
              'confidence': p['confidence']?.toString() ?? '0',
            }).toList();

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
          'cause': _lookupCause('', diseaseName: diseaseName),
          'symptoms': _lookupSymptoms(diseaseName),
          'remediation': remediation.isNotEmpty
              ? remediation
              : ['Consult an agricultural expert', 'Remove affected leaves to reduce spread'],
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
      debugPrint('❌ PlantNet API analysis error: $e');
      return {
        'success': false,
        'error': 'PlantNet analysis failed',
        'message': e.toString(),
        'source': 'PlantNet AI',
      };
    }
  }

  /// Groq (text) analysis on top of on-device ML
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
          'message': onDevice['error']?.toString() ?? 'Unable to analyze image on-device',
          'source': 'On-Device AI',
        };
      }

      // If it isn't a leaf, stop here — don't run Groq on non-plant images
      if (onDevice['isLeaf'] == false) {
        debugPrint('❌ Non-leaf image — blocking Groq analysis');
        return {
          'success': false,
          'isNonLeaf': true,
          'error': 'Not a plant leaf',
          'message': 'The image does not appear to be a plant leaf. Please take a clear photo of a plant leaf.',
          'source': 'Groq AI',
        };
      }

      final plantName = onDevice['plantName']?.toString() ?? 'Unknown Plant';
      final diseaseName = onDevice['diseaseName']?.toString() ?? 'Healthy';
      final severity = onDevice['severity']?.toString() ?? (diseaseName.toLowerCase() == 'healthy' ? 'None' : 'Unknown');
      final confidence = onDevice['confidence'] is num ? (onDevice['confidence'] as num) : 0;

      final groq = await _groqService.generateAgronomyAdvice(
        plantName: plantName,
        diseaseName: diseaseName,
        severity: severity,
        confidencePercent: confidence,
        inUrdu: TranslationService().isUrdu,
      );

      if (groq['success'] == true) {
        // Groq is used for *advice text*, not vision. Never let Groq override
        // the on-device diagnosis fields (plant/disease/severity/confidence).
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

  String _getGroqErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('groq_api_key') || errorStr.contains('401') || errorStr.contains('403')) {
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
      return 'Plant.id credits exhausted. Please use Cloud AI analysis instead.';
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
            ? 'Using Groq AI (free-tier text assistant on top of on-device detection)'
            : 'Use Plant.id. ${plantIdStatus['remaining']?['total'] ?? 'Unknown'} credits left.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Status error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> isAnyApiAvailable() async {
    final plantNet = _plantNetApiService.hasApiKey;
    final groq = await testGroqApi();
    final plantId = _plantIdService.hasApiKey() ? await testPlantIdApi() : false;
    return plantNet || groq || plantId;
  }

  Map<String, dynamic> getApiRecommendations() {
    return {
      'primary': 'Hugging Face',
      'status': 'Free-tier vision model (✅ if HF_API_TOKEN is valid)',
      'secondary': 'Plant.id',
      'secondary_status': '✅ Working',
      'credits': 'Hugging Face has a free tier with usage limits',
      'action_required': 'Ensure HF_API_TOKEN + HF_MODEL are set',
      'documentation': 'https://huggingface.co/docs/api-inference/',
    };
  }
}