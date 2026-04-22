import 'dart:convert';
import 'dart:async';
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

  /// Groq is used here for **text reasoning** on top of on-device detections.
  /// It does NOT do image vision; the caller should provide detected fields.
  Future<Map<String, dynamic>> generateAgronomyAdvice({
    required String plantName,
    required String diseaseName,
    required String severity,
    required num confidencePercent,
    bool inUrdu = false,
  }) async {
    try {
      final apiKey = _requireApiKey();

      final langInstruction = inUrdu
          ? '\nIMPORTANT: Respond ENTIRELY in Urdu script (اردو). All field values must be in Urdu.'
          : '';

      final system = '''
You are an expert agronomist assistant for a farmer-facing mobile app called AgriGuard.
Your job is to provide accurate, practical plant disease advice.$langInstruction

Return ONLY a single valid JSON object (no markdown, no explanation) with these exact fields:
{
  "plantName": "string — common plant name",
  "diseaseName": "string — disease name or Healthy",
  "confidence": "string — e.g. 87.5",
  "severity": "None | Low | Medium | High | Critical",
  "cause": "string — primary cause (fungal/bacterial/viral/environmental)",
  "symptoms": ["string", "string", "string"],
  "remediation": ["string", "string", "string", "string"],
  "precautions": ["string", "string", "string"]
}

Rules:
- If diseaseName is "Healthy", severity must be "None"
- remediation must be specific, actionable, and safe for small farmers
- symptoms must be observable visual signs
- Keep each string under 100 characters
- Do NOT include markdown, code blocks, or extra text
''';

      final user = 'Plant: $plantName\nDisease: $diseaseName\nSeverity: $severity\nConfidence: $confidencePercent%\n\nGenerate the JSON.';

      final body = {
        'model': dotenv.env['GROQ_MODEL']?.trim().isNotEmpty == true
            ? dotenv.env['GROQ_MODEL']!.trim()
            : 'llama-3.1-8b-instant',
        'temperature': 0.2,
        'max_tokens': 900,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'response_format': {'type': 'json_object'},
      };

      Future<http.Response> postWithModel(String modelId) {
        final patched = Map<String, dynamic>.from(body)..['model'] = modelId;
        return http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode(patched),
            )
            .timeout(const Duration(seconds: 45));
      }

      http.Response resp;
      try {
        resp = await postWithModel(body['model'] as String);
      } on TimeoutException {
        // one retry for slow networks
        resp = await postWithModel(body['model'] as String);
      }
      // Auto-fallback if model is decommissioned
      if (resp.statusCode == 400 &&
          resp.body.toLowerCase().contains('decommissioned')) {
        resp = await postWithModel('llama-3.1-8b-instant');
      }

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
      String? content;
      if (choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final msg = first['message'];
          if (msg is Map<String, dynamic>) {
            content = msg['content']?.toString();
          }
        }
      }

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
}

