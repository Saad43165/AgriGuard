import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Remediation & Disease Knowledge Base
///
/// Provides treatment recommendations based on disease name and severity level.
/// Uses a JSON database + hardcoded botanical knowledge.
class SeverityRemediationLookup {
  Map<String, dynamic> _remediationData = {};

  Future<void> load() async {
    try {
      final s = await rootBundle.loadString('assets/data/remediation.json');
      _remediationData = json.decode(s);
      debugPrint('✅ Remediation data loaded');
    } catch (e) {
      debugPrint('⚠️ Using default remediation data');
      _remediationData = {};
    }
  }

  /// Get disease knowledge base severity (reputation-based)
  String getKnowledgeBaseSeverity(String diseaseName) {
    final d = diseaseName.toLowerCase();

    // CRITICAL diseases — always serious
    if (d.contains('late blight') || d.contains('fusarium wilt') ||
        d.contains('verticillium wilt') || d.contains('leaf curl') ||
        d.contains('fire blight') || d.contains('leaf scorch')) {
      return 'Critical';
    }

    // HIGH severity diseases
    if (d.contains('early blight') || d.contains('bacterial spot') ||
        d.contains('anthracnose') || d.contains('downy mildew') ||
        d.contains('rust') || d.contains('blight') || d.contains('spider mites')) {
      return 'High';
    }

    // MEDIUM severity diseases
    if (d.contains('powdery mildew') || d.contains('brown spot') ||
        d.contains('black spot') || d.contains('leaf spot') ||
        d.contains('leaf mold') || d.contains('septoria') ||
        d.contains('blotch') || d.contains('shot hole') ||
        d.contains('leaf miner') || d.contains('mites')) {
      return 'Medium';
    }

    return 'Low';
  }

  /// Get remediation text for exact disease + severity combination
  Map<String, dynamic> getRemediation(String diseaseName, String plantName, String severityLevel) {
    // Try to find exact match in JSON
    final result = _lookupInJson(diseaseName, plantName, severityLevel);
    if (result != null) return result;

    // Fall back to disease-based guidelines
    return _getGeneralGuideline(severityLevel);
  }

  Map<String, dynamic>? _lookupInJson(String diseaseName, String plantName, String severityLevel) {
    final remediations = _remediationData['remediations'] as Map<String, dynamic>?;
    if (remediations == null) return null;

    final pClean = plantName.replaceAll(' ', '_');
    final dClean = diseaseName.replaceAll(' ', '_').toLowerCase();
    final key = '${pClean}_${pClean}_$dClean';

    final diseaseData = remediations[key] as Map<String, dynamic>?;
    if (diseaseData == null) return null;

    final sevData = diseaseData[severityLevel] as Map<String, dynamic>?;
    if (sevData == null) return null;

    return _extractRemediation(sevData);
  }

  Map<String, dynamic> _extractRemediation(Map sevData) {
    final remRaw = sevData['remediation'];
    final effRaw = sevData['effect'];

    String remEn = remRaw is Map ? remRaw['en']?.toString() ?? '' : remRaw?.toString() ?? '';
    String effEn = effRaw is Map ? effRaw['en']?.toString() ?? '' : effRaw?.toString() ?? '';

    return {
      'remediation': remEn,
      'effect': effEn,
    };
  }

  Map<String, dynamic> _getGeneralGuideline(String severityLevel) {
    final gg = _remediationData['general_guidelines'] as Map<String, dynamic>?;
    final text = gg?['severity_${severityLevel.toLowerCase()}'] as String?
        ?? _defaultGuideline(severityLevel);

    return {
      'remediation': text,
      'effect': 'General treatment for $severityLevel severity.',
    };
  }

  String _defaultGuideline(String level) {
    switch (level.toLowerCase()) {
      case 'critical': return 'Immediate treatment required. Remove infected parts. Apply intensive care. Consult expert.';
      case 'high': return 'Apply strong treatment. Isolate plant. Remove infected leaves. Monitor daily.';
      case 'medium': return 'Apply standard treatment. Improve growing conditions. Monitor regularly.';
      case 'low': return 'Monitor plant health. Apply mild treatment if needed. Improve plant care.';
      default: return 'Continue regular care. Maintain optimal conditions.';
    }
  }

  /// Get color code for severity level
  String getColorCode(String severityLevel) {
    switch (severityLevel.toLowerCase()) {
      case 'critical': return '#F44336';
      case 'high': return '#FF9800';
      case 'medium': return '#FFC107';
      case 'low': return '#8BC34A';
      case 'none': return '#4CAF50';
      default: return '#9E9E9E';
    }
  }

  /// Get specific symptoms for a disease
  List<String> getSymptomsForDisease(String diseaseName) {
    // Returns symptoms from JSON or defaults
    final diseaseData = _remediationData['disease_info'] as Map<String, dynamic>?;
    final info = diseaseData?[diseaseName.toLowerCase().replaceAll(' ', '_')];
    if (info is Map && info['symptoms'] is List) {
      return List<String>.from(info['symptoms']);
    }
    return ['Visible leaf damage', 'Abnormal discoloration', 'Reduced plant vigor'];
  }
}