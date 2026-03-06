// lib/core/services/remediation_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

class RemediationService {
  Map<String, dynamic>? _remediations;

  Future<void> loadRemediations() async {
    final String response = await rootBundle.loadString('assets/data/remediations_bilingual.json');
    final data = json.decode(response);
    _remediations = data['remediations'];
  }

  // Get remediation text based on disease, severity, and language
  String getRemediation(String diseaseKey, String severity, String language) {
    if (_remediations == null) return '';

    try {
      final disease = _remediations![diseaseKey];
      if (disease == null) return '';

      final severityData = disease[severity];
      if (severityData == null) return '';

      return severityData['remediation'][language] ?? '';
    } catch (e) {
      return '';
    }
  }

  // Get effect text
  String getEffect(String diseaseKey, String severity, String language) {
    if (_remediations == null) return '';

    try {
      final disease = _remediations![diseaseKey];
      if (disease == null) return '';

      final severityData = disease[severity];
      if (severityData == null) return '';

      return severityData['effect'][language] ?? '';
    } catch (e) {
      return '';
    }
  }

  // Get plant name
  String getPlantName(String diseaseKey, String language) {
    if (_remediations == null) return '';

    try {
      return _remediations![diseaseKey]['plant'][language] ?? '';
    } catch (e) {
      return '';
    }
  }

  // Get disease name
  String getDiseaseName(String diseaseKey, String language) {
    if (_remediations == null) return '';

    try {
      return _remediations![diseaseKey]['disease'][language] ?? '';
    } catch (e) {
      return '';
    }
  }
}