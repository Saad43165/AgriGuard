import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'plant_id_client.dart';

class PlantIdRequest {
  final PlantIdClient _client;

  PlantIdRequest(this._client);

  /// Send request WITH health assessment
  Future<Map<String, dynamic>> sendWithHealth(String base64Image) async {
    final apiKey = _client.requireApiKey();
    final requestBody = {
      'images': [base64Image],
      'health': 'all',
      'similar_images': true,
    };

    debugPrint('📋 Request: health=all, similar_images=true');

    final response = await http.post(
      Uri.parse('${PlantIdClient.baseUrl}/identification'),
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': apiKey,
      },
      body: jsonEncode(requestBody),
    );

    debugPrint('📡 Plant.id Create Response: ${response.statusCode}');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String?;
      if (accessToken == null) throw Exception('No access token in response');
      debugPrint('🔑 Access Token: $accessToken');
      return await _pollForResult(accessToken);
    }

    if (response.statusCode == 429) {
      throw Exception('Plant.id credits exhausted. Visit web.plant.id to purchase more.');
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid Plant.id API key.');
    }
    if (response.statusCode == 400) {
      debugPrint('🔄 Trying minimal request...');
      return await sendMinimal(base64Image);
    }

    throw Exception('Plant.id API error ${response.statusCode}');
  }

  /// Send minimal request (fallback)
  Future<Map<String, dynamic>> sendMinimal(String base64Image) async {
    final apiKey = _client.requireApiKey();
    final minimalBody = {'images': [base64Image]};

    final response = await http.post(
      Uri.parse('${PlantIdClient.baseUrl}/identification'),
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': apiKey,
      },
      body: jsonEncode(minimalBody),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String?;
      if (accessToken == null) throw Exception('No access token');
      return await _pollForResult(accessToken);
    }

    throw Exception('Minimal request failed: ${response.statusCode}');
  }

  /// Poll for result with exponential backoff
  Future<Map<String, dynamic>> _pollForResult(String accessToken) async {
    const maxAttempts = 20;
    int delaySeconds = 1;
    final apiKey = _client.requireApiKey();

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint('🔄 Polling attempt $attempt/$maxAttempts (wait: ${delaySeconds}s)...');

      try {
        final uri = Uri.parse('${PlantIdClient.baseUrl}/identification/$accessToken').replace(
          queryParameters: {'language': 'en', 'details': 'common_names,description,treatment'},
        );

        final response = await http.get(uri, headers: {'Api-Key': apiKey})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final isFinished = data['finished'] as bool? ?? false;
          final status = data['status'] as String?;

          if (isFinished || status == 'COMPLETED') {
            debugPrint('✅ Identification finished');
            return data;
          }

          if (status == 'FAILED' || status == 'ERROR') {
            throw Exception('Identification failed: ${data['error'] ?? 'Unknown error'}');
          }
        }
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
      }

      await Future.delayed(Duration(seconds: delaySeconds));

      // Exponential backoff
      if (attempt < 3) delaySeconds = 2;
      else if (attempt < 7) delaySeconds = 3;
      else if (attempt < 12) delaySeconds = 4;
      else delaySeconds = 5;
    }

    throw Exception('Identification timeout after $maxAttempts attempts');
  }
}