class DiagnosisResult {
  final String disease;
  final String severity;
  final List<String> recommendations;
  final String plantName; // Add this field
  final String confidence; // Add this field

  DiagnosisResult({
    required this.disease,
    required this.severity,
    required this.recommendations,
    required this.plantName, // Include in constructor
    required this.confidence, // Include in constructor
  });
}