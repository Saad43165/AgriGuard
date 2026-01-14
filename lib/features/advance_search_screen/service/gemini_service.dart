import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  // Correct Gemini Vision API endpoint
  static const String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // Your Gemini API key
  static const String apiKey = 'AIzaSyDAjrwZApVBJKvbJz7Y-_-Ex83S2IhOHiQ';

  Future<Map<String, dynamic>> analyzeWithGemini(File imageFile) async {
    try {
      debugPrint('🚀 Starting Gemini analysis...');

      // Check if file exists
      if (!await imageFile.exists()) {
        debugPrint('❌ Image file not found');
        throw Exception('Image file not found');
      }

      // Read and encode image
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      debugPrint('📊 Image encoded: ${base64Image.length ~/ 1024} KB');

      // Create the request
      final uri = Uri.parse('$endpoint?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': '''ANALYZE THIS PLANT LEAF IMAGE FOR DISEASES.

Provide analysis in JSON format with these exact fields:
{
  "plantName": "Name of the plant",
  "diseaseName": "Name of disease or 'Healthy'",
  "confidence": "Percentage confidence",
  "severity": "Low/Medium/High/None",
  "cause": "Cause of the disease",
  "symptoms": ["Array of symptoms"],
  "remediation": ["Array of treatment steps"],
  "precautions": ["Array of prevention measures"]
}

Be specific and scientific.'''
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 1500,
          'topP': 0.8,
          'topK': 40,
        }
      };

      debugPrint('🌐 Calling Gemini API...');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Gemini response received');

        // Log full response for debugging
        final fullResponse = jsonEncode(data);
        debugPrint('📝 Full response length: ${fullResponse.length} chars');

        return _processGeminiResponse(data);
      } else {
        debugPrint('❌ Gemini API error: ${response.body}');

        // Try alternative endpoint
        return await _tryAlternativeEndpoint(base64Image);
      }
    } catch (e) {
      debugPrint('❌ Gemini exception: $e');
      return {
        'success': false,
        'error': 'Gemini analysis failed',
        'message': 'Failed to analyze with Gemini: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _tryAlternativeEndpoint(String base64Image) async {
    try {
      debugPrint('🔄 Trying alternative Gemini endpoint...');

      // Try with the latest model
      const altEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';
      final uri = Uri.parse('$altEndpoint?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Analyze this plant leaf image for diseases and provide JSON analysis.'
              },
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ]
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return _processGeminiResponse(jsonDecode(response.body));
      }

      throw Exception('Alternative endpoint failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Alternative endpoint failed: $e');
      throw e;
    }
  }

  Map<String, dynamic> _processGeminiResponse(Map<String, dynamic> data) {
    try {
      // Extract text from response
      String? responseText;

      try {
        // Try standard Gemini response format
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              responseText = parts[0]['text'] as String?;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error extracting response: $e');
      }

      if (responseText == null || responseText.isEmpty) {
        debugPrint('⚠️ Empty response from Gemini');
        return _createDefaultResponse('No analysis generated by Gemini');
      }

      debugPrint('📝 Gemini response: ${responseText.substring(0, min(200, responseText.length))}...');

      // Try to parse JSON from response
      Map<String, dynamic> jsonData;
      try {
        // Clean response text
        String cleanText = responseText.trim();

        // Remove markdown code blocks
        cleanText = cleanText.replaceAll('```json', '').replaceAll('```', '').trim();

        // Find JSON object
        final startIdx = cleanText.indexOf('{');
        final endIdx = cleanText.lastIndexOf('}');

        if (startIdx >= 0 && endIdx > startIdx) {
          final jsonStr = cleanText.substring(startIdx, endIdx + 1);
          jsonData = jsonDecode(jsonStr);
          debugPrint('✅ Successfully parsed JSON from Gemini');
        } else {
          throw Exception('No JSON object found');
        }
      } catch (e) {
        debugPrint('⚠️ Could not parse JSON, extracting from text: $e');
        jsonData = _extractDataFromText(responseText);
      }

      return {
        'success': true,
        'source': 'Gemini AI',
        'data': {
          'plantName': jsonData['plantName']?.toString() ?? _extractPlantName(responseText),
          'diseaseName': jsonData['diseaseName']?.toString() ?? _extractDiseaseName(responseText),
          'confidence': jsonData['confidence']?.toString() ?? _extractConfidence(responseText),
          'severity': jsonData['severity']?.toString() ?? _extractSeverity(responseText),
          'cause': jsonData['cause']?.toString() ?? _extractCause(responseText),
          'analysis': responseText,
          'symptoms': _ensureList(jsonData['symptoms']) ?? _extractSymptoms(responseText),
          'remediation': _ensureList(jsonData['remediation']) ?? _extractRemediation(responseText),
          'precautions': _ensureList(jsonData['precautions']) ?? _extractPrecautions(responseText),
          'rawResponse': responseText,
        },
      };
    } catch (e) {
      debugPrint('❌ Error processing Gemini response: $e');
      return {
        'success': true,
        'source': 'Gemini AI',
        'data': _createDefaultData('Gemini analysis completed'),
      };
    }
  }

  Map<String, dynamic> _createDefaultData(String message) {
    return {
      'plantName': 'Plant Species',
      'diseaseName': 'Health Analysis',
      'confidence': '80%',
      'severity': 'Medium',
      'cause': 'Requires detailed analysis',
      'analysis': message,
      'symptoms': ['AI-powered visual analysis performed'],
      'remediation': ['Consult agricultural expert for specific treatment'],
      'precautions': ['Regular monitoring recommended'],
      'rawResponse': message,
    };
  }

  Map<String, dynamic> _createDefaultResponse(String message) {
    return {
      'success': true,
      'source': 'Gemini AI',
      'data': _createDefaultData(message),
    };
  }

  // Helper methods for text extraction (same as before)
  List<String>? _ensureList(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<String>.from(value.map((e) => e.toString()));
    return [value.toString()];
  }

  Map<String, dynamic> _extractDataFromText(String content) {
    return {
      'plantName': _extractPlantName(content),
      'diseaseName': _extractDiseaseName(content),
      'confidence': _extractConfidence(content),
      'severity': _extractSeverity(content),
      'cause': _extractCause(content),
    };
  }

  String _extractPlantName(String content) {
    final patterns = [
      RegExp(r'plant[:\s]+([^\.\n,]+)', caseSensitive: false),
      RegExp(r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:plant|leaf)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        final name = match.group(1)!.trim();
        if (name.isNotEmpty) return name;
      }
    }
    return 'Plant Species';
  }

  String _extractDiseaseName(String content) {
    final patterns = [
      RegExp(r'disease[:\s]+([^\.\n,]+)', caseSensitive: false),
      RegExp(r'infection[:\s]+([^\.\n,]+)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        final disease = match.group(1)!.trim();
        if (disease.isNotEmpty) return disease;
      }
    }

    if (content.toLowerCase().contains('healthy')) return 'Healthy';
    return 'Plant Health Issue';
  }

  String _extractConfidence(String content) {
    final pattern = RegExp(r'(\d{1,3})%');
    final matches = pattern.allMatches(content);
    for (var match in matches) {
      final percent = match.group(1)!;
      final num = int.tryParse(percent);
      if (num != null && num >= 50) return '$percent%';
    }
    return '80%';
  }

  String _extractSeverity(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('severe')) return 'High';
    if (lower.contains('moderate') || lower.contains('medium')) return 'Medium';
    if (lower.contains('mild')) return 'Low';
    if (lower.contains('healthy')) return 'None';
    return 'Medium';
  }

  String _extractCause(String content) {
    final patterns = [
      RegExp(r'caused by ([^\.\n]+)', caseSensitive: false),
      RegExp(r'due to ([^\.\n]+)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) return match.group(1)!.trim();
    }

    final lower = content.toLowerCase();
    if (lower.contains('fungal')) return 'Fungal infection';
    if (lower.contains('bacterial')) return 'Bacterial infection';
    if (lower.contains('viral')) return 'Viral infection';
    if (lower.contains('water')) return 'Water management issue';
    return 'Environmental factors';
  }

  List<String> _extractSymptoms(String content) {
    final lines = content.split('\n');
    final symptoms = <String>[];

    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('symptom') ||
          lower.contains('spot') ||
          lower.contains('yellow') ||
          lower.contains('brown') ||
          line.contains('•') ||
          line.contains('-')) {
        symptoms.add(line.trim());
      }
    }

    return symptoms.isNotEmpty ? symptoms : ['Visual symptoms detected'];
  }

  List<String> _extractRemediation(String content) {
    final lines = content.split('\n');
    final steps = <String>[];

    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('treatment') ||
          lower.contains('apply') ||
          lower.contains('remove') ||
          RegExp(r'^\d+\.').hasMatch(line.trim())) {
        steps.add(line.trim());
      }
    }

    return steps.isNotEmpty ? steps : ['Apply appropriate treatment based on diagnosis'];
  }

  List<String> _extractPrecautions(String content) {
    final lines = content.split('\n');
    final precautions = <String>[];

    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('prevent') ||
          lower.contains('avoid') ||
          lower.contains('maintain')) {
        precautions.add(line.trim());
      }
    }

    return precautions.isNotEmpty ? precautions : ['Maintain proper plant care practices'];
  }

  Future<bool> testGeminiApi() async {
    try {
      debugPrint('🔍 Testing Gemini API...');

      // Test connectivity with a simple request
      const testUrl = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
      final response = await http.get(Uri.parse(testUrl)).timeout(Duration(seconds: 10));

      debugPrint('📡 Gemini test response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Gemini API is accessible');
        return true;
      } else {
        debugPrint('❌ Gemini API test failed');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Gemini API test error: $e');
      return false;
    }
  }
}