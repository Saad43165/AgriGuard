import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HuggingFaceVisionService {
  bool hasToken() {
    final token = dotenv.env['HF_API_TOKEN']?.trim();
    return token != null && token.isNotEmpty;
  }

  String _requireToken() {
    final token = dotenv.env['HF_API_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      throw Exception('Missing HF_API_TOKEN. Add it to your .env file.');
    }
    return token;
  }

  String _model() {
    final model = dotenv.env['HF_MODEL']?.trim();
    // Default is configurable; user should set HF_MODEL to a plant-disease model.
    return (model != null && model.isNotEmpty)
        ? model
        : 'dima806/plant-disease-classification';
  }

  Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required List<int> body,
  }) async {
    // Connection resets happen frequently on some mobile networks / ISPs.
    // Retry a couple of times with small backoff.
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 45));
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    // unreachable, but keeps analyzer happy
    throw Exception(lastError?.toString() ?? 'Unknown network error');
  }

  Future<Map<String, dynamic>> classifyPlantDisease(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final token = _requireToken();
      final model = _model();
      // HF migrated serverless inference from api-inference.huggingface.co to router.huggingface.co.
      // Router expects the model id as path segments (org/model), not a single encoded string.
      final modelParts = model.split('/').where((p) => p.trim().isNotEmpty).toList();
      final uri = Uri.https(
        'router.huggingface.co',
        '/hf-inference/models/${modelParts.join('/')}',
      );

      final bytes = await imageFile.readAsBytes();
      final resp = await _postWithRetry(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/octet-stream',
          // Some networks/proxies behave better with an explicit UA.
          'User-Agent': 'AgriGuard/1.0 (Flutter)',
        },
        body: bytes,
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final bodyLower = resp.body.toLowerCase();
        if (resp.statusCode == 401 || resp.statusCode == 403) {
          return {
            'success': false,
            'error': 'HuggingFace unauthorized',
            'message':
                'Hugging Face token is invalid or missing permissions. Ensure HF_API_TOKEN is correct and has access to Inference Providers.',
            'source': 'Hugging Face',
            'statusCode': resp.statusCode,
          };
        }
        if (resp.statusCode == 404) {
          return {
            'success': false,
            'error': 'HuggingFace endpoint not found',
            'message':
                'Hugging Face returned 404. This usually means the selected model is NOT hosted by the `hf-inference` provider. Pick a model that supports HF Inference Providers (filter models by inference_provider=hf-inference), or switch to Plant.id.',
            'source': 'Hugging Face',
            'statusCode': resp.statusCode,
          };
        }
        if (bodyLower.contains('invalid username or password')) {
          return {
            'success': false,
            'error': 'HuggingFace auth required',
            'message':
                'This Hugging Face endpoint requires an Authorization token. The app sends it automatically via HF_API_TOKEN; opening the link in a browser will fail.',
            'source': 'Hugging Face',
            'statusCode': resp.statusCode,
          };
        }
        return {
          'success': false,
          'error': 'HuggingFace request failed',
          'message': 'HF error ${resp.statusCode}: ${resp.body}',
          'source': 'Hugging Face',
        };
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['error'] != null) {
        return {
          'success': false,
          'error': 'HuggingFace model error',
          'message': decoded['error'].toString(),
          'source': 'Hugging Face',
        };
      }

      if (decoded is! List) {
        return {
          'success': false,
          'error': 'Unexpected HF response',
          'message': 'Expected a list, got ${decoded.runtimeType}',
          'source': 'Hugging Face',
        };
      }

      final preds = decoded
          .whereType<Map>()
          .map((m) => {
                'label': m['label']?.toString() ?? '',
                'score': (m['score'] is num) ? (m['score'] as num).toDouble() : 0.0,
              })
          .where((m) => (m['label'] as String).isNotEmpty)
          .toList();

      preds.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      if (preds.isEmpty) {
        return {
          'success': false,
          'error': 'No predictions',
          'message': 'HF returned no usable predictions',
          'source': 'Hugging Face',
        };
      }

      return {
        'success': true,
        'source': 'Hugging Face',
        'model': model,
        'predictions': preds.take(5).toList(),
      };
    } catch (e) {
      debugPrint('❌ HF vision exception: $e');
      final msg = e.toString().toLowerCase().contains('connection reset by peer') ||
              e.toString().toLowerCase().contains('socketexception')
          ? 'Network error while contacting Hugging Face. Try again, switch network, or use Plant.id.'
          : e.toString();
      return {
        'success': false,
        'error': 'HuggingFace vision failed',
        'message': msg,
        'source': 'Hugging Face',
      };
    }
  }
}

