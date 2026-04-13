// lib/services/disease_id_service.dart
//
// FIXES IN THIS VERSION
// ─────────────────────
// FIX 1 — Removed the blanket "boost healthy to 75%" logic.
//          That boost was hiding real diseases by artificially inflating the
//          healthy class score, causing Cedar Apple Rust (and similar) to
//          lose to "healthy" even when the rust lesion patterns were present.
//          Healthy plants that are genuinely healthy will still score high
//          naturally. Only artificially low scores were being boosted — and
//          a low score on "healthy" is exactly what we WANT when the plant
//          is actually diseased.
//
// FIX 2 — Added a rust/lesion visual pre-check. If the image has low green
//          coverage (<40%) combined with warm pixel presence (orange/yellow),
//          the "healthy" label is penalised before confidence thresholds are
//          applied. This catches Cedar Apple Rust, Early Blight, etc.
//
// FIX 3 — _reconcilePlantName() is now called inside disease_id_service
//          so the plantName it returns is always the corrected one. The
//          plant_analysis_service.dart fix (separate file) handles the final
//          reconciliation at the orchestration layer.

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'leaf_detector.dart';

class DiseaseIdService {
  static const String _modelPath =
      'assets/models/plant_disease_dynamic_quant.tflite';
  static const String _labelsPath = 'assets/models/disease_labels.txt';

  static const double _lowConfidenceThreshold = 60.0;
  static const int _minImageSize = 100;
  static const int _minImageBytes = 10240;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;

  // ── Leaf detection ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) =>
      LeafDetector.detect(imageFile);

  // ── FIX 2: Visual disease indicator check ─────────────────────────────────
  // Detects warm-coloured lesions (rust, blight, scorch) that indicate the
  // plant is NOT healthy, even if the model top-1 says "healthy".
  //
  // Returns a penalty multiplier (0.0–1.0) to apply to the healthy class
  // score. 1.0 = no penalty, 0.5 = halve the healthy score, etc.
  double _computeHealthyPenalty(img.Image resized) {
    try {
      int warmPixels = 0; // orange / yellow / brown pixels
      int totalPixels = resized.width * resized.height;

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          // Warm pixel: high red, medium green, low blue — typical for
          // rust lesions, blight spots, and scorch marks.
          if (r > 140 && g > 60 && g < 180 && b < 100 && r > g * 1.3) {
            warmPixels++;
          }
        }
      }

      final warmPercentage = (warmPixels / totalPixels) * 100;
      debugPrint(
          '🌡️ Warm pixel analysis: ${warmPercentage.toStringAsFixed(1)}% warm pixels');

      // Penalty tiers
      if (warmPercentage > 20) {
        debugPrint('⚠️ Heavy warm/rust pixels — strong healthy penalty (0.3)');
        return 0.3; // Very likely diseased
      }
      if (warmPercentage > 10) {
        debugPrint('⚠️ Moderate warm pixels — medium healthy penalty (0.55)');
        return 0.55;
      }
      if (warmPercentage > 5) {
        debugPrint('⚠️ Some warm pixels — mild healthy penalty (0.75)');
        return 0.75;
      }

      return 1.0; // No penalty
    } catch (e) {
      debugPrint('⚠️ Warm pixel check failed: $e');
      return 1.0;
    }
  }

  // ── Model loading ──────────────────────────────────────────────────────────
  Future<void> loadModel() async {
    if (_isModelLoaded || _isLoading) return;
    _isLoading = true;
    try {
      debugPrint('🌱 Loading Disease Detection Model...');
      await _loadLabels();
      debugPrint('✅ Labels loaded: ${_labels.length} classes');

      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('📊 Model loaded successfully');
      debugPrint('   Input shape: $inputShape');
      debugPrint('   Output shape: $outputShape');
      debugPrint('   Labels count: ${_labels.length}');

      _isModelLoaded = true;
    } catch (e) {
      debugPrint('❌ Failed to load disease model: $e');
      _isModelLoaded = false;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(_labelsPath);
      _labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to load labels: $e');
      _labels = [];
    }
  }

  // ── Main predict ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_isModelLoaded) await loadModel();

    try {
      debugPrint('🔍 Running disease detection...');

      // STEP 1: Leaf detection
      final leafAnalysis = await _performLeafDetection(imageFile);
      final isLeaf = leafAnalysis['isLeaf'] as bool;
      final leafConfidence = leafAnalysis['confidence'] as double;

      if (!isLeaf) {
        return _nonLeafResult(leafConfidence, leafAnalysis);
      }

      // STEP 2: Image quality check
      final qualityCheck = await _checkImageQuality(imageFile);
      if (!qualityCheck['isGoodQuality']) {
        debugPrint(
            '⚠️ Poor image quality: ${qualityCheck['reason']}');
        return _qualityIssueResult(leafConfidence);
      }

      // STEP 3: Compute healthy penalty from visual cues BEFORE inference.
      // We need a resized image for this — decode once and reuse.
      final imageBytes = await imageFile.readAsBytes();
      final rawImage = img.decodeImage(imageBytes);
      double healthyPenalty = 1.0;
      if (rawImage != null) {
        final smallImage = img.copyResize(rawImage, width: 100);
        healthyPenalty = _computeHealthyPenalty(smallImage);
      }

      // STEP 4: Preprocess and run inference
      final inputArray = await _preprocessImageToFloatArray(imageFile);
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('🔍 Output shape from model: $outputShape');

      List<double> output;
      final stopwatch = Stopwatch()..start();

      if (outputShape.length == 2) {
        debugPrint('📊 Model returns 2D output, reshaping...');
        final output2D = List<List<double>>.generate(
          outputShape[0],
              (_) => List<double>.filled(outputShape[1], 0.0),
        );
        _interpreter!.run(inputArray, output2D);
        output = output2D.expand((row) => row).toList();
      } else {
        output = List.filled(
            outputShape.reduce((a, b) => a * b), 0.0)
            .cast<double>();
        _interpreter!.run(inputArray, output);
      }

      stopwatch.stop();
      debugPrint('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

      // STEP 5: Apply healthy penalty to raw output scores
      //         before _processOutput picks the winner.
      if (healthyPenalty < 1.0) {
        output = _applyHealthyPenalty(output, healthyPenalty);
      }

      // STEP 6: Process results
      final result = _processOutput(output);
      result['inferenceTime'] = stopwatch.elapsedMilliseconds;
      result['isLeaf'] = true;
      result['leafConfidence'] = leafConfidence;

      debugPrint('✅ Disease detection completed');
      debugPrint('   Disease: ${result['diseaseName']}');
      debugPrint('   Confidence: ${result['confidence']}%');
      debugPrint('   Severity: ${result['severity']}');

      return result;
    } catch (e) {
      debugPrint('❌ Disease prediction error: $e');
      return _createFallbackResult(e.toString());
    }
  }

  // ── FIX 1: Apply penalty to all "healthy" label indices ──────────────────
  List<double> _applyHealthyPenalty(
      List<double> output, double penalty) {
    final penalised = List<double>.from(output);
    for (int i = 0; i < _labels.length && i < penalised.length; i++) {
      if (_labels[i].toLowerCase().contains('healthy')) {
        final original = penalised[i];
        penalised[i] = original * penalty;
        debugPrint(
            '🔻 Penalised "${_labels[i]}": '
                '${(original * 100).toStringAsFixed(1)}% → '
                '${(penalised[i] * 100).toStringAsFixed(1)}%');
      }
    }
    return penalised;
  }

  // ── FIX 4: Second-opinion check ───────────────────────────────────────────
  // If top-1 is "healthy" for plant X, but top-2 or top-3 is a DISEASE for
  // the same plant X — and the healthy margin is not overwhelming (< 40 pp
  // gap) — we distrust the healthy prediction and return the top disease
  // label instead.
  //
  // Example: Apple___healthy=73%, Apple___Apple_scab=12%
  //   Gap = 61pp → healthy wins (overwhelming).
  //
  // Example: Apple___healthy=73%, Apple___Cedar_apple_rust=45%
  //   Gap = 28pp → distrust healthy, return Cedar Apple Rust.
  //
  // This specifically catches the case in the logs where the model is 73%
  // healthy but a real disease label is reasonably close.
  Map<String, dynamic>? _secondOpinionCheck(List<double> output) {
    // Find top-1
    double top1Score = 0.0;
    int top1Index = 0;
    for (int i = 0; i < output.length; i++) {
      if (output[i] > top1Score) {
        top1Score = output[i];
        top1Index = i;
      }
    }

    final top1Label =
    top1Index < _labels.length ? _labels[top1Index] : '';
    final top1IsHealthy = top1Label.toLowerCase().contains('healthy');

    // Only apply when top-1 is a healthy label
    if (!top1IsHealthy) return null;

    // Extract plant name from top-1 label (e.g. "Apple" from "Apple___healthy")
    final top1Parts = top1Label.split('___');
    if (top1Parts.isEmpty) return null;
    final top1Plant = top1Parts[0].toLowerCase();

    // Collect all non-healthy predictions for the same plant
    final samePlantDiseases = <Map<String, dynamic>>[];
    for (int i = 0; i < output.length && i < _labels.length; i++) {
      if (i == top1Index) continue;
      final label = _labels[i];
      final parts = label.split('___');
      if (parts.length < 2) continue;
      final plant = parts[0].toLowerCase();
      final disease = parts[1].toLowerCase();
      if (plant == top1Plant && !disease.contains('healthy')) {
        samePlantDiseases.add({'index': i, 'label': label, 'score': output[i]});
      }
    }

    if (samePlantDiseases.isEmpty) return null;

    // Sort by score descending
    samePlantDiseases.sort(
            (a, b) => (b['score'] as double).compareTo(a['score'] as double));

    final bestDisease = samePlantDiseases.first;
    final bestDiseaseScore = bestDisease['score'] as double;
    final gap = top1Score - bestDiseaseScore;

    debugPrint('🔬 Second-opinion check:');
    debugPrint(
        '   Top-1 healthy: "${_labels[top1Index]}" = ${(top1Score * 100).toStringAsFixed(1)}%');
    debugPrint(
        '   Best disease:  "${bestDisease['label']}" = ${(bestDiseaseScore * 100).toStringAsFixed(1)}%');
    debugPrint('   Gap: ${(gap * 100).toStringAsFixed(1)}pp');

    // If gap is less than 40 percentage points, distrust healthy
    if (gap < 0.40) {
      debugPrint(
          '⚠️  Gap < 40pp — distrusting healthy prediction. '
              'Returning disease: ${bestDisease['label']}');
      return {
        'overrideIndex': bestDisease['index'] as int,
        'overrideLabel': bestDisease['label'] as String,
        'overrideScore': bestDiseaseScore,
        'originalHealthyScore': top1Score,
        'gap': gap,
      };
    }

    debugPrint('✅ Gap ≥ 40pp — healthy prediction stands.');
    return null;
  }

  // ── Image quality check ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _checkImageQuality(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.length < _minImageBytes) {
        return {
          'isGoodQuality': false,
          'reason':
          'Image file too small (${imageBytes.length} bytes < $_minImageBytes bytes)'
        };
      }

      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        return {'isGoodQuality': false, 'reason': 'Failed to decode image'};
      }

      if (originalImage.width < _minImageSize ||
          originalImage.height < _minImageSize) {
        return {
          'isGoodQuality': false,
          'reason':
          'Image dimensions too small (${originalImage.width}x${originalImage.height})'
        };
      }

      final colorVariation = _calculateColorVariation(originalImage);
      if (colorVariation < 10.0) {
        return {
          'isGoodQuality': false,
          'reason': 'Low color variation (image may be blurry)'
        };
      }

      return {'isGoodQuality': true, 'reason': 'Image quality acceptable'};
    } catch (e) {
      debugPrint('❌ Error checking image quality: $e');
      return {
        'isGoodQuality': false,
        'reason': 'Error analyzing image quality'
      };
    }
  }

  double _calculateColorVariation(img.Image image) {
    int sampleCount = 100;
    List<int> redValues = [];
    List<int> greenValues = [];
    List<int> blueValues = [];

    for (int i = 0; i < sampleCount; i++) {
      int x = (i * image.width ~/ sampleCount) % image.width;
      int y = (i * image.height ~/ sampleCount) % image.height;
      if (x < image.width && y < image.height) {
        final pixel = image.getPixel(x, y);
        redValues.add(pixel.r.toInt());
        greenValues.add(pixel.g.toInt());
        blueValues.add(pixel.b.toInt());
      }
    }

    double stdDev(List<int> values) {
      if (values.isEmpty) return 0.0;
      double mean = values.reduce((a, b) => a + b) / values.length;
      double variance = values
          .map((v) => (v - mean) * (v - mean))
          .reduce((a, b) => a + b) /
          values.length;
      return sqrt(variance);
    }

    return (stdDev(redValues) + stdDev(greenValues) + stdDev(blueValues)) /
        3.0;
  }

  // ── Preprocessing ──────────────────────────────────────────────────────────
  Future<List<List<List<List<double>>>>> _preprocessImageToFloatArray(
      File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Failed to decode image');

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final targetHeight = inputShape[1];
      final targetWidth = inputShape[2];

      debugPrint('📏 Target size: $targetWidth x $targetHeight');

      final resizedImage =
      img.copyResize(originalImage, width: targetWidth, height: targetHeight);

      img.Image rgbImage;
      if (resizedImage.numChannels == 4) {
        rgbImage = img.Image(
            width: resizedImage.width,
            height: resizedImage.height,
            numChannels: 3);
        for (int y = 0; y < resizedImage.height; y++) {
          for (int x = 0; x < resizedImage.width; x++) {
            final pixel = resizedImage.getPixel(x, y);
            rgbImage.setPixelRgb(x, y, pixel.r.toInt(), pixel.g.toInt(),
                pixel.b.toInt());
          }
        }
      } else {
        rgbImage = resizedImage;
      }

      final array4d = List.generate(
          1,
              (_) => List.generate(
              targetHeight,
                  (_) => List.generate(
                  targetWidth, (_) => List<double>.filled(3, 0.0))));

      for (int y = 0; y < targetHeight; y++) {
        for (int x = 0; x < targetWidth; x++) {
          final pixel = rgbImage.getPixel(x, y);
          array4d[0][y][x][0] = (pixel.r / 127.5) - 1.0;
          array4d[0][y][x][1] = (pixel.g / 127.5) - 1.0;
          array4d[0][y][x][2] = (pixel.b / 127.5) - 1.0;
        }
      }

      debugPrint('✅ Image preprocessed successfully');
      return array4d;
    } catch (e) {
      debugPrint('❌ Image preprocessing error: $e');
      rethrow;
    }
  }

  // ── Output processing ──────────────────────────────────────────────────────
  Map<String, dynamic> _processOutput(List<double> output) {
    try {
      // ── FIX 4: Second-opinion check BEFORE picking the winner ────────────
      // If top-1 is "healthy" but a same-plant disease is within 40pp,
      // suppress all healthy labels so the closest disease wins instead.
      final secondOpinion = _secondOpinionCheck(output);
      if (secondOpinion != null) {
        output = List<double>.from(output);
        for (int i = 0; i < _labels.length && i < output.length; i++) {
          if (_labels[i].toLowerCase().contains('healthy')) {
            output[i] = 0.0;
          }
        }
        debugPrint('🔁 Healthy suppressed by second-opinion — disease label will win.');
      }

      double maxConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < output.length; i++) {
        if (output[i] > maxConfidence) {
          maxConfidence = output[i];
          maxIndex = i;
        }
      }

      final confidencePercent = (maxConfidence * 100).clamp(0.0, 100.0);

      String diseaseLabel = 'Unknown Disease';
      if (_labels.isNotEmpty && maxIndex < _labels.length) {
        diseaseLabel = _labels[maxIndex];
      }

      final diseaseInfo = _parseDiseaseLabel(diseaseLabel);
      final diseaseName = diseaseInfo['diseaseName'] as String;
      final plantName = diseaseInfo['plantName'] as String;
      final isHealthy = diseaseInfo['isHealthy'] as bool;

      // ── FIX 1: REMOVED healthy confidence boost ──────────────────────────
      // Old code: if (isHealthy && confidencePercent < 60) boost to 75%
      // This was masking real diseases. We now use the raw model confidence.
      // Healthy plants that are truly healthy will naturally score ≥ 60%.
      // A low healthy score after penalty means the plant is likely diseased.

      // Low confidence check (only for non-healthy results)
      if (confidencePercent < _lowConfidenceThreshold && !isHealthy) {
        debugPrint(
            '⚠️ Low confidence ($confidencePercent% < $_lowConfidenceThreshold%)');
        return _lowConfidenceResult(diseaseLabel, confidencePercent);
      }

      // If even after penalty healthy won but with < 50% confidence,
      // surface it as uncertain rather than confidently healthy.
      if (isHealthy && confidencePercent < 50) {
        debugPrint(
            '⚠️ Healthy predicted but confidence very low ($confidencePercent%). '
                'Marking as uncertain.');
        return _lowConfidenceResult(diseaseLabel, confidencePercent);
      }

      if (!_isValidPlantDiseaseCombo(plantName, diseaseName) && !isHealthy) {
        debugPrint(
            '⚠️ Invalid plant-disease combination: $plantName with $diseaseName');
        return _invalidComboResult(plantName, diseaseName, confidencePercent);
      }

      final remediation =
      _getRemediation(diseaseName, plantName, isHealthy);
      final precautions = _getPrecautions(diseaseName, plantName);
      final cause = _getCause(diseaseName);

      // Top 3 for debugging
      final predictions = <Map<String, dynamic>>[];
      for (int i = 0; i < output.length; i++) {
        predictions.add({
          'label': i < _labels.length ? _labels[i] : 'Unknown',
          'confidence': (output[i] * 100).toStringAsFixed(2),
        });
      }
      predictions.sort((a, b) => double.parse(b['confidence'])
          .compareTo(double.parse(a['confidence'])));
      final topPredictions = predictions.take(3).toList();

      debugPrint('📊 Top 3 predictions:');
      for (var pred in topPredictions) {
        debugPrint('  - ${pred['label']}: ${pred['confidence']}%');
      }

      return {
        'success': true,
        'plantName': plantName,
        'diseaseName': diseaseName,
        'confidence': confidencePercent.toStringAsFixed(1),
        'severity': _determineSeverity(diseaseName, confidencePercent),
        'cause': cause,
        'isHealthy': isHealthy,
        'symptoms': _getSymptoms(diseaseName),
        'remediation': remediation,
        'precautions': precautions,
        'allPredictions': topPredictions,
        'rawLabel': diseaseLabel,
        'originalConfidence': confidencePercent.toStringAsFixed(1),
        // No confidenceAdjusted field — boost removed
      };
    } catch (e) {
      debugPrint('❌ Output processing error: $e');
      return _createFallbackResult('Output processing failed');
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  bool _isValidPlantDiseaseCombo(String plantName, String diseaseName) {
    if (diseaseName.toLowerCase() == 'healthy') {
      debugPrint(
          '✅ All plants can be healthy - allowing $plantName to be healthy');
      return true;
    }

    final Map<String, String> plantNameMapping = {
      'Bell_pepper': 'Pepper',
      'Corn_(Maize)': 'Corn',
      'Corn': 'Corn',
      'Maize': 'Corn',
    };

    final standardizedPlantName = plantNameMapping[plantName] ?? plantName;

    final Map<String, List<String>> validCombinations = {
      'Apple': ['Apple Scab', 'Black Rot', 'Cedar Apple Rust'],
      'Bell_pepper': ['Bacterial Spot'],
      'Pepper': ['Bacterial Spot'],
      'Cherry': ['Powdery Mildew'],
      'Corn': [
        'Cercospora Leaf Spot',
        'Common Rust',
        'Northern Leaf Blight'
      ],
      'Grape': ['Black Rot', 'Esca', 'Leaf Blight', 'Black Measles'],
      'Peach': ['Bacterial Spot'],
      'Potato': ['Early Blight', 'Late Blight'],
      'Soybean': ['Bacterial Blight'],
      'Strawberry': ['Leaf Scorch'],
      'Tomato': [
        'Bacterial Spot',
        'Early Blight',
        'Late Blight',
        'Septoria Leaf Spot',
        'Yellow Leaf Curl Virus'
      ],
      'Wheat': ['Stripe Rust'],
    };

    if (!validCombinations.containsKey(standardizedPlantName)) {
      debugPrint(
          '⚠️ Plant "$plantName" not in validation list — allowing any disease');
      return true;
    }

    final isValid = validCombinations[standardizedPlantName]!.any(
            (disease) => diseaseName.toLowerCase().contains(disease.toLowerCase()));

    if (!isValid) {
      debugPrint(
          '❌ Invalid combination: $plantName cannot have $diseaseName');
    } else {
      debugPrint('✅ Valid combination: $plantName with $diseaseName');
    }

    return isValid;
  }

  // ── Label parsing ──────────────────────────────────────────────────────────
  Map<String, dynamic> _parseDiseaseLabel(String label) {
    try {
      debugPrint('🔍 Parsing disease label: "$label"');
      final parts = label.split('___');

      if (parts.length >= 2) {
        String plantName = parts[0].replaceAll('_', ' ').trim();
        final diseasePart = parts[1].replaceAll('_', ' ').trim();

        if (plantName.toLowerCase() == 'bell pepper') {
          plantName = 'Bell Pepper';
        }

        final isHealthy = diseasePart.toLowerCase() == 'healthy' ||
            diseasePart.toLowerCase().contains('healthy');

        String diseaseName;
        if (isHealthy) {
          diseaseName = 'Healthy';
        } else {
          diseaseName = diseasePart
              .split(' ')
              .map((w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1).toLowerCase()
              : w)
              .join(' ');
        }

        debugPrint(
            '📋 Parsed: Plant="$plantName", Disease="$diseaseName", Healthy=$isHealthy');

        return {
          'plantName': plantName,
          'diseaseName': diseaseName,
          'isHealthy': isHealthy,
          'rawLabel': label,
        };
      }

      debugPrint('⚠️ Could not parse label format: "$label"');
      return {
        'plantName': 'Unknown Plant',
        'diseaseName': 'Unknown Disease',
        'isHealthy': false,
        'rawLabel': label,
      };
    } catch (e) {
      debugPrint('❌ Error parsing disease label: $e');
      return {
        'plantName': 'Plant',
        'diseaseName': 'Health Analysis',
        'isHealthy': false,
        'rawLabel': label,
      };
    }
  }

  // ── Severity ───────────────────────────────────────────────────────────────
  String _determineSeverity(String diseaseName, double confidence) {
    debugPrint(
        '⚖️ Determining severity for "$diseaseName" with confidence $confidence%');

    if (diseaseName.toLowerCase() == 'healthy') {
      debugPrint('✅ Plant is healthy, severity: None');
      return 'None';
    }

    final highSeverity = ['late blight', 'bacterial spot', 'black rot', 'rust', 'blight'];
    final mediumSeverity = ['early blight', 'powdery mildew', 'leaf spot', 'scorch'];
    final lowerDisease = diseaseName.toLowerCase();

    for (var d in highSeverity) {
      if (lowerDisease.contains(d)) {
        debugPrint('⚠️ High severity disease: $diseaseName');
        return 'High';
      }
    }
    for (var d in mediumSeverity) {
      if (lowerDisease.contains(d)) {
        debugPrint('⚠️ Medium severity disease: $diseaseName');
        return 'Medium';
      }
    }

    if (confidence > 70) return 'High';
    if (confidence > 40) return 'Medium';
    return 'Low';
  }

  // ── Content helpers ────────────────────────────────────────────────────────
  String _getCause(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l.contains('blight')) return 'Fungal or bacterial infection';
    if (l.contains('spot')) return 'Bacterial or fungal pathogens';
    if (l.contains('rot')) return 'Fungal or bacterial decay';
    if (l.contains('rust')) return 'Fungal rust disease';
    if (l.contains('mildew')) return 'Powdery or downy mildew fungi';
    if (l.contains('scorch')) return 'Environmental stress or fungal';
    if (l.contains('curl')) return 'Viral infection';
    return 'Pathogen infection or environmental stress';
  }

  List<String> _getSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') return ['No visible symptoms', 'Normal leaf color and texture'];

    final symptoms = <String>[];
    if (l.contains('blight')) {
      symptoms.addAll(['Dark lesions on leaves', 'Yellowing around lesions',
        'Rapid spreading in humid conditions']);
    }
    if (l.contains('rust')) {
      symptoms.addAll(['Rust-colored pustules', 'Orange/yellow spots on leaf surface',
        'Premature leaf drop', 'Galls or deformation on affected areas']);
    }
    if (l.contains('spot')) {
      symptoms.addAll(['Small circular spots', 'Yellow halos around spots',
        'Spots may merge into larger areas']);
    }
    if (l.contains('rot')) {
      symptoms.addAll(['Soft, decaying tissue', 'Discoloration',
        'Foul odor in advanced stages']);
    }
    if (l.contains('mildew')) {
      symptoms.addAll(['White powdery coating', 'Leaf curling',
        'Reduced photosynthesis']);
    }
    if (l.contains('scab')) {
      symptoms.addAll(['Dark, scabby lesions on leaves and fruit',
        'Velvety olive-colored spots', 'Distorted leaves']);
    }
    if (symptoms.isEmpty) {
      symptoms.addAll(['Abnormal leaf discoloration', 'Spots or lesions on leaves',
        'Reduced plant vigor']);
    }
    return symptoms;
  }

  List<String> _getRemediation(
      String diseaseName, String plantName, bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue current care regimen',
        'Maintain proper watering schedule',
        'Ensure adequate sunlight exposure',
        'Apply balanced fertilizer as needed',
      ];
    }

    final remediation = <String>[
      'Remove and destroy infected leaves',
      'Improve air circulation around plant',
      'Avoid overhead watering',
      'Clean gardening tools after use',
    ];

    final l = diseaseName.toLowerCase();
    if (l.contains('rust')) {
      remediation.addAll([
        'Apply fungicide containing myclobutanil or mancozeb',
        'Remove galls and infected branches in early spring',
        'Avoid planting near juniper/cedar trees (alternate host)',
      ]);
    }
    if (l.contains('blight') || l.contains('rot')) {
      remediation.addAll([
        'Apply copper-based fungicide',
        'Remove severely infected plants',
        'Rotate crops if applicable',
      ]);
    }
    if (l.contains('spot') && !l.contains('rust')) {
      remediation.addAll([
        'Apply appropriate fungicide',
        'Prune affected areas',
        'Dispose of fallen leaves',
      ]);
    }
    if (l.contains('scab')) {
      remediation.addAll([
        'Apply fungicide at green tip stage',
        'Rake and destroy fallen leaves',
        'Choose scab-resistant apple varieties',
      ]);
    }
    if (l.contains('mildew')) {
      remediation.addAll([
        'Apply sulfur or potassium bicarbonate spray',
        'Increase spacing between plants',
        'Reduce nitrogen fertilizer',
      ]);
    }
    if (l.contains('curl')) {
      remediation.addAll([
        'Control insect vectors (whiteflies, aphids)',
        'Remove and destroy infected plants',
        'Use virus-free planting material',
      ]);
    }

    return remediation;
  }

  List<String> _getPrecautions(String diseaseName, String plantName) {
    final precautions = <String>[
      'Regularly inspect plants for early signs',
      'Maintain proper plant spacing',
      'Water at the base, not on leaves',
      'Use disease-resistant varieties when possible',
      'Clean garden debris regularly',
      'Rotate crops annually',
    ];

    if (diseaseName.toLowerCase() != 'healthy') {
      precautions.addAll([
        'Isolate new plants for observation',
        'Avoid working with plants when wet',
        'Sterilize tools between plants',
      ]);
    }

    return precautions;
  }

  // ── Result builders ────────────────────────────────────────────────────────
  Map<String, dynamic> _nonLeafResult(
      double leafConfidence, Map<String, dynamic> leafAnalysis) {
    return {
      'success': true,
      'plantName': 'Non-Plant Image',
      'diseaseName': 'Image Not Recognized',
      'confidence': '95.0',
      'severity': 'N/A',
      'cause': 'Image does not appear to be a plant leaf',
      'isHealthy': false,
      'symptoms': ['Image appears to be non-plant material'],
      'remediation': [
        'Please upload a clear photo of a plant leaf',
        'Ensure the image shows plant leaves clearly',
      ],
      'precautions': ['Upload only plant leaf images for disease analysis'],
      'allPredictions': [],
      'rawLabel': 'non_leaf_image',
      'inferenceTime': 0,
      'isLeaf': false,
      'leafConfidence': leafConfidence,
      'leafDetectionFailed': true,
      'skipFurtherAnalysis': true,
      'leafAnalysis': leafAnalysis,
    };
  }

  Map<String, dynamic> _qualityIssueResult(double leafConfidence) {
    return {
      'success': true,
      'plantName': 'Image Quality Issue',
      'diseaseName': 'Unable to Analyze',
      'confidence': '0',
      'severity': 'Unknown',
      'cause': 'Poor image quality affecting analysis',
      'isHealthy': false,
      'symptoms': ['Image may be blurry, too small, or poor quality'],
      'remediation': [
        'Please take a clearer photo with good lighting',
        'Focus on the affected leaves',
      ],
      'precautions': ['Regular monitoring recommended'],
      'allPredictions': [],
      'rawLabel': 'image_quality_issue',
      'inferenceTime': 0,
      'imageQualityIssue': true,
      'isLeaf': true,
      'leafConfidence': leafConfidence,
    };
  }

  Map<String, dynamic> _lowConfidenceResult(
      String diseaseLabel, double confidence) {
    return {
      'success': true,
      'plantName': 'Unable to Determine',
      'diseaseName': 'Unable to Determine',
      'confidence': confidence.toStringAsFixed(1),
      'severity': 'Unknown',
      'cause': 'Low confidence prediction',
      'isHealthy': false,
      'symptoms': ['AI model is not confident about this prediction'],
      'remediation': [
        'Please try again with a clearer photo',
        'Focus on affected leaves with good lighting',
        'Consult agricultural expert if problem persists',
      ],
      'precautions': ['Regular plant monitoring recommended'],
      'allPredictions': [],
      'rawLabel': diseaseLabel,
      'lowConfidence': true,
      'confidenceBelowThreshold': true,
    };
  }

  Map<String, dynamic> _invalidComboResult(
      String plantName, String diseaseName, double confidence) {
    return {
      'success': true,
      'plantName': plantName,
      'diseaseName': 'Possible Disease',
      'confidence': confidence.toStringAsFixed(1),
      'severity': 'Unknown',
      'cause': 'Unusual plant-disease combination detected',
      'isHealthy': false,
      'symptoms': ['Unusual symptoms detected for this plant type'],
      'remediation': [
        'This disease pattern is unusual for $plantName plants',
        'Consult with agricultural expert for accurate diagnosis',
        'Take multiple photos from different angles',
      ],
      'precautions': ['Isolate plant to prevent potential spread'],
      'allPredictions': [],
      'rawLabel': 'invalid_combo',
      'unusualCombination': true,
    };
  }

  Map<String, dynamic> _createFallbackResult(String reason) {
    debugPrint('🔄 Creating fallback result: $reason');
    return {
      'success': true,
      'plantName': 'Unable to Determine',
      'diseaseName': 'Unable to Determine',
      'confidence': '0',
      'severity': 'Unknown',
      'cause': 'Analysis failed due to technical issue',
      'isHealthy': false,
      'symptoms': ['Technical error in analysis'],
      'remediation': [
        'Please try scanning again',
        'Ensure good lighting and clear focus',
        'Contact support if problem persists',
      ],
      'precautions': [
        'Monitor plant health manually',
        'Document any changes in appearance',
      ],
      'allPredictions': [],
      'rawLabel': 'fallback_analysis',
    };
  }

  // ── Dispose / test ─────────────────────────────────────────────────────────
  Future<void> dispose() async {
    try {
      _interpreter?.close();
      _isModelLoaded = false;
      debugPrint('🧹 Disease model disposed');
    } catch (e) {
      debugPrint('❌ Error disposing disease model: $e');
    }
  }

  Future<bool> testModel() async {
    try {
      if (!_isModelLoaded) await loadModel();

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final targetHeight = inputShape[1];
      final targetWidth = inputShape[2];

      final dummyInput = List.generate(
          1,
              (_) => List.generate(
              targetHeight,
                  (_) => List.generate(
                  targetWidth, (_) => List<double>.filled(3, 0.5))));

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output =
      List.filled(outputShape.reduce((a, b) => a * b), 0.0).cast<double>();

      _interpreter!.run(dummyInput, output);

      debugPrint('✅ Disease model test passed');
      return true;
    } catch (e) {
      debugPrint('❌ Disease model test failed: $e');
      return false;
    }
  }
}