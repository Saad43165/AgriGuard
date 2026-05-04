/// Result model for severity analysis
class SeverityResult {
  final String severity;
  final String severityLevel;
  final double confidence;
  final String remediation;
  final String effect;
  final String colorCode;
  final String description;
  final String action;
  final Map<String, dynamic>? analysisDetails;

  SeverityResult({
    required this.severity,
    required this.severityLevel,
    required this.confidence,
    required this.remediation,
    required this.effect,
    required this.colorCode,
    required this.description,
    required this.action,
    this.analysisDetails,
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
    if (analysisDetails != null) 'analysisDetails': analysisDetails,
  };
}