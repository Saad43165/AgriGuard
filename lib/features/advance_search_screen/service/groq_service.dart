import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  bool hasApiKey() {
    final key = dotenv.env['GROQ_API_KEY']?.trim();
    return key != null && key.isNotEmpty;
  }

  String _requireApiKey() {
    final key = dotenv.env['GROQ_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw Exception('Missing GROQ_API_KEY. Add it to your .env file.');
    }
    return key;
  }

  String _model() {
    final m = dotenv.env['GROQ_MODEL']?.trim();
    return (m != null && m.isNotEmpty) ? m : 'llama-3.1-8b-instant';
  }

  Future<Map<String, dynamic>> generateAgronomyAdvice({
    required String plantName,
    required String diseaseName,
    required String severity,
    required num confidencePercent,
    bool inUrdu = false,
  }) async {
    try {
      final apiKey = _requireApiKey();

      final system = '''
You are an expert agronomist assistant for a farmer-facing mobile app called AgriGuard.
Your job is to provide accurate, practical plant disease advice in simple, easy-to-understand language.

Return ONLY a single valid JSON object (no markdown, no explanation) with these exact fields:
{
  "plantName": "string — common plant name (e.g., Tomato, Potato, Wheat in local language)",
  "plantNameUrdu": "string — plant name in Urdu script (e.g., ٹماٹر, آلو, گندم)",
  "plantDescription": "string — 1-line easy description about this plant for common farmers",
  "diseaseName": "string — disease name or Healthy",
  "confidence": "string — e.g. 87.5",
  "severity": "None | Low | Medium | High | Critical",
  "cause": "string — primary cause (fungal/bacterial/viral/environmental/nutrient deficiency)",
  "symptoms": ["string", "string", "string"],
  "remediation": ["string", "string", "string", "string"],
  "precautions": ["string", "string", "string"],
  "diseaseDescription": "string — easy explanation of what this disease is and how it affects the plant",
  "preventionTips": ["string", "string", "string"]
}

Rules:
- If diseaseName is "Healthy", severity must be "None"
- Use SIMPLE language that any farmer can understand
- Avoid scientific jargon
- remediation must be specific, actionable, and safe for small farmers
- symptoms must be observable visual signs
- Keep each string under 100 characters
- Do NOT include markdown, code blocks, or extra text
- ALWAYS include plantNameUrdu field for Urdu
''';

      final user =
          'Plant: $plantName\nDisease: $diseaseName\nSeverity: $severity\nConfidence: $confidencePercent%\n\nGenerate the JSON.';

      final body = {
        'model': _model(),
        'temperature': 0.2,
        'max_tokens': 1200,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'response_format': {'type': 'json_object'},
      };

      final resp = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 45));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return {
          'success': false,
          'error': 'Groq request failed',
          'message': 'Groq API error ${resp.statusCode}: ${resp.body}',
          'source': 'Groq AI',
        };
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;

      if (content == null || content.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Groq response empty',
          'message': 'Groq returned an empty response',
          'source': 'Groq AI',
        };
      }

      final data = jsonDecode(content) as Map<String, dynamic>;
      return {
        'success': true,
        'source': 'Groq AI',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'isRealData': true,
      };
    } catch (e) {
      debugPrint('❌ Groq exception: $e');
      return {
        'success': false,
        'error': 'Groq analysis failed',
        'message': e.toString(),
        'source': 'Groq AI',
      };
    }
  }

  /// Translate ANY arbitrary text to Urdu (used for long paragraphs)
  Future<Map<String, dynamic>> translateToUrdu({
    required String text,
    int maxChars = 7000,
  }) async {
    try {
      final apiKey = _requireApiKey();
      final trimmed = text.length > maxChars ? text.substring(0, maxChars) : text;

      final system = '''
You are a professional Urdu translator for an agriculture mobile app.
Translate the user's text into natural Urdu.

Rules:
- Return ONLY a single valid JSON object: {"translation":"..."}
- Keep emojis, bullet points, and formatting (newlines) as close as possible.
- Do NOT add extra explanation.
''';

      final body = {
        'model': _model(),
        'temperature': 0.1,
        'max_tokens': 1400,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': trimmed},
        ],
        'response_format': {'type': 'json_object'},
      };

      final resp = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 40));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return {
          'success': false,
          'error': 'Groq translation failed',
          'message': 'Groq API error ${resp.statusCode}: ${resp.body}',
        };
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;

      if (content == null || content.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Empty translation',
          'message': 'Groq returned empty translation content',
        };
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final translation = json['translation']?.toString();

      if (translation == null || translation.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Translation missing',
          'message': 'Groq response JSON missing "translation"',
        };
      }

      return {'success': true, 'translation': translation};
    } catch (e) {
      debugPrint('❌ Groq translate exception: $e');
      return {
        'success': false,
        'error': 'Groq translation exception',
        'message': e.toString(),
      };
    }
  }

  /// ✅ SINGLE-CALL: translate your entire `data` map into Urdu JSON
  /// This is cheaper and faster than translating item-by-item.
  Future<Map<String, dynamic>> translateScanDataToUrdu({
    required Map<String, dynamic> data,
  }) async {
    try {
      final apiKey = _requireApiKey();

      final system = '''
You translate agriculture scan results into Urdu for a farmer-facing app.

Task:
- Translate ALL string fields and list items into Urdu.
- Keep keys EXACTLY the same.
- Keep numbers, percentages, and units unchanged.
- If a value is not translatable (empty/null), keep it as-is.
- Return ONLY valid JSON (no markdown).
- ALWAYS translate plantName to Urdu (e.g., Tomato → ٹماٹر, Potato → آلو, Wheat → گندم, Corn → مکئی)
- Add a new field "plantNameUrdu" with the Urdu name for the plant
- Add "plantDescription" and "diseaseDescription" in simple Urdu
- Use SIMPLE language that any farmer can understand

Input JSON schema example:
{
  "plantName": "...",
  "plantNameUrdu": "...",
  "plantDescription": "...",
  "scientificName": "...",
  "diseaseName": "...",
  "diseaseDescription": "...",
  "severity": "...",
  "confidence": "... or number",
  "cause": "...",
  "symptoms": ["..."],
  "remediation": ["..."],
  "precautions": ["..."],
  "preventionTips": ["..."],
  "additionalInfo": "..."
}
''';

      final user = jsonEncode(data);

      final body = {
        'model': _model(),
        'temperature': 0.1,
        'max_tokens': 1800,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'response_format': {'type': 'json_object'},
      };

      final resp = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 45));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return {
          'success': false,
          'error': 'Groq translation failed',
          'message': 'Groq API error ${resp.statusCode}: ${resp.body}',
        };
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;

      if (content == null || content.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Empty translation',
          'message': 'Groq returned empty JSON',
        };
      }

      final translated = jsonDecode(content);
      if (translated is! Map) {
        return {
          'success': false,
          'error': 'Invalid translation format',
          'message': 'Groq did not return a JSON object',
        };
      }

      return {
        'success': true,
        'data': Map<String, dynamic>.from(translated as Map),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Groq translation exception',
        'message': e.toString(),
      };
    }
  }

  Future<bool> testGroqApi() async {
    try {
      final apiKey = _requireApiKey();
      final resp = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'temperature': 0,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Return {"ok":true} only.'},
          ],
          'response_format': {'type': 'json_object'},
        }),
      )
          .timeout(const Duration(seconds: 15));

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  String _visionModel() {
    final m = dotenv.env['GROQ_VISION_MODEL']?.trim();
    return (m != null && m.isNotEmpty) ? m : 'llama-3.2-90b-vision-preview';
  }

  Future<Map<String, dynamic>?> generatePlantInfo({
    required String plantName,
    required String scientificName,
    bool inUrdu = false,
  }) async {
    if (!hasApiKey()) return null;

    try {
      final apiKey = _requireApiKey();
      final lang = inUrdu ? 'اردو' : 'English';

      final system = '''
You are an expert agronomist for the AgriGuard app. Provide clear, practical information about plants for farmers.
Respond in $lang with simple language that any farmer can understand.
Return ONLY valid JSON (no markdown):
{
  "overview": "2-3 sentences about this plant including its importance to farmers",
  "uses": ["use1", "use2", "use3"],
  "growing": "simple growing instructions",
  "care": "basic care tips",
  "problems": "common problems to watch for"
}
''';

      final user = 'Plant: $plantName ($scientificName)';
      
      final body = {
        'model': _model(),
        'temperature': 0.3,
        'max_tokens': 500,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'response_format': {'type': 'json_object'},
      };

      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;
      
      if (content == null || content.trim().isEmpty) return null;

      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzePlantDiseaseFromImage({
    required String imageBase64,
    bool inUrdu = false,
  }) async {
    if (!hasApiKey()) return null;

    try {
      final apiKey = _requireApiKey();
      final lang = inUrdu ? 'اردو' : 'English';

      final system = '''
You are an expert agronomist for a farmer-facing mobile app.
Your job is to analyze plant images and diagnose diseases accurately.

Return ONLY valid JSON (no markdown, no explanation):
{
  "plantName": "string — detected plant name",
  "plantNameUrdu": "string — plant name in Urdu script",
  "isHealthy": boolean,
  "diseaseName": "string — disease name or 'Healthy' if no disease detected",
  "diseaseNameUrdu": "string — disease name in Urdu script",
  "confidence": "string — e.g. '87.5'",
  "severity": "None | Low | Medium | High | Critical",
  "cause": "string — cause (fungal/bacterial/viral/environmental/nutrient deficiency/pest)",
  "causeUrdu": "string — cause in Urdu",
  "symptoms": ["observable symptom 1", "symptom 2", "symptom 3"],
  "symptomsUrdu": ["symptom 1 in Urdu", "symptom 2 in Urdu", "symptom 3 in Urdu"],
  "remediation": ["actionable remediation step 1", "step 2", "step 3", "step 4"],
  "remediationUrdu": ["step 1 in Urdu", "step 2 in Urdu", "step 3 in Urdu", "step 4 in Urdu"],
  "precautions": ["prevention tip 1", "tip 2", "tip 3"],
  "precautionsUrdu": ["tip 1 in Urdu", "tip 2 in Urdu", "tip 3 in Urdu"],
  "diseaseDescription": "string — easy explanation of what this disease is",
  "diseaseDescriptionUrdu": "string — in Urdu",
  "preventionTips": ["tip 1", "tip 2", "tip 3"],
  "preventionTipsUrdu": ["tip 1 in Urdu", "tip 2 in Urdu", "tip 3 in Urdu"],
  "additionalNotes": "any important notes for the farmer"
}

Rules:
- Response in $lang with simple language any farmer can understand
- Use SIMPLE language, avoid scientific jargon
- If plant looks healthy, set isHealthy: true and severity: "None"
- symptoms must be visual/observable signs
- remediation must be specific, actionable, safe for small farmers
- Keep each string under 100 characters
- Do NOT include markdown, code blocks, or extra text
- Respond in the same language as the user's prompt
- ALWAYS include Urdu fields when appropriate
''';

      final body = {
        'model': _visionModel(),
        'temperature': 0.2,
        'max_tokens': 1500,
        'messages': [
          {
            'role': 'system',
            'content': system,
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$imageBase64',
                },
              },
              {
                'type': 'text',
                'text': 'Analyze this plant image and identify any diseases. Provide diagnosis with cause, symptoms, treatment, and prevention.',
              },
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
      };

      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('Groq API error: ${resp.statusCode} ${resp.body}');
        return null;
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;

      if (content == null || content.trim().isEmpty) return null;

      return jsonDecode(content);
    } catch (e) {
      debugPrint('Groq image analysis error: $e');
      return null;
    }
  }
}