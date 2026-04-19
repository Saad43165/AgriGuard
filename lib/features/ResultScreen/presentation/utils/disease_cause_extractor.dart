import 'package:flutter/foundation.dart';

class DiseaseCauseExtractor {
  final Map<String, dynamic> diseaseCauses;
  final Map<String, dynamic> diseaseMapping;
  final bool isLeafImage;
  final String? rawLabel;
  final String? diseaseName;
  final String? plantName;
  final double confidence;
  final double minimumConfidence;

  DiseaseCauseExtractor({
    required this.diseaseCauses,
    required this.diseaseMapping,
    required this.isLeafImage,
    this.rawLabel,
    this.diseaseName,
    this.plantName,
    required this.confidence,
    this.minimumConfidence = 30.0,
  });

  List<dynamic> extract() {
    try {
      if (!isLeafImage) return _getNonLeafCauses();
      if (_isFailedAnalysis()) return _getFailedAnalysisCauses();
      if (_isUnknownPlant()) return _getUnknownPlantCauses();
      if (_isHealthyPlant()) return _getHealthyPlantCauses();
      if (confidence < minimumConfidence) return _getLowConfidenceCauses();

      // The JSON has a "plant_disease_causes" wrapper — unwrap it
      final causesDb = diseaseCauses['plant_disease_causes'] as Map<String, dynamic>?
          ?? diseaseCauses;

      final diseaseKey = _findDiseaseKey(causesDb);
      if (diseaseKey != null && causesDb.containsKey(diseaseKey)) {
        final causes = _extractCausesFromKey(diseaseKey, causesDb);
        if (causes.isNotEmpty) return causes;
      }

      return _tryGeneralCauses();
    } catch (e) {
      debugPrint('❌ Error extracting causes: $e');
      return _getErrorCauses();
    }
  }

  List<dynamic> _getNonLeafCauses() {
    return [
      {
        'en': 'The uploaded image does not appear to be a plant leaf',
        'ur': 'اپ لوڈ کردہ تصویر پودے کا پتا نہیں لگتی'
      },
      {
        'en': 'Plant disease detection requires clear photos of plant leaves',
        'ur': 'پودوں کی بیماری کی تشخیص کے لیے پتوں کی واضح تصاویر درکار ہیں'
      },
      {
        'en': 'Our analysis detected non-plant characteristics',
        'ur': 'ہمارے تجزیے نے غیر پودوں کی خصوصیات کا پتہ لگایا'
      },
      {
        'en': 'Please upload a clear photo of a plant leaf',
        'ur': 'براہ کرم پودے کے پتے کی واضح تصویر اپ لوڈ کریں'
      }
    ];
  }

  List<dynamic> _getFailedAnalysisCauses() {
    return [
      {
        'en': 'Analysis could not be completed successfully',
        'ur': 'تجزیہ کامیابی سے مکمل نہیں ہو سکا'
      },
      {
        'en': 'This may be due to poor image quality or unclear symptoms',
        'ur': 'یہ خراب تصویر کے معیار یا غیر واضح علامات کی وجہ سے ہو سکتا ہے'
      },
      {
        'en': 'Please try again with a clearer photo',
        'ur': 'براہ کرم واضح تصویر کے ساتھ دوبارہ کوشش کریں'
      }
    ];
  }

  List<dynamic> _getUnknownPlantCauses() {
    return [
      {
        'en': 'Plant species could not be identified',
        'ur': 'پودے کی قسم کی شناخت نہیں ہو سکی'
      },
      {
        'en': 'Specific disease causes require plant identification',
        'ur': 'مخصوص بیماری کی وجوہات کے لیے پودے کی شناخت ضروری ہے'
      },
      {
        'en': 'For accurate diagnosis, please ensure:',
        'ur': 'درست تشخیص کے لیے، یقینی بنائیں:'
      },
      {
        'en': '• Clear photo of the whole plant',
        'ur': '• پورے پودے کی واضح تصویر'
      },
      {
        'en': '• Good lighting conditions',
        'ur': '• اچھی روشنی کے حالات'
      },
      {
        'en': '• Focus on affected leaves',
        'ur': '• متاثرہ پتوں پر توجہ مرکوز کریں'
      }
    ];
  }

  List<dynamic> _getHealthyPlantCauses() {
    return [
      {
        'en': 'Plant appears to be in good health',
        'ur': 'پودا صحت مند نظر آتا ہے'
      },
      {
        'en': 'No visible signs of disease or stress',
        'ur': 'بیماری یا تناؤ کی کوئی ظاہری علامات نہیں'
      },
      {
        'en': 'Maintaining current care practices is recommended',
        'ur': 'موجودہ دیکھ بھال کے طریقوں کو جاری رکھنے کی سفارش کی جاتی ہے'
      }
    ];
  }

  List<dynamic> _getLowConfidenceCauses() {
    return [
      {
        'en': 'Low confidence in disease identification',
        'ur': 'بیماری کی شناخت میں کم اعتماد'
      },
      {
        'en': 'Possible causes could include:',
        'ur': 'ممکنہ وجوہات میں شامل ہو سکتے ہیں:'
      },
      {
        'en': '• Environmental stress factors',
        'ur': '• ماحولیاتی تناؤ کے عوامل'
      },
      {
        'en': '• Mild pathogen infection',
        'ur': '• ہلکا پیتھوجن انفیکشن'
      },
      {
        'en': '• Natural leaf variations',
        'ur': '• پتوں کی قدرتی تبدیلیاں'
      },
      {
        'en': 'Consult an expert for accurate diagnosis',
        'ur': 'درست تشخیص کے لیے ماہر سے رجوع کریں'
      }
    ];
  }

  List<dynamic> _getErrorCauses() {
    return [
      {
        'en': 'Error loading disease information',
        'ur': 'بیماری کی معلومات لوڈ کرنے میں خرابی'
      },
      {
        'en': 'Please try again or consult an expert',
        'ur': 'براہ کرم دوبارہ کوشش کریں یا ماہر سے رجوع کریں'
      }
    ];
  }

  List<dynamic> _getFallbackCauses() {
    return [
      {
        'en': 'Specific causes for "${diseaseName ?? 'this disease'}" not available',
        'ur': '"${diseaseName ?? 'اس بیماری'}" کی مخصوص وجوہات دستیاب نہیں ہیں'
      },
      {
        'en': 'General disease prevention tips:',
        'ur': 'بیماری سے بچاؤ کے عمومی مشورے:'
      },
      {
        'en': '• Ensure proper plant spacing',
        'ur': '• پودوں کے درمیان مناسب فاصلہ رکھیں'
      },
      {
        'en': '• Water at soil level to avoid wet leaves',
        'ur': '• پتوں کو گیلا ہونے سے بچانے کے لیے مٹی کی سطح پر پانی دیں'
      },
      {
        'en': '• Remove infected plant material',
        'ur': '• متاثرہ پودوں کے حصوں کو ہٹا دیں'
      },
      {
        'en': '• Rotate crops annually',
        'ur': '• فصلوں کو سالانہ تبدیل کریں'
      }
    ];
  }

  bool _isFailedAnalysis() {
    return diseaseName == null ||
        diseaseName!.toLowerCase().contains('unable to determine') ||
        diseaseName!.toLowerCase().contains('image quality issue') ||
        diseaseName!.toLowerCase().contains('analysis required');
  }

  bool _isUnknownPlant() {
    return plantName == null ||
        plantName!.toLowerCase().contains('unknown') ||
        plantName!.toLowerCase().contains('unable to determine');
  }

  bool _isHealthyPlant() {
    return diseaseName?.toLowerCase() == 'healthy' ||
        diseaseName?.toLowerCase().contains('healthy') == true;
  }

  String? _findDiseaseKey(Map<String, dynamic> causesDb) {
    // Try rawLabel directly (new format: "Apple Brown_spot" → build key)
    if (rawLabel != null) {
      // Try direct key match
      if (causesDb.containsKey(rawLabel)) return rawLabel;

      // Build key from mapping.json — try rawLabel as mapping key
      if (diseaseMapping.containsKey(rawLabel)) {
        final entry = diseaseMapping[rawLabel];
        if (entry is Map) {
          final plant = entry['plant']?.toString() ?? '';
          final disease = entry['disease']?.toString() ?? '';
          // Build PlantCity key format: Plant_Plant_disease
          final plantClean = plant.replaceAll(' ', '_').replaceAll('(', '').replaceAll(')', '');
          final diseaseClean = disease.replaceAll(' ', '_').toLowerCase();
          final key = '${plantClean}_${plantClean}_$diseaseClean';
          if (causesDb.containsKey(key)) return key;
        }
      }
    }

    // Try constructed key from plantName + diseaseName
    if (plantName != null && diseaseName != null) {
      // Normalize plant name — handle Corn/Maize alias
      final pNorm = _normalizePlantName(plantName!);
      final pClean = pNorm.replaceAll(' ', '_');
      final dClean = diseaseName!.replaceAll(' ', '_').toLowerCase();

      // PlantCity format: Plant_Plant_disease
      final key1 = '${pClean}_${pClean}_$dClean';
      if (causesDb.containsKey(key1)) return key1;

      // Case-insensitive search
      final lowerKey = key1.toLowerCase();
      for (final k in causesDb.keys) {
        if (k.toLowerCase() == lowerKey) return k;
      }

      // Partial match — plant prefix + disease fragment
      final plantLower = pClean.toLowerCase();
      final diseaseLower = dClean.toLowerCase();
      for (final k in causesDb.keys) {
        final kl = k.toLowerCase();
        if (kl.startsWith(plantLower) && kl.contains(diseaseLower)) return k;
      }

      // Try just disease fragment
      for (final k in causesDb.keys) {
        if (k.toLowerCase().contains(diseaseLower) && diseaseLower.length > 4) return k;
      }
    }

    return null;
  }

  /// Normalize plant name to match JSON keys (e.g. Corn → Maize)
  String _normalizePlantName(String name) {
    const aliases = {
      'corn': 'Maize',
      'maize': 'Maize',
      'persimmon': 'Persimmon',
    };
    return aliases[name.toLowerCase()] ?? name;
  }

  String? _findKeyByDisplayName(String displayName, Map<String, dynamic> causesDb) {
    if (!displayName.contains(' - ')) return null;
    final parts = displayName.split(' - ');
    if (parts.length != 2) return null;
    final plant = parts[0].replaceAll(' ', '_');
    final disease = parts[1].replaceAll(' ', '_').toLowerCase();
    final key = '${plant}___$disease';
    if (causesDb.containsKey(key)) return key;
    if (disease == 'healthy') {
      final healthyKey = '${plant}___healthy';
      if (causesDb.containsKey(healthyKey)) return healthyKey;
    }
    return null;
  }

  List<dynamic> _extractCausesFromKey(String key, Map<String, dynamic> causesDb) {
    final diseaseData = causesDb[key];
    if (diseaseData is Map) {
      // Try 'causes' key first, then 'causes_ur' for bilingual
      final causes = diseaseData['causes'];
      final causesUr = diseaseData['causes_ur'];
      if (causes is List && causes.isNotEmpty) {
        // Return bilingual list if Urdu available
        if (causesUr is List && causesUr.length == causes.length) {
          return List.generate(causes.length, (i) => {
            'en': causes[i].toString(),
            'ur': causesUr[i].toString(),
          });
        }
        return List.from(causes);
      }
    }
    return [];
  }

  List<dynamic> _tryGeneralCauses() {
    // Try general causes from the JSON
    final causesDb = diseaseCauses['plant_disease_causes'] as Map<String, dynamic>?
        ?? diseaseCauses;
    final generalCauses = diseaseCauses['general_disease_causes'] as Map?
        ?? causesDb['general_disease_causes'] as Map?;

    if (diseaseName == null || generalCauses == null) {
      return _getFallbackCauses();
    }

    final lowerDisease = diseaseName!.toLowerCase();
    String? causeType;

    if (lowerDisease.contains('spot')) {
      causeType = 'bacterial_spot';
    } else if (lowerDisease.contains('blight')) causeType = 'blight';
    else if (lowerDisease.contains('rust')) causeType = 'rust_disease';
    else if (lowerDisease.contains('mildew')) causeType = 'powdery_mildew';
    else if (lowerDisease.contains('virus') || lowerDisease.contains('curl')) causeType = 'viral';
    else if (lowerDisease.contains('rot')) causeType = 'rot';
    else if (lowerDisease.contains('scorch') || lowerDisease.contains('scab')) causeType = 'fungal';

    if (causeType != null && generalCauses.containsKey(causeType)) {
      final causes = generalCauses[causeType]['general_causes'];
      if (causes is List && causes.isNotEmpty) return List.from(causes);
    }

    return _getFallbackCauses();
  }
}