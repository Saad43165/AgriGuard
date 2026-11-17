import 'dart:convert';
import 'package:http/http.dart' as http;
import 'groq_client.dart';

class GroqPlantInfo {
  final GroqClient _client;

  GroqPlantInfo(this._client);

  Future<Map<String, dynamic>?> generate({
    required String plantName,
    required String scientificName,
    bool inUrdu = false,
  }) async {
    if (!_client.hasApiKey()) return null;

    try {
      final apiKey = _client.requireApiKey();
      final lang = inUrdu ? 'اردو' : 'English';

      final system = '''
You are an expert agronomist for the AgriGuard app.
Provide clear, practical information about plants for farmers.
Respond in $lang with simple language.
Return ONLY valid JSON (no markdown):
{
  "overview": "2-3 sentences about this plant",
  "uses": ["use1", "use2", "use3"],
  "growing": "simple growing instructions",
  "care": "basic care tips",
  "problems": "common problems to watch for"
}
''';

      final body = {
        'model': _client.model(),
        'temperature': 0.3,
        'max_tokens': 500,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': 'Plant: $plantName ($scientificName)'},
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
}