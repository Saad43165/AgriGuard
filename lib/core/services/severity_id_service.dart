import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class SeverityResult {
  final String severity;
  final String severityLevel;
  final double confidence;
  final String remediation;
  final String effect;
  final String colorCode;
  final String description;
  final String action;

  SeverityResult({
    required this.severity,
    required this.severityLevel,
    required this.confidence,
    required this.remediation,
    required this.effect,
    required this.colorCode,
    required this.description,
    required this.action,
  });

  Map<String, dynamic> toMap() => {
    'severity': severity,
    'severityLevel': severityLevel,
    'confidence': confidence,
    'remediation': remediation,
    'effect': effect,
    'colorCode': colorCode,
    'description': description,
    'action': action,
  };
}

class SeverityIdService {
  late Interpreter _interpreter;
  Map<String, dynamic> _remediationData = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _loadRemediationData();
      await _loadModel();
      _isInitialized = true;
      debugPrint('✅ SeverityIdService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing SeverityIdService: $e');
      rethrow;
    }
  }

  Future<void> _loadRemediationData() async {
    try {
      final s = await rootBundle.loadString('assets/data/remediation.json');
      _remediationData = json.decode(s);
      debugPrint('✅ Remediation data loaded');
    } catch (e) {
      debugPrint('❌ Error loading remediation data: $e');
      _remediationData = {'remediations': {}, 'general_guidelines': {}};
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/severity_dynamic_quant.tflite');
      debugPrint('✅ Model loaded successfully');
      debugPrint('📊 Input shape: ${_interpreter.getInputTensors()[0].shape}');
      debugPrint('📊 Output shape: ${_interpreter.getOutputTensors()[0].shape}');
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
      throw Exception('Failed to load severity model: $e');
    }
  }

  // ── Remediation helpers ────────────────────────────────────────────────────

  Map<String, dynamic> _getRemediationInfo(String diseaseKey, String severityLevel) {
    try {
      final remediations = (_remediationData['remediations'] as Map<String, dynamic>?) ?? {};
      if (!remediations.containsKey(diseaseKey)) {
        return _generalGuideline(severityLevel);
      }
      final diseaseData = remediations[diseaseKey] as Map<String, dynamic>? ?? {};
      if (!diseaseData.containsKey(severityLevel)) {
        final fallback = diseaseData['Medium'] ?? diseaseData['medium'];
        if (fallback is Map) return _extractRem(fallback);
        return _generalGuideline(severityLevel);
      }
      final sevRaw = diseaseData[severityLevel];
      return _extractRem(sevRaw is Map ? sevRaw : {});
    } catch (e) {
      debugPrint('❌ Error getting remediation info: $e');
      return {
        'remediation': 'Consult an agricultural expert.',
        'remediation_ur': 'زرعی ماہر سے مشورہ کریں۔',
        'effect': 'Expert consultation recommended.',
        'effect_ur': 'ماہر سے مشورہ تجویز کیا جاتا ہے۔',
      };
    }
  }

  Map<String, dynamic> _generalGuideline(String severityLevel) {
    final gg = (_remediationData['general_guidelines'] as Map<String, dynamic>?) ?? {};
    final key = 'severity_${severityLevel.toLowerCase()}';
    final text = gg[key]?.toString() ?? 'Apply appropriate treatment.';
    return {
      'remediation': text,
      'remediation_ur': text,
      'effect': 'General treatment for $severityLevel severity.',
      'effect_ur': '$severityLevel شدت کے لیے عمومی علاج۔',
    };
  }

  Map<String, dynamic> _extractRem(Map sevData) {
    String remEn, remUr, effEn, effUr;
    final remRaw = sevData['remediation'];
    final effRaw = sevData['effect'];
    if (remRaw is Map) {
      remEn = remRaw['en']?.toString() ?? 'Treatment not available.';
      remUr = remRaw['ur']?.toString() ?? remEn;
    } else {
      remEn = remRaw?.toString() ?? 'Treatment not available.';
      remUr = remEn;
    }
    if (effRaw is Map) {
      effEn = effRaw['en']?.toString() ?? 'Effect not available.';
      effUr = effRaw['ur']?.toString() ?? effEn;
    } else {
      effEn = effRaw?.toString() ?? 'Effect not available.';
      effUr = effEn;
    }
    return {'remediation': remEn, 'remediation_ur': remUr, 'effect': effEn, 'effect_ur': effUr};
  }

  // ── Disease-based severity (replaces unreliable TFLite severity model) ─────
  // The severity TFLite model always outputs Low regardless of disease.
  // This method derives severity from disease name — accurate for PlantCity 52 classes.
  Map<String, dynamic> _getDiseaseBasedSeverity(
      String diseaseName, String plantName, double confidence) {
    final d = diseaseName.toLowerCase();

    // Healthy
    if (d == 'healthy' || d.contains('healthy') || d == 'normal') {
      return {
        'severity': 'None',
        'severityLevel': 'None',
        'confidence': confidence,
        'remediation': ['Continue regular plant care', 'Monitor for any changes'],
        'remediation_ur': ['باقاعدہ پودوں کی دیکھ بھال جاری رکھیں', 'کسی بھی تبدیلی کے لیے نگرانی کریں'],
        'colorCode': '#4CAF50',
        'description': 'Plant is healthy',
        'action': 'Continue regular care',
        'effect': 'Plant is in good health.',
        'effect_ur': 'پودا اچھی صحت میں ہے۔',
      };
    }

    // Map disease → severity
    String severity;
    String colorCode;

    if (d.contains('late blight') || d.contains('fusarium wilt') ||
        d.contains('verticillium wilt') || d.contains('leaf curl') ||
        d.contains('fire blight') || d.contains('leaf scorch')) {
      severity = 'Critical'; colorCode = '#F44336';
    } else if (d.contains('early blight') || d.contains('bacterial spot') ||
        d.contains('anthracnose') || d.contains('downy mildew') ||
        d.contains('rust') || d.contains('blight') || d.contains('spider mites')) {
      severity = 'High'; colorCode = '#FF9800';
    } else if (d.contains('powdery mildew') || d.contains('brown spot') ||
        d.contains('black spot') || d.contains('leaf spot') ||
        d.contains('leaf mold') || d.contains('septoria') ||
        d.contains('blotch') || d.contains('shot hole') ||
        d.contains('leaf miner') || d.contains('mites')) {
      severity = 'Medium'; colorCode = '#FFC107';
    } else {
      severity = 'Low'; colorCode = '#8BC34A';
    }

    // Look up remediation from JSON
    final remediations = (_remediationData['remediations'] as Map<String, dynamic>?) ?? {};
    final pNorm = _normalizePlantName(plantName);
    final pClean = pNorm.replaceAll(' ', '_');
    final dClean = diseaseName.replaceAll(' ', '_').toLowerCase();
    String diseaseKey = '${pClean}_${pClean}_$dClean';

    if (!remediations.containsKey(diseaseKey)) {
      final lk = diseaseKey.toLowerCase();
      for (final k in remediations.keys) {
        if (k.toLowerCase() == lk) { diseaseKey = k; break; }
      }
    }
    if (!remediations.containsKey(diseaseKey)) {
      for (final k in remediations.keys) {
        if (k.toLowerCase().startsWith(pClean.toLowerCase()) &&
            k.toLowerCase().contains(dClean.split('_').first)) {
          diseaseKey = k; break;
        }
      }
    }

    final remInfo = _getRemediationInfo(diseaseKey, severity);
    final remStr = remInfo['remediation'] as String? ?? '';
    final remStrUr = remInfo['remediation_ur'] as String? ?? remStr;

    List<String> remList = remStr.isNotEmpty
        ? remStr.split(RegExp(r'\.\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : _getGeneralRemediations(severity);
    List<String> remListUr = remStrUr.isNotEmpty
        ? remStrUr.split(RegExp(r'\.\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : remList;

    debugPrint('✅ Disease-based severity: $diseaseName → $severity');

    return {
      'severity': severity,
      'severityLevel': severity,
      'confidence': confidence,
      'remediation': remList,
      'remediation_ur': remListUr,
      'effect': remInfo['effect'] ?? '',
      'effect_ur': remInfo['effect_ur'] ?? '',
      'colorCode': colorCode,
      'description': '$severity severity — $diseaseName',
      'action': (severity == 'Critical' || severity == 'High')
          ? 'Immediate treatment required'
          : 'Apply appropriate treatment',
    };
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getSeverityAndRemediation({
    required String diseaseName,
    required String plantName,
    required double confidence,
    String? imagePath,
    String? imageBase64,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      debugPrint('🎯 Getting severity and remediation for: $plantName - $diseaseName');

      if (diseaseName.isEmpty || diseaseName.toLowerCase() == 'healthy') {
        return {
          'severity': 'None',
          'remediation': ['Continue regular plant care', 'Monitor for any changes'],
          'remediation_ur': ['باقاعدہ پودوں کی دیکھ بھال جاری رکھیں', 'نگرانی کریں'],
        };
      }

      if (diseaseName == 'Image Not Recognized' || plantName == 'Non-Plant Image' ||
          diseaseName == 'Unable to Determine') {
        return {
          'severity': 'N/A',
          'remediation': ['Please upload a clear photo of a plant leaf'],
          'remediation_ur': ['براہ کرم پودے کے پتے کی واضح تصویر اپ لوڈ کریں'],
        };
      }

      // Use disease-name based severity — TFLite severity model outputs Low on everything
      return _getDiseaseBasedSeverity(diseaseName, plantName, confidence);

    } catch (e, st) {
      debugPrint('❌ Error in getSeverityAndRemediation: $e\n$st');
      return _getDiseaseBasedSeverity(diseaseName, plantName, confidence);
    }
  }

  // ── Legacy assessSeverity (kept for compatibility) ─────────────────────────
  Future<SeverityResult> assessSeverity(File imageFile, String diseaseKey) async {
    try {
      if (!_isInitialized) await initialize();
      final parts = diseaseKey.split('___');
      final plant = parts.isNotEmpty ? parts[0] : '';
      final disease = parts.length > 1 ? parts[1].replaceAll('_', ' ') : diseaseKey;
      final result = _getDiseaseBasedSeverity(disease, plant, 0.8);
      final remList = result['remediation'] as List<String>? ?? [];
      return SeverityResult(
        severity: result['severity'] as String,
        severityLevel: result['severityLevel'] as String,
        confidence: result['confidence'] as double,
        remediation: remList.isNotEmpty ? remList.first : 'Apply appropriate treatment.',
        effect: result['effect'] as String? ?? '',
        colorCode: result['colorCode'] as String,
        description: result['description'] as String? ?? '',
        action: result['action'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('❌ Error in assessSeverity: $e');
      return SeverityResult(
        severity: 'Medium', severityLevel: 'Medium', confidence: 0.5,
        remediation: 'Consult an agricultural expert.',
        effect: 'Expert consultation recommended.',
        colorCode: '#FFC107',
        description: 'Severity assessment could not be completed',
        action: 'Consult with plant disease expert',
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> _getGeneralRemediations(String severityLevel) {
    switch (severityLevel.toLowerCase()) {
      case 'critical':
        return ['Immediate treatment required', 'Remove severely infected parts',
            'Apply intensive care', 'Consult expert immediately'];
      case 'high':
        return ['Apply strong treatment', 'Isolate plant',
            'Remove infected leaves', 'Monitor daily'];
      case 'medium':
        return ['Apply standard treatment', 'Improve growing conditions',
            'Monitor regularly', 'Consider preventive measures'];
      case 'low':
        return ['Monitor plant health', 'Apply mild treatment',
            'Improve plant care', 'Watch for progression'];
      default:
        return ['Continue regular care', 'Maintain optimal conditions',
            'Monitor for changes', 'Apply preventive care'];
    }
  }

  String _normalizePlantName(String name) {
    const aliases = <String, String>{'corn': 'Maize', 'maize': 'Maize'};
    return aliases[name.toLowerCase()] ?? name;
  }

  String getGeneralGuideline(String severityLevel) {
    try {
      final gg = _remediationData['general_guidelines'] as Map<String, dynamic>;
      return gg['severity_${severityLevel.toLowerCase()}'] ?? 'No guideline available.';
    } catch (_) { return 'Error retrieving guidelines.'; }
  }

  Map<String, String> getImportantNotes() {
    try {
      return Map<String, String>.from(
          _remediationData['important_notes'] as Map<String, dynamic>);
    } catch (_) { return {'error': 'Could not load important notes'}; }
  }

  bool isReady() => _isInitialized;

  void dispose() {
    try {
      _interpreter.close();
      _isInitialized = false;
      debugPrint('✅ SeverityIdService disposed');
    } catch (e) { debugPrint('⚠️ Error disposing: $e'); }
  }
}

extension ReshapeList on List<double> {
  List<List<double>> reshape(List<int> shape) {
    if (shape.length != 2) throw ArgumentError('Only 2D reshaping supported');
    final rows = shape[0], cols = shape[1];
    if (length != rows * cols) throw ArgumentError('List length does not match shape');
    final result = List.generate(rows, (_) => List<double>.filled(cols, 0.0));
    for (var i = 0; i < rows; i++)
      for (var j = 0; j < cols; j++) {
        result[i][j] = this[i * cols + j];
      }
    return result;
  }
}
