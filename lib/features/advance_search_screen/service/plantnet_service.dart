import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PlantNetService {
  static const String _baseUrl = 'https://my.plantnet.org';

  String? get _apiKey => dotenv.env['PLANTNET_API_KEY']?.trim();

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<Map<String, dynamic>> identify(File imageFile) async {
    if (!hasApiKey) {
      return {'success': false, 'error': 'Missing PLANTNET_API_KEY'};
    }

    try {
      if (!await imageFile.exists()) {
        return {'success': false, 'error': 'Image file not found'};
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final requestBody = [
        {'url': 'data:image/jpeg;base64,$base64Image'}
      ];

      debugPrint('🌿 Calling PlantNet API...');

      final resp = await http.post(
        Uri.parse('$_baseUrl/api/v1/identification/all?api-key=$_apiKey&include-related=true'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🌿 PlantNet response: ${resp.statusCode}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        if (data.isEmpty) {
          return {'success': false, 'error': 'No results returned'};
        }

        final result = data[0] as Map<String, dynamic>;
        final suggestions = result['suggestions'] as List<dynamic>? ?? [];
        
        if (suggestions.isEmpty) {
          return {'success': false, 'error': 'No plant identified'};
        }

        final top = suggestions[0] as Map<String, dynamic>;
        final project = top['project'] as Map<String, dynamic>? ?? {};
        final species = project['scientificName'] ?? 'Unknown';
        final commonNames = (top['commonNames'] as List<dynamic>?)?.cast<String>() ?? [];
        final score = (top['score'] ?? 0) * 100;

        return {
          'success': true,
          'scientificName': species,
          'commonName': commonNames.isNotEmpty ? commonNames.first : species.toString().split(' ').last,
          'confidence': score,
          'allSuggestions': suggestions.take(3).map((s) => {
            'name': (s['project']?['scientificName'] ?? 'Unknown').toString().split(' ').last,
            'score': ((s['score'] ?? 0) * 100).toStringAsFixed(1),
          }).toList(),
        };
      } else {
        return {'success': false, 'error': 'API error: ${resp.statusCode}'};
      }
    } catch (e) {
      debugPrint('❌ PlantNet error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}