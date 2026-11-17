import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'groq_client.dart';

class GroqTranslation {
  final GroqClient _client;

  GroqTranslation(this._client);

  Future<Map<String, dynamic>> translateToUrdu({
    required String text,
    int maxChars = 7000,
  }) async {
    try {
      final apiKey = _client.requireApiKey();
      final trimmed = text.length > maxChars ? text.substring(0, maxChars) : text;

      final system = '''
You are a professional Urdu translator for an agriculture mobile app.
Translate the user's text into natural Urdu.
Return ONLY a single valid JSON object: {"translation":"..."}
Keep emojis, bullet points, and formatting as close as possible.
Do NOT add extra explanation.
''';

      final body = {
        'model': _client.model(),
        'temperature': 0.1,
        'max_tokens': 1400,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': trimmed},
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
          .timeout(const Duration(seconds: 40));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return {
          'success': false,
          'error': 'Groq translation failed',
          'message': 'Groq API error ${resp.statusCode}',
        };
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;

      if (content == null || content.trim().isEmpty) {
        return {'success': false, 'error': 'Empty translation'};
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final translation = json['translation']?.toString();

      if (translation == null || translation.trim().isEmpty) {
        return {'success': false, 'error': 'Translation missing'};
      }

      return {'success': true, 'translation': translation};
    } catch (e) {
      debugPrint('❌ Groq translate exception: $e');
      return {'success': false, 'error': 'Groq translation exception', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> translateScanDataToUrdu({
    required Map<String, dynamic> data,
  }) async {
    try {
      final apiKey = _client.requireApiKey();

      final system = '''
You translate agriculture scan results into Urdu for a farmer-facing app.
Translate ALL string fields and list items into Urdu.
Keep keys EXACTLY the same. Keep numbers, percentages, and units unchanged.
Return ONLY valid JSON (no markdown).
ALWAYS translate plantName to Urdu (e.g., Tomato → ٹماٹر, Potato → آلو)
Add "plantNameUrdu" field with Urdu name.
Use SIMPLE language any farmer can understand.
''';

      final body = {
        'model': _client.model(),
        'temperature': 0.1,
        'max_tokens': 1800,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': jsonEncode(data)},
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
          .timeout(const Duration(seconds: 45));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return {'success': false, 'error': 'Groq translation failed'};
      }

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      final msg = choices.isNotEmpty ? (choices.first as Map)['message'] : null;
      final content = msg is Map ? msg['content']?.toString() : null;

      if (content == null || content.trim().isEmpty) {
        return {'success': false, 'error': 'Empty translation'};
      }

      final translated = jsonDecode(content);
      if (translated is! Map) {
        return {'success': false, 'error': 'Invalid translation format'};
      }

      return {'success': true, 'data': Map<String, dynamic>.from(translated as Map)};
    } catch (e) {
      return {'success': false, 'error': 'Groq translation exception', 'message': e.toString()};
    }
  }
}