import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Fetches real crop/disease information from Groq AI.
/// Falls back to curated offline data if no internet.
class CropInfoService {
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // ── Fetch live crop info ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCropInfo(String cropName, String plantType) async {
    try {
      final key = dotenv.env['GROQ_API_KEY'] ?? '';
      if (key.isEmpty) return _fallback(plantType);

      final prompt = '''
You are an agricultural expert. Provide accurate, practical information about "$plantType" crop in JSON format.
Return ONLY valid JSON with this exact structure:
{
  "description": "Brief description of the plant (2 sentences)",
  "growingSeason": "Best growing season/months",
  "waterNeeds": "Water requirements",
  "soilType": "Best soil type",
  "commonDiseases": [
    {"name": "Disease name", "symptoms": "Key symptoms", "treatment": "Treatment method", "severity": "low/medium/high"}
  ],
  "pestManagement": "Key pest management tips",
  "harvestTime": "Days to harvest from planting",
  "yieldPerAcre": "Expected yield per acre",
  "tips": ["Tip 1", "Tip 2", "Tip 3"]
}
Provide exactly 3 common diseases. Keep all text concise and practical for farmers.
''';

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are an agricultural expert. Always respond with valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 800,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        // Extract JSON from response
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = content.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonStr) as Map<String, dynamic>;
          result['source'] = 'live';
          result['plantType'] = plantType;
          return result;
        }
      }
    } catch (e) {
      // Fall through to offline data
    }
    return _fallback(plantType);
  }

  // ── Offline fallback data ─────────────────────────────────────────────────
  static Map<String, dynamic> _fallback(String plantType) {
    final data = _offlineData[plantType.toLowerCase()] ?? _offlineData['default']!;
    return {...data, 'source': 'offline', 'plantType': plantType};
  }

  static const Map<String, Map<String, dynamic>> _offlineData = {
    'tomato': {
      'description': 'Tomato is a warm-season crop widely grown for its edible fruit. It requires full sun and consistent watering for best yield.',
      'growingSeason': 'Spring to Summer (March–August)',
      'waterNeeds': '1–2 inches per week, consistent moisture',
      'soilType': 'Well-drained, fertile loam (pH 6.0–6.8)',
      'commonDiseases': [
        {'name': 'Early Blight', 'symptoms': 'Dark brown spots with concentric rings on lower leaves', 'treatment': 'Apply copper-based fungicide, remove infected leaves', 'severity': 'medium'},
        {'name': 'Late Blight', 'symptoms': 'Water-soaked gray-green lesions, white mold on undersides', 'treatment': 'Apply mancozeb or chlorothalonil immediately', 'severity': 'high'},
        {'name': 'Bacterial Spot', 'symptoms': 'Small dark water-soaked spots on leaves and fruit', 'treatment': 'Copper bactericide spray, avoid overhead irrigation', 'severity': 'medium'},
      ],
      'pestManagement': 'Monitor for aphids, whiteflies, and hornworms. Use neem oil or insecticidal soap for organic control.',
      'harvestTime': '60–85 days from transplant',
      'yieldPerAcre': '15,000–30,000 lbs per acre',
      'tips': ['Stake or cage plants for support', 'Mulch to retain moisture and prevent splash', 'Rotate crops every 3 years'],
    },
    'potato': {
      'description': 'Potato is a cool-season root vegetable and one of the world\'s most important food crops. It grows best in loose, well-drained soil.',
      'growingSeason': 'Spring (February–April) or Fall (August–September)',
      'waterNeeds': '1–2 inches per week, especially during tuber formation',
      'soilType': 'Loose, well-drained sandy loam (pH 5.0–6.0)',
      'commonDiseases': [
        {'name': 'Late Blight', 'symptoms': 'Dark water-soaked lesions on leaves, white mold, rapid plant death', 'treatment': 'Apply fungicide preventively, destroy infected plants', 'severity': 'high'},
        {'name': 'Early Blight', 'symptoms': 'Dark brown spots with yellow halos on older leaves', 'treatment': 'Apply mancozeb or chlorothalonil fungicide', 'severity': 'medium'},
        {'name': 'Scab', 'symptoms': 'Rough corky lesions on tuber surface', 'treatment': 'Maintain soil pH below 5.5, use certified seed potatoes', 'severity': 'low'},
      ],
      'pestManagement': 'Watch for Colorado potato beetle and aphids. Use row covers early season.',
      'harvestTime': '70–120 days from planting',
      'yieldPerAcre': '20,000–40,000 lbs per acre',
      'tips': ['Hill soil around plants as they grow', 'Avoid planting where tomatoes/peppers grew', 'Cure harvested potatoes before storage'],
    },
    'wheat': {
      'description': 'Wheat is a cool-season cereal grain and one of the most widely cultivated crops globally. It is the primary ingredient in bread and flour.',
      'growingSeason': 'Winter wheat: Oct–June | Spring wheat: March–August',
      'waterNeeds': '12–15 inches total, critical during grain fill',
      'soilType': 'Well-drained loam or clay loam (pH 6.0–7.0)',
      'commonDiseases': [
        {'name': 'Stripe Rust', 'symptoms': 'Yellow-orange stripes of pustules along leaf veins', 'treatment': 'Apply triazole fungicide (propiconazole) at first sign', 'severity': 'high'},
        {'name': 'Powdery Mildew', 'symptoms': 'White powdery coating on leaves and stems', 'treatment': 'Apply fungicide, plant resistant varieties', 'severity': 'medium'},
        {'name': 'Septoria Leaf Blotch', 'symptoms': 'Tan lesions with dark borders on lower leaves', 'treatment': 'Apply strobilurin or triazole fungicide', 'severity': 'medium'},
      ],
      'pestManagement': 'Monitor for aphids and Hessian fly. Use certified disease-free seed.',
      'harvestTime': '110–130 days from planting',
      'yieldPerAcre': '1,500–3,000 lbs per acre',
      'tips': ['Plant at correct depth (1–1.5 inches)', 'Apply nitrogen fertilizer at tillering stage', 'Scout fields weekly during growing season'],
    },
    'corn': {
      'description': 'Corn (maize) is a warm-season cereal crop with high yield potential. It is used for food, feed, and industrial purposes.',
      'growingSeason': 'Spring to Summer (April–September)',
      'waterNeeds': '1–1.5 inches per week, critical during silking',
      'soilType': 'Deep, well-drained loam (pH 5.8–7.0)',
      'commonDiseases': [
        {'name': 'Gray Leaf Spot', 'symptoms': 'Rectangular gray-tan lesions parallel to leaf veins', 'treatment': 'Apply triazole fungicide, plant resistant hybrids', 'severity': 'medium'},
        {'name': 'Common Rust', 'symptoms': 'Orange-brown pustules on both leaf surfaces', 'treatment': 'Apply fungicide early, use resistant varieties', 'severity': 'medium'},
        {'name': 'Northern Leaf Blight', 'symptoms': 'Long cigar-shaped gray-green lesions', 'treatment': 'Apply strobilurin fungicide at early infection', 'severity': 'high'},
      ],
      'pestManagement': 'Monitor for corn earworm, fall armyworm, and rootworm. Use pheromone traps.',
      'harvestTime': '60–100 days from planting',
      'yieldPerAcre': '150–200 bushels per acre',
      'tips': ['Plant when soil temp reaches 50°F', 'Side-dress nitrogen at V6 stage', 'Ensure proper plant spacing (8–10 inches)'],
    },
    'apple': {
      'description': 'Apple is a deciduous fruit tree that produces sweet, crisp fruit. It requires cold winters for proper dormancy and fruit development.',
      'growingSeason': 'Blooms spring, harvest late summer to fall',
      'waterNeeds': '1–1.5 inches per week during growing season',
      'soilType': 'Well-drained loam (pH 6.0–7.0)',
      'commonDiseases': [
        {'name': 'Apple Scab', 'symptoms': 'Olive-green to black scabby lesions on leaves and fruit', 'treatment': 'Apply fungicide at green tip, repeat every 7–10 days', 'severity': 'high'},
        {'name': 'Fire Blight', 'symptoms': 'Blossoms and shoots turn brown, shepherd\'s crook appearance', 'treatment': 'Prune 12 inches below infection, apply copper spray', 'severity': 'high'},
        {'name': 'Cedar Apple Rust', 'symptoms': 'Bright orange spots on leaves, tube-like structures', 'treatment': 'Apply myclobutanil fungicide, remove nearby cedar trees', 'severity': 'medium'},
      ],
      'pestManagement': 'Monitor for codling moth, apple maggot, and aphids. Use pheromone traps and kaolin clay.',
      'harvestTime': '3–5 years for first harvest, annual thereafter',
      'yieldPerAcre': '400–800 bushels per acre (mature orchard)',
      'tips': ['Thin fruit to 6 inches apart for larger apples', 'Prune annually during dormancy', 'Apply dormant oil spray before bud break'],
    },
    'grape': {
      'description': 'Grapes are woody perennial vines grown for fresh fruit, wine, and raisins. They thrive in warm, dry climates with well-drained soil.',
      'growingSeason': 'Buds break in spring, harvest late summer to fall',
      'waterNeeds': '20–30 inches annually, reduce near harvest',
      'soilType': 'Well-drained sandy loam or gravel (pH 5.5–6.5)',
      'commonDiseases': [
        {'name': 'Black Rot', 'symptoms': 'Brown circular lesions on leaves, mummified berries', 'treatment': 'Apply myclobutanil or mancozeb from bud break', 'severity': 'high'},
        {'name': 'Powdery Mildew', 'symptoms': 'White powdery coating on leaves, shoots, and berries', 'treatment': 'Apply sulfur or potassium bicarbonate spray', 'severity': 'medium'},
        {'name': 'Downy Mildew', 'symptoms': 'Yellow oil spots on upper leaf, white mold below', 'treatment': 'Apply copper-based fungicide preventively', 'severity': 'high'},
      ],
      'pestManagement': 'Monitor for grape berry moth, leafhoppers, and Japanese beetle.',
      'harvestTime': '2–3 years for first harvest',
      'yieldPerAcre': '2–8 tons per acre depending on variety',
      'tips': ['Train vines on trellis system', 'Prune 80–90% of previous year\'s growth', 'Maintain good air circulation to prevent disease'],
    },
    'default': {
      'description': 'This crop requires proper care and monitoring for optimal yield. Regular scouting and timely interventions are key to success.',
      'growingSeason': 'Varies by region and variety',
      'waterNeeds': '1–2 inches per week',
      'soilType': 'Well-drained fertile soil (pH 6.0–7.0)',
      'commonDiseases': [
        {'name': 'Fungal Blight', 'symptoms': 'Brown spots or lesions on leaves', 'treatment': 'Apply appropriate fungicide, improve air circulation', 'severity': 'medium'},
        {'name': 'Bacterial Infection', 'symptoms': 'Water-soaked spots, wilting', 'treatment': 'Apply copper bactericide, remove infected parts', 'severity': 'medium'},
        {'name': 'Viral Disease', 'symptoms': 'Mosaic patterns, stunted growth', 'treatment': 'Control insect vectors, remove infected plants', 'severity': 'high'},
      ],
      'pestManagement': 'Regular scouting, use integrated pest management (IPM) practices.',
      'harvestTime': 'Varies by crop and variety',
      'yieldPerAcre': 'Varies by crop and conditions',
      'tips': ['Scout fields regularly', 'Maintain proper soil nutrition', 'Practice crop rotation'],
    },
  };
}
