class LeafAnalysisResult {
  final bool isLeaf;
  final double confidence;
  final List<String> reasons;
  final Map<String, dynamic>? details;

  const LeafAnalysisResult({
    required this.isLeaf,
    required this.confidence,
    required this.reasons,
    this.details,
  });

  factory LeafAnalysisResult.fromJson(Map<String, dynamic> json) {
    return LeafAnalysisResult(
      isLeaf: json['isLeaf'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLeaf': isLeaf,
      'confidence': confidence,
      'reasons': reasons,
      'details': details,
    };
  }
}