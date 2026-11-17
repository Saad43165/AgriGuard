import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'groq_client.dart';
import 'groq_agronomy.dart';
import 'groq_translation.dart';
import 'groq_vision.dart';
import 'groq_plant_info.dart';

class GroqService {
  late final GroqClient _client;
  late final GroqAgronomy _agronomy;
  late final GroqTranslation _translation;
  late final GroqVision _vision;
  late final GroqPlantInfo _plantInfo;

  GroqService() {
    _client = GroqClient();
    _agronomy = GroqAgronomy(_client);
    _translation = GroqTranslation(_client);
    _vision = GroqVision(_client);
    _plantInfo = GroqPlantInfo(_client);
  }

  bool hasApiKey() => _client.hasApiKey();

  Future<Map<String, dynamic>> generateAgronomyAdvice({
    required String plantName,
    required String diseaseName,
    required String severity,
    required num confidencePercent,
    bool inUrdu = false,
  }) => _agronomy.generate(
    plantName: plantName,
    diseaseName: diseaseName,
    severity: severity,
    confidencePercent: confidencePercent,
    inUrdu: inUrdu,
  );

  Future<Map<String, dynamic>> translateToUrdu({required String text, int maxChars = 7000}) =>
      _translation.translateToUrdu(text: text, maxChars: maxChars);

  Future<Map<String, dynamic>> translateScanDataToUrdu({required Map<String, dynamic> data}) =>
      _translation.translateScanDataToUrdu(data: data);

  Future<Map<String, dynamic>?> analyzePlantDiseaseFromImage({
    required String imageBase64,
    bool inUrdu = false,
  }) => _vision.analyzeImage(imageBase64: imageBase64, inUrdu: inUrdu);

  Future<Map<String, dynamic>?> generatePlantInfo({
    required String plantName,
    required String scientificName,
    bool inUrdu = false,
  }) => _plantInfo.generate(plantName: plantName, scientificName: scientificName, inUrdu: inUrdu);

  Future<bool> testGroqApi() async {
    try {
      final apiKey = _client.requireApiKey();
      final resp = await http.post(
        Uri.parse(GroqClient.endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'temperature': 0,
          'max_tokens': 10,
          'messages': [{'role': 'user', 'content': 'Return {"ok":true} only.'}],
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 15));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}