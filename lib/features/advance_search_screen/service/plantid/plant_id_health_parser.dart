import 'package:flutter/foundation.dart';

class PlantIdHealthParser {
  /// Extract disease information from health assessment
  Map<String, dynamic> extract(Map<String, dynamic> result) {
    final isHealthy = result['is_healthy'] as Map<String, dynamic>?;
    final isHealthyBinary = isHealthy?['binary'] as bool? ?? true;
    final isHealthyProb = (isHealthy?['probability'] as num?)?.toDouble() ?? 1.0;

    debugPrint('💚 Health: ${isHealthyBinary ? "HEALTHY" : "DISEASED"} (${(isHealthyProb * 100).toStringAsFixed(1)}%)');

    if (isHealthyBinary) {
      return {
        'hasDiseaseInfo': false,
        'diseaseName': 'Healthy',
        'severity': 'None',
        'diseaseProbability': 0.0,
        'symptoms': ['No visible disease symptoms detected'],
        'treatments': ['Continue regular plant care'],
        'precautions': ['Monitor plant regularly for any changes'],
      };
    }

    return _extractDiseaseInfo(result, isHealthyProb);
  }

  Map<String, dynamic> _extractDiseaseInfo(Map<String, dynamic> result, double healthyProb) {
    final diseaseSection = result['disease'] as Map<String, dynamic>?;
    String diseaseName = 'Plant Stress';
    double diseaseProb = 1.0 - healthyProb;
    List<String> symptoms = ['Plant shows signs of stress or poor health'];
    List<String> treatments = ['Remove affected parts', 'Improve air circulation'];
    List<String> precautions = ['Monitor daily', 'Maintain proper spacing'];

    if (diseaseSection != null) {
      final suggestions = diseaseSection['suggestions'] as List<dynamic>? ?? [];
      if (suggestions.isNotEmpty) {
        final topDisease = suggestions.first as Map<String, dynamic>;
        diseaseName = topDisease['name'] as String? ?? 'Unknown Disease';
        diseaseProb = (topDisease['probability'] as num?)?.toDouble() ?? 0.0;

        debugPrint('🦠 Disease: $diseaseName (${(diseaseProb * 100).toStringAsFixed(1)}%)');

        final details = topDisease['details'] as Map<String, dynamic>? ?? {};
        symptoms = _extractSymptoms(diseaseName, details, diseaseProb);
        treatments = _extractTreatments(details, diseaseName);
        precautions = _extractPrecautions(details);
      }
    }

    return {
      'hasDiseaseInfo': true,
      'diseaseName': diseaseName,
      'severity': _determineSeverity(diseaseProb),
      'diseaseProbability': diseaseProb,
      'symptoms': symptoms,
      'treatments': treatments,
      'precautions': precautions,
    };
  }

  String _determineSeverity(double probability) {
    if (probability > 0.8) return 'Severe';
    if (probability > 0.6) return 'High';
    if (probability > 0.4) return 'Medium';
    if (probability > 0.2) return 'Low';
    return 'Minimal';
  }

  List<String> _extractSymptoms(String diseaseName, Map<String, dynamic> details, double probability) {
    final symptoms = <String>[];

    // Try description-based extraction
    final description = details['description'];
    String? descValue;
    if (description is Map) descValue = description['value']?.toString();
    else if (description is String) descValue = description;

    if (descValue != null && descValue.isNotEmpty) {
      final sentences = descValue.split('. ');
      for (var s in sentences.take(3)) {
        if (s.length > 15 && !s.contains('http')) {
          symptoms.add(s.trim().endsWith('.') ? s.trim() : '$s.');
        }
      }
    }

    // Fallback symptoms
    if (symptoms.isEmpty) {
      if (probability > 0.7) {
        symptoms.addAll(['Advanced stage of $diseaseName', 'Visible tissue damage', 'Immediate action required']);
      } else if (probability > 0.4) {
        symptoms.addAll(['Moderate signs of $diseaseName', 'Early to mid-stage symptoms', 'Treatment recommended']);
      } else {
        symptoms.addAll(['Early indicators of $diseaseName', 'Minimal damage visible', 'Preventive measures advised']);
      }
    }

    return symptoms;
  }

  List<String> _extractTreatments(Map<String, dynamic> details, String diseaseName) {
    final treatments = <String>[];
    final treatment = details['treatment'] as Map<String, dynamic>?;
    if (treatment == null) return _getGenericTreatments(diseaseName);

    void addFrom(String key, String prefix) {
      final list = treatment[key] as List<dynamic>?;
      if (list != null) {
        for (var item in list) {
          final value = item.toString();
          if (value.isNotEmpty && value.length > 10) treatments.add('$prefix: $value');
        }
      }
    }

    addFrom('biological', 'Biological');
    addFrom('chemical', 'Chemical');
    addFrom('prevention', 'Prevention');

    return treatments.isEmpty ? _getGenericTreatments(diseaseName) : treatments;
  }

  List<String> _extractPrecautions(Map<String, dynamic> details) {
    final treatment = details['treatment'] as Map<String, dynamic>?;
    final prevention = treatment?['prevention'] as List<dynamic>?;

    if (prevention != null && prevention.isNotEmpty) {
      return prevention.map((e) => e.toString()).where((s) => s.length > 15).toList();
    }

    return [
      'Monitor plant daily for symptom progression',
      'Maintain proper spacing between plants',
      'Use sterilized tools when pruning',
      'Avoid working with plants when wet',
      'Ensure proper drainage and air flow',
    ];
  }

  List<String> _getGenericTreatments(String diseaseName) => [
    'Remove and dispose of affected plant parts',
    'Improve air circulation around the plant',
    'Reduce humidity and avoid overhead watering',
    'Apply appropriate fungicide for $diseaseName',
    'Isolate plant to prevent disease spread',
  ];
}