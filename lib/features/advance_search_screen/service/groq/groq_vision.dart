import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'groq_client.dart';

class GroqVision {
  final GroqClient _client;

  GroqVision(this._client);

  Future<Map<String, dynamic>?> analyzeImage({
    required String imageBase64,
    bool inUrdu = false,
  }) async {
    if (!_client.hasApiKey()) return null;

    try {
      final apiKey = _client.requireApiKey();

      final system = '''
You are an expert agronomist for a farmer-facing mobile app.
Analyze plant images and diagnose diseases accurately.
Return ONLY valid JSON (no markdown):
{
  "plantName": "string", "plantNameUrdu": "string",
  "isHealthy": boolean, "diseaseName": "string", "diseaseNameUrdu": "string",
  "confidence": "string", "severity": "None | Low | Medium | High | Critical",
  "cause": "string", "causeUrdu": "string",
  "symptoms": ["..."], "symptomsUrdu": ["..."],
  "remediation": ["..."], "remediationUrdu": ["..."],
  "precautions": ["..."], "precautionsUrdu": ["..."],
  "diseaseDescription": "string", "diseaseDescriptionUrdu": "string",
  "preventionTips": ["..."], "preventionTipsUrdu": ["..."]
}
Use SIMPLE language. If healthy, set isHealthy: true and severity: "None".
''';

      final body = {
        'model': _client.visionModel(),
        'temperature': 0.2,
        'max_tokens': 1500,
        'messages': [
          {'role': 'system', 'content': system},
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
              },
              {'type': 'text', 'text': 'Analyze this plant image and identify any diseases.'},
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
      };

      final resp = await http
          .post(Uri.parse(GroqClient.endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

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