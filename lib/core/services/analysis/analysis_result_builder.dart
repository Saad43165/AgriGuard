import 'package:flutter/foundation.dart';
import 'analysis_helpers.dart';

class AnalysisResultBuilder {
  Map<String, dynamic> build({
    required Map<String, dynamic> leafAnalysis,
    required Map<String, dynamic> diseaseResult,
    required ExtractedInfo extracted,
    required Map<String, dynamic> severityData,
    required AnalysisStatus status,
  }) {
    final leafConfidence = leafAnalysis['confidence'] as double;
    final isHealthyPlant = extracted.isHealthyPlant;

    Map<String, dynamic> result = {
      'success': true,
      'analysisType': 'combined_species_disease_severity',
      'isLeaf': true,
      'leafConfidence': leafConfidence,

      // Plant info
      'species': extracted.finalPlantName,
      'plantName': extracted.finalPlantName,
      'speciesConfidence': extracted.diseaseConfidence / 100.0,
      'isUnknown': extracted.isUnknownPlant,
      'analysisStatus': status.status,
      'speciesMessage': status.displayMessage,

      // Disease info
      'disease': extracted.rawDiseaseName,
      'diseaseName': extracted.rawDiseaseName,
      'healthStatus': isHealthyPlant ? 'Healthy' : 'Diseased',
      'diseaseConfidence': extracted.diseaseConfidence,
      'confidence': extracted.diseaseConfidence,
      'isHealthy': isHealthyPlant,

      // Confidence tier
      'confidenceTier': status.confidenceTier,

      'hasDiseaseData': true,
      'shouldShowDisease': !extracted.isUnknownPlant,
      'displayTitle': extracted.isUnknownPlant ? 'Plant Not Identified' : 'Plant Analysis Complete',
      'primaryMessage': AnalysisHelpers.primaryMessage(
        extracted.isUnknownPlant,
        extracted.finalPlantName,
        extracted.diseaseConfidence / 100.0,
        diseaseResult,
        severityData['severity']?.toString() ?? 'Unknown',
      ),
      'secondaryMessage': AnalysisHelpers.secondaryMessage(
        extracted.isUnknownPlant,
        extracted.diseaseConfidence / 100.0,
        diseaseResult,
        severityData['severity']?.toString() ?? 'Unknown',
      ),

      // Debug data
      '_rawDisease': diseaseResult,
      '_leafAnalysis': leafAnalysis,
      'rawLabel': diseaseResult['rawLabel'],
      'shouldSaveToHistory': true,
    };

    // Add severity data
    result.addAll({
      'severity': severityData['severity'] ?? 'Unknown',
      'severityLevel': severityData['severityLevel'] ?? severityData['severity'] ?? 'Unknown',
      'severityConfidence': severityData['severityConfidence'] ?? severityData['confidence'] ?? 0.0,
      'remediation': severityData['remediation'] ?? AnalysisHelpers.defaultRemediation(isHealthyPlant),
      'severityEffect': severityData['effect'],
      'severityColorCode': severityData['colorCode'],
      'severityDescription': severityData['description'],
      'severityAction': severityData['action'],
      'hasSeverityData': severityData.containsKey('severityLevel'),
    });

    // Add analysis details if available
    if (severityData['analysisDetails'] != null) {
      result['analysisDetails'] = severityData['analysisDetails'];
    }

    if (diseaseResult['remediation'] != null) {
      final orig = AnalysisHelpers.parseRemediation(diseaseResult['remediation']);
      if (orig.isNotEmpty) result['originalRemediation'] = orig;
    }

    return result;
  }

  Map<String, dynamic> nonLeafResult(Map<String, dynamic> leafAnalysis, bool allChecks) {
    final leafConfidence = leafAnalysis['confidence'] as double;
    return {
      'success': true,
      'analysisType': 'non_leaf_image',
      'isLeaf': false,
      'leafConfidence': leafConfidence,
      'species': 'Non-Plant Image',
      'disease': 'Image Not Recognized',
      'speciesConfidence': 0.0,
      'diseaseConfidence': 95.0,
      'isUnknown': true,
      'analysisStatus': 'NON_LEAF',
      'speciesMessage': 'Image does not appear to be a plant leaf',
      'displayTitle': 'Non-Plant Image Detected',
      'primaryMessage': allChecks
          ? 'All detection systems confirm this is not a plant leaf.'
          : 'The uploaded image does not appear to be a plant leaf.',
      'secondaryMessage': 'Please upload a clear photo of a plant leaf.',
      'shouldShowDisease': false,
      'hasDiseaseData': false,
      'remediation': [
        'Upload a clear photo of a plant leaf',
        'Ensure the leaf fills most of the frame',
      ],
      'rawLabel': 'non_leaf_image',
      'shouldSaveToHistory': false,
    };
  }

  Map<String, dynamic> errorResult(String error) => {
    'success': false,
    'error': error,
    'species': 'Unknown Plant',
    'isUnknown': true,
    'analysisStatus': 'ERROR',
    'displayTitle': 'Analysis Failed',
    'primaryMessage': 'Unable to analyze plant image',
    'isLeaf': false,
    'severity': 'Unknown',
    'remediation': ['Please try again with a different image'],
  };
}