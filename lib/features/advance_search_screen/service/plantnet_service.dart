// plantnet_service.dart
// Calls your own FastAPI server (server.py) for plant disease detection.
// Server wraps the PlantNet PyTorch model with a REST API.
// Run server: python server.py
// Deploy: Render / Railway / any VPS

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PlantNetService {
  // ── Server URL ─────────────────────────────────────────────────────────────
  // Local testing:  http://10.0.2.2:8000  (Android emulator → localhost)
  // Real device:    http://YOUR_PC_IP:8000  (same WiFi)
  // Production:     https://your-app.onrender.com
  static String get _serverUrl {
    final url = dotenv.env['PLANTNET_SERVER_URL']?.trim();
    return (url != null && url.isNotEmpty) ? url : 'http://10.0.2.2:8000';
  }

  // 38 class names (kept for offline fallback parsing)
  static const List<String> classNames = [
    'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust',
    'Apple___healthy', 'Blueberry___healthy',
    'Cherry_(including_sour)___Powdery_mildew', 'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight', 'Corn_(maize)___healthy',
    'Grape___Black_rot', 'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)', 'Peach___Bacterial_spot', 'Peach___healthy',
    'Pepper,_bell___Bacterial_spot', 'Pepper,_bell___healthy',
    'Potato___Early_blight', 'Potato___Late_blight', 'Potato___healthy',
    'Raspberry___healthy', 'Soybean___healthy', 'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch', 'Strawberry___healthy',
    'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___Late_blight',
    'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite', 'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy',
  ];

  bool hasToken() => true; // always available — own server

  /// Check if server is reachable
  Future<bool> isServerReachable() async {
    try {
      final resp = await http.get(Uri.parse('$_serverUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Classify a plant leaf image using your FastAPI server.
  Future<Map<String, dynamic>> classify(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return {'success': false, 'error': 'Image file not found', 'source': 'PlantNet'};
      }

      final uri = Uri.parse('$_serverUrl/predict_topk?k=5');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['success'] != true) {
          return {'success': false, 'error': 'Server error', 'source': 'PlantNet'};
        }

        final preds = (data['predictions'] as List).map((p) => {
          'label': p['class_name']?.toString() ?? '',
          'score': ((p['confidence'] as num?) ?? 0.0) / 100.0,
          'plant': p['plant']?.toString() ?? '',
          'disease': p['disease']?.toString() ?? '',
          'is_healthy': p['is_healthy'] as bool? ?? false,
        }).toList();

        debugPrint('✅ PlantNet top-3:');
        for (int i = 0; i < 3 && i < preds.length; i++) {
          debugPrint('   ${preds[i]['label']}: ${((preds[i]['score'] as double) * 100).toStringAsFixed(1)}%');
        }

        return {
          'success': true,
          'source': 'PlantNet',
          'predictions': preds,
        };
      }

      if (resp.statusCode == 503 || resp.statusCode == 502) {
        return {
          'success': false,
          'error': 'Server unavailable',
          'message': 'PlantNet server is starting up. Try again in a moment.',
          'source': 'PlantNet',
        };
      }

      return {
        'success': false,
        'error': 'HTTP ${resp.statusCode}',
        'message': 'Server error: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
        'source': 'PlantNet',
      };
    } catch (e) {
      debugPrint('❌ PlantNet error: $e');
      final msg = e.toString();
      return {
        'success': false,
        'error': 'PlantNet request failed',
        'message': msg.contains('SocketException') || msg.contains('Connection refused')
            ? 'Cannot reach PlantNet server. Make sure server.py is running.'
            : msg.contains('TimeoutException')
            ? 'Server timeout. Check your connection.'
            : msg,
        'source': 'PlantNet',
      };
    }
  }

  /// Parse a label like "Tomato___Early_blight" into plant + disease
  static Map<String, String> parseLabel(String label) {
    if (label.contains('___')) {
      final parts = label.split('___');
      final plant = parts[0].replaceAll('_', ' ').replaceAll(',', '').trim();
      final disease = parts[1].replaceAll('_', ' ').trim();
      return {
        'plant': plant,
        'disease': disease.toLowerCase() == 'healthy' ? 'Healthy' : _titleCase(disease),
        'isHealthy': (disease.toLowerCase() == 'healthy').toString(),
      };
    }
    return {'plant': 'Unknown', 'disease': label, 'isHealthy': 'false'};
  }

  static String _titleCase(String s) => s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
