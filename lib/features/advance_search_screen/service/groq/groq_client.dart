import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqClient {
  static const String endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  bool hasApiKey() {
    final key = dotenv.env['GROQ_API_KEY']?.trim();
    return key != null && key.isNotEmpty;
  }

  String requireApiKey() {
    final key = dotenv.env['GROQ_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw Exception('Missing GROQ_API_KEY. Add it to your .env file.');
    }
    return key;
  }

  String model() {
    final m = dotenv.env['GROQ_MODEL']?.trim();
    return (m != null && m.isNotEmpty) ? m : 'llama-3.1-8b-instant';
  }

  String visionModel() {
    final m = dotenv.env['GROQ_VISION_MODEL']?.trim();
    return (m != null && m.isNotEmpty) ? m : 'llama-3.2-90b-vision-preview';
  }
}