// lib/features/ResultScreen/presentation/models/diagnosis_result.dart

class DiagnosisResult {
  final String disease;
  final String severity;
  final List<String> recommendations;
  final String plantName;
  final String confidence;
  final String? description;
  final String? scientificName;

  const DiagnosisResult({
    required this.disease,
    required this.severity,
    required this.recommendations,
    required this.plantName,
    required this.confidence,
    this.description,
    this.scientificName,
  });

  factory DiagnosisResult.fromScanData(Map<String, dynamic> scanData) {
    return DiagnosisResult(
      disease: scanData['diseaseName']?.toString() ??
          scanData['diagnosis']?.toString() ??
          'Healthy',
      severity: scanData['severity']?.toString() ?? 'Medium',
      recommendations: _parseRecommendations(scanData),
      plantName: scanData['plantName']?.toString() ?? 'Unknown Plant',
      confidence: scanData['confidence']?.toString() ?? '0',
      description: scanData['description']?.toString(),
      scientificName: scanData['scientificName']?.toString(),
    );
  }

  static List<String> _parseRecommendations(Map<String, dynamic> scanData) {
    final remediation = scanData['remediation'];
    if (remediation is List) {
      return List<String>.from(remediation);
    } else if (remediation is String) {
      return remediation
          .split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return _getFallbackRecommendations(
      scanData['diseaseName']?.toString().toLowerCase().contains('healthy') ?? false,
    );
  }

  static List<String> _getFallbackRecommendations(bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue regular plant care',
        'Maintain proper watering schedule',
        'Ensure adequate sunlight exposure',
        'Monitor for any changes in plant health'
      ];
    }
    return [
      'Apply appropriate fungicide if fungal disease is suspected',
      'Remove and destroy infected plant parts',
      'Improve air circulation around the plant',
      'Consult with agricultural expert for precise treatment'
    ];
  }

  // Add this getter
  bool get requiresUrgentAction {
    final lowerSeverity = severity.toLowerCase();
    return lowerSeverity == 'high' ||
        lowerSeverity == 'severe' ||
        lowerSeverity == 'critical';
  }

  bool get isHealthy => disease.toLowerCase() == 'healthy' ||
      disease.toLowerCase().contains('no disease');
}