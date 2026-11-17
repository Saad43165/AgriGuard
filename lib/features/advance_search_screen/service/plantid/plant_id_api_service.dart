import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'plant_id_client.dart';
import 'plant_id_request.dart';
import 'plant_id_response_parser.dart';

class PlantIdService {
  late final PlantIdClient _client;
  late final PlantIdRequest _request;
  late final PlantIdResponseParser _parser;

  PlantIdService() {
    _client = PlantIdClient();
    _request = PlantIdRequest(_client);
    _parser = PlantIdResponseParser();
  }

  bool hasApiKey() => _client.hasApiKey();

  Future<bool> testPlantIdApi() async {
    try {
      final apiKey = _client.requireApiKey();
      final response = await http.get(
        Uri.parse('${PlantIdClient.baseUrl}/usage_info'),
        headers: {'Api-Key': apiKey},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Plant.id test error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> analyzeWithPlantId(File imageFile) async {
    try {
      debugPrint('🌿 Starting Plant.id v3 analysis...');

      if (!await imageFile.exists()) throw Exception('Image file not found');

      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) throw Exception('Image too large (max 5MB)');
      if (fileSize < 1024) throw Exception('Image too small (min 1KB)');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final rawResponse = await _request.sendWithHealth(base64Image);
      return _parser.parse(rawResponse);
    } catch (e) {
      debugPrint('❌ Plant.id analysis error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Plant.id analysis failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getApiStatus() async {
    try {
      final apiKey = _client.requireApiKey();
      final response = await http.get(
        Uri.parse('${PlantIdClient.baseUrl}/usage_info'),
        headers: {'Api-Key': apiKey},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': 'API is working',
          'version': 'v3',
          'details': jsonDecode(response.body),
        };
      }
      return {'success': false, 'status': 'API connection issue'};
    } catch (e) {
      return {'success': false, 'status': 'Connection failed', 'error': e.toString()};
    }
  }
}