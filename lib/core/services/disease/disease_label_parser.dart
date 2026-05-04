import 'package:flutter/foundation.dart';

class DiseaseLabelParser {
  static const _knownPlants = ['bean', 'corn', 'fig', 'grape', 'walnut', 'tomato'];

  static const _plantNameMap = {
    'bean': 'Bean', 'corn': 'Corn', 'maize': 'Corn',
    'fig': 'Fig', 'grape': 'Grape', 'walnut': 'Walnut', 'tomato': 'Tomato',
  };

  Map<String, dynamic> parse(String label) {
    try {
      debugPrint('🔍 Parsing label: "$label"');

      String rawPlant;
      String diseasePart;

      if (label.contains('___')) {
        final parts = label.split('___');
        rawPlant = parts[0].trim();
        diseasePart = parts.length > 1 ? parts[1].replaceAll('_', ' ').trim() : 'Unknown';
      } else {
        final normalized = label.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        final words = normalized.split(' ');
        rawPlant = words[0];

        final matched = _knownPlants.firstWhere(
              (p) => words[0].toLowerCase() == p || words[0].toLowerCase().startsWith(p),
          orElse: () => '',
        );

        diseasePart = words.length > 1 ? words.sublist(1).join(' ').trim() : 'Normal';
      }

      final plantName = normalize(rawPlant);
      final cleanDisease = _cleanDiseasePart(diseasePart);
      final isHealthy = _isHealthyLabel(cleanDisease);

      final diseaseName = isHealthy ? 'Healthy' : _titleCase(cleanDisease);

      debugPrint('📋 Parsed: Plant="$plantName", Disease="$diseaseName", Healthy=$isHealthy');

      return {
        'plantName': plantName,
        'diseaseName': diseaseName,
        'isHealthy': isHealthy,
        'rawLabel': label,
      };
    } catch (e) {
      debugPrint('❌ Error parsing label: $e');
      return {'plantName': 'Plant', 'diseaseName': 'Unknown', 'isHealthy': false, 'rawLabel': label};
    }
  }

  String normalize(String raw) {
    return _plantNameMap[raw] ?? _plantNameMap[raw.toLowerCase()] ?? _titleCase(raw);
  }

  String _cleanDiseasePart(String part) {
    return part
        .replaceAll(RegExp(r'\bleaf\b\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bimage\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isHealthyLabel(String disease) {
    final d = disease.toLowerCase();
    return d.isEmpty || d == 'healthy' || d == 'normal' ||
        d == 'normal leaf' || d == 'healthy leaf';
  }

  String _titleCase(String s) {
    return s.replaceAll('_', ' ').split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}