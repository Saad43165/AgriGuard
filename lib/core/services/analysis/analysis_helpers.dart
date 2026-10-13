
class ExtractedInfo {
  final String finalPlantName;
  final String rawDiseaseName;
  final String guardedDiseaseName;
  final double diseaseConfidence;
  final double guardedDiseaseConfidence;
  final bool isHealthyPlant;
  final bool isUnknownPlant;
  final bool diseaseTooUncertain;

  ExtractedInfo({
    required this.finalPlantName,
    required this.rawDiseaseName,
    required this.guardedDiseaseName,
    required this.diseaseConfidence,
    required this.guardedDiseaseConfidence,
    required this.isHealthyPlant,
    required this.isUnknownPlant,
    required this.diseaseTooUncertain,
  });
}

class AnalysisStatus {
  final String status;
  final String displayMessage;
  final String confidenceTier;

  AnalysisStatus({
    required this.status,
    required this.displayMessage,
    required this.confidenceTier,
  });
}

class AnalysisHelpers {
  static const double minDiseaseConfidenceToClaim = 20.0;

  static ExtractedInfo extractPlantDiseaseInfo(Map<String, dynamic> diseaseResult) {
    final diseasePlantName = (diseaseResult['plantName'] ?? 'Unknown Plant').toString();
    final isHealthyPlant = diseaseResult['isHealthy'] as bool? ?? true;
    final rawDiseaseName = (diseaseResult['diseaseName'] ?? diseaseResult['diagnosis'] ?? 'Unknown Disease').toString();

    final diseaseConfidenceRaw = diseaseResult['confidence'] != null
        ? double.tryParse(diseaseResult['confidence'].toString()) ?? 0.0
        : 0.0;

    final isUnknownPlant = diseasePlantName.isEmpty || diseasePlantName == 'Unknown Plant';
    final finalPlantName = isUnknownPlant ? 'Unknown Plant' : diseasePlantName;

    final diseaseTooUncertain = !isHealthyPlant &&
        diseaseConfidenceRaw > 0 &&
        diseaseConfidenceRaw < minDiseaseConfidenceToClaim;

    return ExtractedInfo(
      finalPlantName: finalPlantName,
      rawDiseaseName: rawDiseaseName,
      guardedDiseaseName: diseaseTooUncertain ? 'Unable to Determine' : rawDiseaseName,
      diseaseConfidence: diseaseConfidenceRaw,
      guardedDiseaseConfidence: diseaseTooUncertain ? 0.0 : diseaseConfidenceRaw,
      isHealthyPlant: isHealthyPlant,
      isUnknownPlant: isUnknownPlant,
      diseaseTooUncertain: diseaseTooUncertain,
    );
  }

  static AnalysisStatus determineStatus(bool isUnknown, double confidence, String plantName) {
    if (isUnknown) {
      return AnalysisStatus(
        status: 'UNKNOWN_PLANT',
        displayMessage: 'Plant species could not be identified.',
        confidenceTier: 'low',
      );
    }

    if (confidence >= 70) {
      return AnalysisStatus(
        status: 'HIGH_CONFIDENCE',
        displayMessage: 'Plant identified as $plantName',
        confidenceTier: 'high',
      );
    }

    if (confidence >= 40) {
      return AnalysisStatus(
        status: 'MEDIUM_CONFIDENCE',
        displayMessage: 'Plant identified as $plantName',
        confidenceTier: 'medium',
      );
    }

    return AnalysisStatus(
      status: 'LOW_CONFIDENCE',
      displayMessage: 'Plant likely $plantName, but low confidence',
      confidenceTier: 'low',
    );
  }

  static Map<String, dynamic> staticSeverityResult(bool isHealthy, bool diseaseTooUncertain) {
    if (isHealthy) {
      return {
        'severity': 'None',
        'remediation': ['Continue regular plant care', 'Monitor for any changes'],
        'severityLevel': 'None',
        'severityConfidence': 1.0,
        'effect': 'No disease effect detected',
        'colorCode': '#4CAF50',
        'description': 'Plant appears to be in good health',
        'action': 'Continue regular care and monitoring',
      };
    }
    return {
      'severity': 'Unknown',
      'remediation': [
        'Take a clearer close-up photo',
        'Ensure good lighting and focus',
        'Try Advanced Scan for better accuracy',
      ],
      'severityLevel': 'Unknown',
      'severityConfidence': 0.0,
    };
  }

  static Map<String, dynamic> fallbackSeverity(String diseaseName, String plantName, double confidence) {
    String severity;
    List<String> remediation;

    if (confidence > 70) {
      severity = 'High';
      remediation = [
        'Apply appropriate fungicide/pesticide immediately',
        'Remove and destroy infected plant parts',
        'Consult agricultural expert',
      ];
    } else if (confidence > 40) {
      severity = 'Medium';
      remediation = [
        'Apply recommended treatment',
        'Improve plant growing conditions',
        'Monitor plant health daily',
      ];
    } else if (confidence > 20) {
      severity = 'Low';
      remediation = [
        'Monitor plant closely',
        'Apply preventive treatments',
        'Improve air circulation',
      ];
    } else {
      severity = 'None';
      remediation = [
        'Plant appears healthy',
        'Continue regular care',
        'Monitor for changes',
      ];
    }

    return {
      'severity': severity,
      'remediation': remediation,
      'severityLevel': severity,
      'severityConfidence': 0.5,
      'effect': 'Fallback analysis used',
      'colorCode': '#FFC107',
      'description': 'Severity estimated based on confidence',
      'action': 'Follow recommended remediation',
    };
  }

  static List<String> parseRemediation(dynamic remediation) {
    if (remediation == null) return [];
    if (remediation is List) return List<String>.from(remediation);
    if (remediation is String) {
      return remediation
          .split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<String> defaultRemediation(bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue regular plant care',
        'Maintain proper watering schedule',
        'Monitor for any changes',
      ];
    }
    return [
      'Apply appropriate treatment',
      'Remove infected plant parts',
      'Consult with agricultural expert',
    ];
  }

  static String primaryMessage(bool isUnknown, String species, double confidence,
      Map<String, dynamic>? disease, String severity) {
    if (isUnknown) return 'Plant species not recognized';
    final pct = (confidence * 100).toStringAsFixed(1);
    if (disease == null || (disease['isHealthy'] ?? true)) {
      return '$species identified with $pct% confidence';
    }
    final dn = disease['diseaseName'] ?? 'disease';
    return '$species with $dn (Severity: $severity)';
  }

  static String secondaryMessage(bool isUnknown, double confidence,
      Map<String, dynamic>? disease, String severity) {
    if (isUnknown) {
      if (confidence < 0.3) return 'Very low confidence — try a clearer image';
      if (confidence < 0.5) return 'Low confidence — image may be unclear';
      return 'Unable to identify plant species';
    }
    if (disease == null) return 'Disease detection skipped';
    if (disease['isHealthy'] ?? true) return 'No signs of disease detected';
    return 'Severity: $severity — Follow recommended treatment';
  }
}