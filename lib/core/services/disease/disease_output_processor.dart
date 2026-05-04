import 'dart:math';
import 'package:flutter/foundation.dart';
import 'disease_label_parser.dart';
import 'disease_content_provider.dart';

class DiseaseOutputProcessor {
  final DiseaseLabelParser _parser = DiseaseLabelParser();
  final DiseaseContentProvider _content = DiseaseContentProvider();

  static const double highConfidence = 60.0;
  static const double mediumConfidence = 30.0;

  Map<String, dynamic> process(List<double> output, List<String> labels, int inferenceTime) {
    try {
      if (output.isEmpty || labels.isEmpty) {
        return fallbackResult('Empty model output');
      }

      // Apply softmax if needed
      final sumRaw = output.fold(0.0, (a, b) => a + b);
      if (sumRaw < 0.95 || sumRaw > 1.05) {
        output = _softmax(output);
      }

      // Find max
      double maxConf = 0.0;
      int maxIdx = 0;
      for (int i = 0; i < output.length; i++) {
        if (output[i] > maxConf) { maxConf = output[i]; maxIdx = i; }
      }

      if (maxIdx >= labels.length) {
        return fallbackResult('Label index out of bounds');
      }

      final confidencePercent = (maxConf * 100).clamp(0.0, 100.0);
      final diseaseLabel = labels[maxIdx];
      final info = _parser.parse(diseaseLabel);

      final predictions = _buildPredictions(output, labels);
      final top3 = predictions.take(3).toList();

      // Determine confidence tier
      if (confidencePercent < mediumConfidence) {
        return _lowConfidenceResult(info, diseaseLabel, confidencePercent, predictions, top3);
      }

      if (confidencePercent < highConfidence && !(info['isHealthy'] as bool)) {
        return _mediumConfidenceResult(info, diseaseLabel, confidencePercent, predictions, top3);
      }

      return _highConfidenceResult(info, diseaseLabel, confidencePercent, predictions, top3, inferenceTime);
    } catch (e) {
      debugPrint('❌ Output processing error: $e');
      return fallbackResult('Output processing failed');
    }
  }

  Map<String, dynamic> applyPlantHint(Map<String, dynamic> result, String plantHint) {
    final allPredictions = result['allPredictions'] as List? ?? [];
    if (allPredictions.isEmpty) return result;

    final hintNorm = _parser.normalize(plantHint).toLowerCase();
    final matches = <Map<String, dynamic>>[];

    for (final pred in allPredictions) {
      final parsed = _parser.parse(pred['label'] ?? '');
      if ((parsed['plantName'] as String).toLowerCase() == hintNorm) {
        matches.add({...pred, '_parsed': parsed, '_score': double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0});
      }
    }

    if (matches.isEmpty) {
      result['plantName'] = _parser.normalize(plantHint);
      return result;
    }

    matches.sort((a, b) => (b['_score'] as double).compareTo(a['_score'] as double));
    final best = matches.first;
    final parsed = best['_parsed'] as Map<String, dynamic>;

    result['plantName'] = parsed['plantName'];
    result['diseaseName'] = parsed['diseaseName'];
    result['isHealthy'] = parsed['isHealthy'];
    result['rawLabel'] = best['label'];
    result['confidence'] = (best['_score'] as double).toStringAsFixed(1);
    result['hintOverridden'] = true;

    return result;
  }

  List<Map<String, dynamic>> _buildPredictions(List<double> output, List<String> labels) {
    final predictions = <Map<String, dynamic>>[];
    for (int i = 0; i < output.length; i++) {
      final parsed = _parser.parse(i < labels.length ? labels[i] : '');
      predictions.add({
        'label': i < labels.length ? labels[i] : 'Unknown',
        'confidence': (output[i] * 100).toStringAsFixed(2),
        'plantName': parsed['plantName'] ?? 'Unknown',
        'diseaseName': parsed['diseaseName'] ?? 'Unknown',
        'isHealthy': parsed['isHealthy'] ?? false,
      });
    }
    predictions.sort((a, b) => double.parse(b['confidence']).compareTo(double.parse(a['confidence'])));
    return predictions;
  }

  Map<String, dynamic> _highConfidenceResult(Map info, String label, double conf,
      List predictions, List top3, int inferenceTime) {
    final diseaseName = info['diseaseName'] as String;
    final plantName = info['plantName'] as String;
    final isHealthy = info['isHealthy'] as bool;

    return {
      'success': true,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'confidence': conf.toStringAsFixed(1),
      'severity': _content.determineSeverity(diseaseName, conf),
      'cause': _content.getCause(diseaseName),
      'isHealthy': isHealthy,
      'symptoms': _content.getSymptoms(diseaseName),
      'remediation': _content.getRemediation(diseaseName, plantName, isHealthy),
      'precautions': _content.getPrecautions(diseaseName, plantName),
      'allPredictions': predictions,
      'top3Predictions': top3,
      'rawLabel': label,
      'confidenceTier': 'high',
      'inferenceTime': inferenceTime,
    };
  }

  Map<String, dynamic> _mediumConfidenceResult(Map info, String label, double conf,
      List predictions, List top3) {
    final diseaseName = info['diseaseName'] as String;
    final plantName = info['plantName'] as String;
    final isHealthy = info['isHealthy'] as bool;

    return {
      'success': true,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'confidence': conf.toStringAsFixed(1),
      'severity': _content.determineSeverity(diseaseName, conf),
      'cause': _content.getCause(diseaseName),
      'isHealthy': isHealthy,
      'symptoms': _content.getSymptoms(diseaseName),
      'remediation': _content.getRemediation(diseaseName, plantName, isHealthy),
      'precautions': _content.getPrecautions(diseaseName, plantName),
      'allPredictions': predictions,
      'top3Predictions': top3,
      'rawLabel': label,
      'confidenceTier': 'medium',
    };
  }

  Map<String, dynamic> _lowConfidenceResult(Map info, String label, double conf,
      List predictions, List top3) {
    return {
      'success': true,
      'plantName': info['plantName'],
      'diseaseName': info['diseaseName'],
      'confidence': conf.toStringAsFixed(1),
      'severity': 'Unknown',
      'cause': 'Low confidence prediction',
      'isHealthy': false,
      'symptoms': <String>[],
      'remediation': <String>[],
      'precautions': <String>[],
      'allPredictions': predictions,
      'top3Predictions': top3,
      'rawLabel': label,
      'confidenceTier': 'low',
      'lowConfidence': true,
    };
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return logits;
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }

  Map<String, dynamic> nonLeafResult(double confidence, Map analysis) => {
    'success': true,
    'plantName': 'Non-Plant Image',
    'diseaseName': 'Image Not Recognized',
    'confidence': '95.0',
    'severity': 'N/A',
    'cause': 'Image does not appear to be a plant leaf',
    'isHealthy': false,
    'symptoms': ['Image appears to be non-plant material'],
    'remediation': ['Please upload a clear photo of a plant leaf'],
    'allPredictions': [],
    'rawLabel': 'non_leaf_image',
    'inferenceTime': 0,
    'isLeaf': false,
    'leafConfidence': confidence,
    'skipFurtherAnalysis': true,
  };

  Map<String, dynamic> qualityIssueResult(double confidence) => {
    'success': true,
    'plantName': 'Image Quality Issue',
    'diseaseName': 'Unable to Analyze',
    'confidence': '0',
    'severity': 'Unknown',
    'isHealthy': false,
    'symptoms': ['Image may be blurry or poor quality'],
    'remediation': ['Please take a clearer photo with good lighting'],
    'allPredictions': [],
    'rawLabel': 'image_quality_issue',
    'inferenceTime': 0,
    'isLeaf': true,
    'leafConfidence': confidence,
  };

  Map<String, dynamic> fallbackResult(String reason) => {
    'success': true,
    'plantName': 'Unable to Determine',
    'diseaseName': 'Unable to Determine',
    'confidence': '0',
    'severity': 'Unknown',
    'cause': 'Analysis failed',
    'isHealthy': false,
    'symptoms': ['Technical error in analysis'],
    'remediation': ['Please try scanning again'],
    'allPredictions': [],
    'rawLabel': 'fallback_analysis',
  };
}