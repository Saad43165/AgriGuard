import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'groq_client.dart';

class GroqAgronomy {
  final GroqClient _client;

  GroqAgronomy(this._client);

  Future<Map<String, dynamic>> generate({
    required String plantName,
    required String diseaseName,
    required String severity,
    required num confidencePercent,
    bool inUrdu = false,
  }) async {
    try {
      final apiKey = _client.requireApiKey();

      final system = '''
You are an expert agronomist assistant for a farmer-facing mobile app called AgriGuard.
Your job is to provide accurate, practical plant disease advice in simple, easy-to-understand language.

Return ONLY a single valid JSON object (no markdown, no explanation) with these exact fields:
{
  "plantName": "string — common plant name",
  "plantNameUrdu": "string — plant name in Urdu script",
  "plantDescription": "string — 1-line easy description for farmers",
  "diseaseName": "string — disease name or Healthy",
  "confidence": "string — e.g. 87.5",
  "severity": "None | Low | Medium | High | Critical",
  "cause": "string — primary cause",
  "symptoms": ["string", "string", "string"],
  "remediation": ["string", "string", "string", "string"],
  "precautions": ["string", "string", "string"],
  "diseaseDescription": "string — easy explanation of disease",
  "preventionTips": ["string", "string", "string"]
}

Rules:
- If diseaseName is "Healthy", severity must be "None"
- Use SIMPLE language any farmer can understand
- Avoid scientific jargon
- remediation must be specific, actionable, and safe for small farmers
- symptoms must be observable visual signs
- Keep each string under 100 characters
- Do NOT include markdown, code blocks, or extra text
- ALWAYS include plantNameUrdu field
''';

      final user = 'Plant: $plantName\nDisease: $diseaseName\nSeverity: $severity\nConfidence: $confidencePercent%\n\nGenerate the JSON.';

      final body = {
        'model': _client.model(),
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
        Uri.parse(GroqClient.endpoint),
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
          'message': 'Groq API error ${resp.statusCode}',
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
}