import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantIdClient {
  static const String baseUrl = 'https://api.plant.id/v3';

  bool hasApiKey() {
    final key = dotenv.env['PLANTID_API_KEY']?.trim();
    return key != null && key.isNotEmpty;
  }

  String requireApiKey() {
    final key = dotenv.env['PLANTID_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw Exception('Missing PLANTID_API_KEY. Add it to your .env file.');
    }
    return key;
  }
}