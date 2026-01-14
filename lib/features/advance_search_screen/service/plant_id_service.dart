// lib/features/ResultScreen/presentation/service/plant_id_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlantIdService {
  // Plant.id API v3 configuration - CORRECTED URL
  static const String _plantIdApiKey = 'w5Ofy2sXPfaORHMM6P9Ky9o0pi58ElkbwyezKuy9dOm3DLqcdF';
  static const String _plantIdBaseUrl = 'https://api.plant.id/v3'; // Correct URL

  /// Test if Plant.id API is working
  Future<bool> testPlantIdApi() async {
    try {
      debugPrint('🌿 Testing Plant.id v3 API connectivity...');
      final response = await http.get(
        Uri.parse('$_plantIdBaseUrl/usage_info'),
        headers: {'Api-Key': _plantIdApiKey},
      );
      debugPrint('🌿 Plant.id v3 Connectivity Test: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🌿 API Credits: ${data.toString()}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Plant.id connectivity test error: $e');
      return false;
    }
  }

  /// Analyze plant using Plant.id v3 API with DISEASE DETECTION
  Future<Map<String, dynamic>> analyzeWithPlantId(File imageFile) async {
    try {
      debugPrint('🌿 Starting Plant.id v3 analysis WITH DISEASE DETECTION...');

      // Read image
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      debugPrint('📤 Sending to Plant.id v3 with health assessment enabled...');

      // Send request with health assessment
      final result = await _sendPlantIdRequestWithHealth(base64Image);
      return result;
    } catch (e) {
      debugPrint('❌ Plant.id analysis error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Plant.id analysis failed: ${e.toString()}',
      };
    }
  }

  /// Send Plant.id request WITH HEALTH ASSESSMENT - IMPROVED VERSION
  Future<Map<String, dynamic>> _sendPlantIdRequestWithHealth(String base64Image) async {
    // Create request body with health assessment - SIMPLIFIED
    final requestBody = {
      'images': [base64Image],
      'similar_images': false, // Disabled for faster response
      'health': 'all',
      'modifiers': ['crops_fast', 'similar_images'], // Add modifiers for faster processing
    };

    debugPrint('📋 Request configuration: health=all, similar_images=false');

    final createResponse = await http.post(
      Uri.parse('$_plantIdBaseUrl/identification'),
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': _plantIdApiKey,
      },
      body: jsonEncode(requestBody),
    );

    debugPrint('📡 Plant.id v3 Create Response: ${createResponse.statusCode}');

    if (createResponse.body.isNotEmpty) {
      final preview = createResponse.body.length > 200
          ? createResponse.body.substring(0, 200)
          : createResponse.body;
      debugPrint('📄 Create Response body preview: $preview');
    }

    if (createResponse.statusCode == 201) {
      final createData = jsonDecode(createResponse.body);
      final accessToken = createData['access_token'] as String?;

      if (accessToken == null) {
        throw Exception('No access token in response');
      }

      debugPrint('🔑 Access Token: $accessToken');

      // Poll for result with improved logic
      return await _pollForResult(accessToken, healthRequested: true);
    } else if (createResponse.statusCode == 429) {
      throw Exception('Plant.id credits exhausted or rate limit exceeded. Visit https://web.plant.id to purchase more credits or wait.');
    } else if (createResponse.statusCode == 401) {
      throw Exception('Invalid Plant.id API key. Please check your configuration.');
    } else if (createResponse.statusCode == 400) {
      final errorBody = createResponse.body;
      debugPrint('❌ Bad Request Error: $errorBody');
      // Try simpler request without health
      debugPrint('🔄 Trying simpler request without health...');
      return await _sendSimplePlantIdRequest(base64Image);
    } else {
      throw Exception('Plant.id API error ${createResponse.statusCode}: ${createResponse.body}');
    }
  }

  /// Poll for identification result - IMPROVED WITH BACKOFF
  Future<Map<String, dynamic>> _pollForResult(String accessToken, {required bool healthRequested}) async {
    const maxAttempts = 15; // Increased from 10
    int delaySeconds = 2; // Start with 2 seconds

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint('🔄 Polling attempt $attempt/$maxAttempts...');

      final uri = Uri.parse('$_plantIdBaseUrl/identification/$accessToken').replace(queryParameters: {
        'language': 'en',
        'details': 'common_names,description,treatment',
        'health': healthRequested ? 'all' : 'none', // Important: Include health parameter
      });

      final response = await http.get(
        uri,
        headers: {'Api-Key': _plantIdApiKey},
      );

      debugPrint('📡 Poll Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isFinished = data['is_finished'] as bool? ?? false;

        if (isFinished) {
          debugPrint('✅ Identification finished');
          return _parsePlantIdV3Response(data);
        } else {
          // Check if there's an error message
          final status = data['status'] as String?;
          if (status == 'failed' || status == 'error') {
            throw Exception('Identification failed: ${data['error'] ?? 'Unknown error'}');
          }

          // Check progress
          final progress = data['progress'] as int?;
          if (progress != null) {
            debugPrint('📊 Progress: $progress%');
          }
        }
      } else {
        debugPrint('❌ Poll error ${response.statusCode}: ${response.body}');
        // Don't throw immediately, retry
      }

      // Exponential backoff
      await Future.delayed(Duration(seconds: delaySeconds));

      // Increase delay for next attempt (exponential backoff)
      if (attempt < 5) {
        delaySeconds += 1;
      } else if (attempt < 10) {
        delaySeconds += 2;
      } else {
        delaySeconds += 3;
      }
    }

    throw Exception('Identification timeout after $maxAttempts attempts. Please try again with a clearer image.');
  }

  /// Send simple Plant.id request (fallback)
  Future<Map<String, dynamic>> _sendSimplePlantIdRequest(String base64Image) async {
    final simpleRequestBody = {
      'images': [base64Image],
      'similar_images': false, // Disabled for faster response
    };

    final createResponse = await http.post(
      Uri.parse('$_plantIdBaseUrl/identification'),
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': _plantIdApiKey,
      },
      body: jsonEncode(simpleRequestBody),
    );

    if (createResponse.statusCode == 201) {
      final createData = jsonDecode(createResponse.body);
      final accessToken = createData['access_token'] as String?;

      if (accessToken == null) {
        throw Exception('No access token in response');
      }

      // Poll for result
      return await _pollForResult(accessToken, healthRequested: false);
    } else {
      throw Exception('Simple request failed: ${createResponse.statusCode}');
    }
  }

  /// Parse Plant.id v3 API response with COMPLETE DISEASE INFORMATION
  Map<String, dynamic> _parsePlantIdV3Response(Map<String, dynamic> data) {
    try {
      debugPrint('🌿 Parsing Plant.id v3 response with health data...');
      debugPrint('📊 Full response keys: ${data.keys.toList()}');

      final result = data['result'] as Map<String, dynamic>? ?? {};

      // Check if plant is detected
      final isPlant = result['is_plant'] as Map<String, dynamic>?;
      final isPlantBinary = isPlant?['binary'] as bool? ?? false;
      final isPlantProbability = (isPlant?['probability'] as num?)?.toDouble() ?? 0.0;

      debugPrint('🔍 Is plant detected: $isPlantBinary (probability: ${(isPlantProbability * 100).toStringAsFixed(1)}%)');

      if (!isPlantBinary) {
        return _createNoPlantResponse();
      }

      // Extract plant classification
      final classification = result['classification'] as Map<String, dynamic>? ?? {};
      final suggestions = classification['suggestions'] as List<dynamic>? ?? [];

      if (suggestions.isEmpty) {
        return _createUnknownPlantResponse();
      }

      final topSuggestion = suggestions.first as Map<String, dynamic>;
      final plantName = topSuggestion['name'] as String? ?? 'Unknown Plant';
      final probability = (topSuggestion['probability'] as num?)?.toDouble() ?? 0.0;
      final confidence = (probability * 100).round();

      // Extract plant details
      final details = topSuggestion['details'] as Map<String, dynamic>? ?? {};
      final commonNames = (details['common_names'] as List<dynamic>?)?.cast<String>() ?? [];
      final description = details['description'] as Map<String, dynamic>?;
      final descriptionValue = description?['value'] as String? ?? 'Plant identified successfully';

      debugPrint('✅ Plant identified: $plantName (${commonNames.isNotEmpty ? commonNames.first : "no common name"})');
      debugPrint('📊 Identification confidence: $confidence%');

      // ========== HEALTH ASSESSMENT ==========
      bool hasDiseaseInfo = false;
      String diseaseName = 'Healthy';
      String severity = 'None';
      double diseaseProbability = 0.0;
      List<String> symptoms = [];
      List<String> treatments = [];
      List<String> precautions = [];

      final isHealthy = result['is_healthy'] as Map<String, dynamic>?;
      final isHealthyBinary = isHealthy?['binary'] as bool? ?? true;
      final isHealthyProbability = (isHealthy?['probability'] as num?)?.toDouble() ?? 1.0;

      debugPrint('💚 Plant health status: ${isHealthyBinary ? "HEALTHY" : "DISEASED"} (probability: ${(isHealthyProbability * 100).toStringAsFixed(1)}%)');

      if (!isHealthyBinary) {
        hasDiseaseInfo = true;

        // Get disease information
        final diseaseSection = result['disease'] as Map<String, dynamic>?;
        if (diseaseSection != null) {
          final diseaseSuggestions = diseaseSection['suggestions'] as List<dynamic>? ?? [];
          debugPrint('🔴 Found ${diseaseSuggestions.length} disease suggestions');

          if (diseaseSuggestions.isNotEmpty) {
            final topDisease = diseaseSuggestions.first as Map<String, dynamic>;
            diseaseName = topDisease['name'] as String? ?? 'Unknown Disease';
            diseaseProbability = (topDisease['probability'] as num?)?.toDouble() ?? 0.0;

            debugPrint('🦠 Disease detected: $diseaseName (${(diseaseProbability * 100).toStringAsFixed(1)}% probability)');

            // Determine severity
            severity = _determineSeverity(diseaseProbability);

            // Extract disease details
            final diseaseDetails = topDisease['details'] as Map<String, dynamic>? ?? {};

            // Get description
            final diseaseDescription = diseaseDetails['description'] as Map<String, dynamic>?;
            final diseaseDescValue = diseaseDescription?['value'] as String?;

            // Extract symptoms from description or generate based on disease name
            symptoms = _extractSymptoms(diseaseName, diseaseDescValue, diseaseProbability);

            // Get treatment information
            final treatment = diseaseDetails['treatment'] as Map<String, dynamic>?;
            if (treatment != null) {
              treatments = _extractTreatments(treatment);
              precautions = _extractPrecautions(treatment);
            } else {
              treatments = _getGenericTreatments(diseaseName);
              precautions = _getGenericPrecautions();
            }

            debugPrint('💊 Extracted ${treatments.length} treatments');
            debugPrint('⚠️ Extracted ${precautions.length} precautions');
          }
        }
      } else {
        debugPrint('✅ Plant appears healthy');
        symptoms = ['No visible disease symptoms detected'];
        treatments = ['Continue regular plant care'];
        precautions = ['Monitor plant regularly for any changes'];
      }

      // Build the final result
      final analysisResult = {
        'plantName': commonNames.isNotEmpty ? commonNames.first : plantName,
        'scientificName': plantName,
        'diseaseName': diseaseName,
        'severity': severity,
        'confidence': confidence,
        'diseaseConfidence': (diseaseProbability * 100).round(),
        'symptoms': symptoms,
        'remediation': treatments,
        'precautions': precautions,
        'additionalInfo': _buildAdditionalInfo(
          plantName: plantName,
          commonNames: commonNames,
          confidence: confidence,
          hasDiseaseInfo: hasDiseaseInfo,
          diseaseName: diseaseName,
          diseaseProbability: diseaseProbability,
          description: descriptionValue,
        ),
      };

      debugPrint('✅ Plant.id analysis complete');
      debugPrint('📊 Final result: ${analysisResult['plantName']} - ${analysisResult['diseaseName']}');

      return {
        'success': true,
        'source': 'Plant.id AI',
        'data': analysisResult,
        'timestamp': DateTime.now().toIso8601String(),
        'isRealData': true,
        'hasDiseaseInfo': hasDiseaseInfo,
        'hasHealthAssessment': isHealthy != null,
      };
    } catch (e) {
      debugPrint('❌ Error parsing Plant.id v3 response: $e');
      debugPrint('Raw data: ${data.toString()}');
      return _createFallbackResponse();
    }
  }

  // ====== HELPER METHODS ======
  String _determineSeverity(double probability) {
    if (probability > 0.8) return 'Severe';
    if (probability > 0.6) return 'High';
    if (probability > 0.4) return 'Medium';
    if (probability > 0.2) return 'Low';
    return 'Minimal';
  }

  List<String> _extractSymptoms(String diseaseName, String? description, double probability) {
    final symptoms = <String>[];

    // Add disease-specific symptoms from description
    if (description != null && description.isNotEmpty) {
      final sentences = description.split('. ');
      for (var sentence in sentences.take(3)) {
        if (sentence.length > 15 && !sentence.toLowerCase().contains('http')) {
          symptoms.add(sentence.trim().endsWith('.') ? sentence.trim() : '${sentence.trim()}.');
        }
      }
    }

    // Add severity-based symptoms
    if (probability > 0.7) {
      if (symptoms.isEmpty) {
        symptoms.add('Advanced stage of $diseaseName detected');
      }
      symptoms.add('Visible damage on plant tissue');
      symptoms.add('Immediate intervention required');
    } else if (probability > 0.4) {
      if (symptoms.isEmpty) {
        symptoms.add('Moderate signs of $diseaseName present');
      }
      symptoms.add('Early to mid-stage symptoms visible');
      symptoms.add('Treatment recommended to prevent spread');
    } else {
      if (symptoms.isEmpty) {
        symptoms.add('Early indicators of $diseaseName');
      }
      symptoms.add('Minimal damage currently visible');
      symptoms.add('Preventive measures advised');
    }

    return symptoms;
  }

  List<String> _extractTreatments(Map<String, dynamic> treatment) {
    final treatments = <String>[];

    // Extract biological treatment
    final biological = treatment['biological'] as List<dynamic>?;
    if (biological != null && biological.isNotEmpty) {
      for (var item in biological) {
        final value = item.toString();
        if (value.isNotEmpty && value.length > 10) {
          treatments.add('Biological: $value');
        }
      }
    }

    // Extract chemical treatment
    final chemical = treatment['chemical'] as List<dynamic>?;
    if (chemical != null && chemical.isNotEmpty) {
      for (var item in chemical) {
        final value = item.toString();
        if (value.isNotEmpty && value.length > 10) {
          treatments.add('Chemical: $value');
        }
      }
    }

    // Extract prevention methods
    final prevention = treatment['prevention'] as List<dynamic>?;
    if (prevention != null && prevention.isNotEmpty) {
      for (var item in prevention) {
        final value = item.toString();
        if (value.isNotEmpty && value.length > 10) {
          treatments.add('Prevention: $value');
        }
      }
    }

    return treatments.isEmpty ? _getGenericTreatments('disease') : treatments;
  }

  List<String> _getGenericTreatments(String diseaseName) {
    return [
      'Remove and dispose of affected plant parts',
      'Improve air circulation around the plant',
      'Reduce humidity and avoid overhead watering',
      'Apply appropriate fungicide or treatment for $diseaseName',
      'Isolate plant to prevent disease spread',
    ];
  }

  List<String> _extractPrecautions(Map<String, dynamic> treatment) {
    final precautions = <String>[];

    final prevention = treatment['prevention'] as List<dynamic>?;
    if (prevention != null && prevention.isNotEmpty) {
      for (var item in prevention) {
        final value = item.toString();
        if (value.isNotEmpty && value.length > 15) {
          precautions.add(value);
        }
      }
    }

    return precautions.isEmpty ? _getGenericPrecautions() : precautions;
  }

  List<String> _getGenericPrecautions() {
    return [
      'Monitor plant daily for symptom progression',
      'Maintain proper spacing between plants',
      'Use sterilized tools when pruning',
      'Avoid working with plants when wet',
      'Ensure proper drainage and air flow',
      'Practice crop rotation if applicable',
    ];
  }

  String _buildAdditionalInfo({
    required String plantName,
    required List<String> commonNames,
    required int confidence,
    required bool hasDiseaseInfo,
    required String diseaseName,
    required double diseaseProbability,
    required String description,
  }) {
    final buffer = StringBuffer();

    buffer.write('🌿 PLANT.ID V3 ANALYSIS REPORT\n');
    buffer.write('═' * 40);
    buffer.write('\n\n');

    // Plant Information
    buffer.write('🪴 PLANT IDENTIFICATION\n');
    buffer.write('─' * 40);
    buffer.write('\n');

    if (commonNames.isNotEmpty) {
      buffer.write('Common Name: ${commonNames.first}\n');
    }
    buffer.write('Scientific Name: $plantName\n');
    buffer.write('Confidence: $confidence%\n');

    if (description.isNotEmpty && description != 'Plant identified successfully') {
      buffer.write('\nDescription: ${description.substring(0, description.length > 150 ? 150 : description.length)}...\n');
    }

    buffer.write('\n');

    // Health Assessment
    buffer.write('🏥 HEALTH ASSESSMENT\n');
    buffer.write('─' * 40);
    buffer.write('\n');

    if (hasDiseaseInfo) {
      buffer.write('Status: ⚠️ DISEASE DETECTED\n');
      buffer.write('Condition: $diseaseName\n');
      buffer.write('Disease Confidence: ${(diseaseProbability * 100).toStringAsFixed(1)}%\n');
      buffer.write('\n💡 IMMEDIATE ACTIONS REQUIRED:\n');
      buffer.write('• Review symptoms listed above carefully\n');
      buffer.write('• Begin recommended treatment immediately\n');
      buffer.write('• Monitor plant response daily\n');
      buffer.write('• Isolate from healthy plants if possible\n');
    } else {
      buffer.write('Status: ✅ HEALTHY\n');
      buffer.write('\n💡 MAINTENANCE RECOMMENDATIONS:\n');
      buffer.write('• Continue current care practices\n');
      buffer.write('• Regular monitoring for early detection\n');
      buffer.write('• Maintain optimal growing conditions\n');
      buffer.write('• Provide balanced nutrition\n');
    }

    buffer.write('\n');
    buffer.write('⚙️ ANALYSIS DETAILS\n');
    buffer.write('─' * 40);
    buffer.write('\n');
    buffer.write('API Version: Plant.id v3\n');
    buffer.write('Health Assessment: Enabled\n');
    buffer.write('Analysis Date: ${DateTime.now().toString().split('.')[0]}\n');

    return buffer.toString();
  }

  Map<String, dynamic> _createNoPlantResponse() {
    return {
      'success': true,
      'source': 'Plant.id AI',
      'data': {
        'plantName': 'No plant detected',
        'scientificName': 'N/A',
        'diseaseName': 'N/A',
        'severity': 'N/A',
        'confidence': 0,
        'diseaseConfidence': 0,
        'symptoms': ['Image does not contain a recognizable plant'],
        'remediation': ['Please upload a clear photo of a plant'],
        'precautions': ['Ensure the plant is the main subject of the photo'],
        'additionalInfo': '❌ NO PLANT DETECTED\n\n💡 Tips for better results:\n• Capture the whole plant or clear leaf details\n• Ensure good lighting without harsh shadows\n• Avoid blurry or distant shots\n• Focus on distinctive plant features\n• Keep the plant as the main subject',
      },
      'isRealData': true,
      'hasDiseaseInfo': false,
    };
  }

  Map<String, dynamic> _createUnknownPlantResponse() {
    return {
      'success': true,
      'source': 'Plant.id AI',
      'data': {
        'plantName': 'Unknown Species',
        'scientificName': 'Unidentified',
        'diseaseName': 'Analysis incomplete',
        'severity': 'Unknown',
        'confidence': 0,
        'diseaseConfidence': 0,
        'symptoms': ['Plant species could not be identified'],
        'remediation': ['Try a different photo with better lighting'],
        'precautions': ['Follow general plant care guidelines'],
        'additionalInfo': '⚠️ SPECIES NOT IDENTIFIED\n\nPossible reasons:\n• Plant not in database\n• Insufficient image quality\n• Rare or uncommon species\n• Photo angle not optimal\n\nTry:\n• Different lighting conditions\n• Closer view of leaves/flowers\n• Multiple angles of the plant',
      },
      'isRealData': true,
      'hasDiseaseInfo': false,
    };
  }

  Map<String, dynamic> _createFallbackResponse() {
    return {
      'success': false,
      'source': 'Plant.id AI',
      'error': 'Failed to parse response',
      'message': 'Could not parse Plant.id response. Please try again.',
    };
  }

  /// Get API status and credit info
  Future<Map<String, dynamic>> getApiStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_plantIdBaseUrl/usage_info'),
        headers: {'Api-Key': _plantIdApiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': 'API is working',
          'version': 'v3',
          'endpoint': _plantIdBaseUrl,
          'key': '${_plantIdApiKey.substring(0, 8)}...',
          'details': data,
        };
      } else {
        return {
          'success': false,
          'status': 'API connection issue',
          'statusCode': response.statusCode,
          'endpoint': _plantIdBaseUrl,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'Connection failed',
        'error': e.toString(),
        'endpoint': _plantIdBaseUrl,
      };
    }
  }
}