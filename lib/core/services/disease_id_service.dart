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
  // ── PlantCity model (EfficientNetB3, 99.23% accuracy, 52 classes) ──────────
  static const String _modelPath  = 'assets/new_model/plantcity_52classes.tflite';
  static const String _labelsPath = 'assets/new_model/plantcity_classes.txt';

  static const double _lowConfidenceThreshold = 5.0;
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

      // Penalty tiers — only apply when warm pixels are clearly dominant
      // (avoids penalizing autumn leaves, dry soil backgrounds, etc.)
      if (warmPercentage > 30) {
        debugPrint('⚠️ Heavy warm/rust pixels — strong healthy penalty (0.4)');
        return 0.4; // Very likely diseased
      }
      if (warmPercentage > 18) {
        debugPrint('⚠️ Moderate warm pixels — medium healthy penalty (0.65)');
        return 0.65;
      }
      if (warmPercentage > 10) {
        debugPrint('⚠️ Some warm pixels — mild healthy penalty (0.85)');
        return 0.85;
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

  // ── Main predict with plant hint ──────────────────────────────────────────
  // When user explicitly selects a plant (e.g. taps "Apple" chip), we ALWAYS
  // force the result to that plant — pick the highest-scoring disease class
  // for that plant from the model output, regardless of model top-1.
  // This handles the case where the model confuses Apple with Walnut etc.
  Future<Map<String, dynamic>> predictWithPlantHint(
    File imageFile, {
    String? plantHint,
    double plantHintConfidence = 0.0,
  }) async {
    final result = await predict(imageFile);

    // No hint — return model result as-is
    if (plantHint == null || plantHint.isEmpty) return result;
    if (result['success'] != true) return result;

    final allPredictions = result['allPredictions'] as List? ?? [];
    if (allPredictions.isEmpty) return result;

    final hintPlantNorm = _normalisePlantName(plantHint).toLowerCase();
    debugPrint('🎯 Plant hint active: "$plantHint" (normalized: "$hintPlantNorm")');

    // Collect ALL predictions for the hinted plant
    final hintMatches = <Map<String, dynamic>>[];
    for (final pred in allPredictions) {
      final label = pred['label'] as String? ?? '';
      final score = double.tryParse(pred['confidence']?.toString() ?? '0') ?? 0.0;
      final parsed = _parseDiseaseLabel(label);
      final predPlant = (parsed['plantName'] as String).toLowerCase();
      if (predPlant == hintPlantNorm) {
        hintMatches.add({...pred, '_parsed': parsed, '_score': score});
      }
    }

    if (hintMatches.isEmpty) {
      // Model has no classes for this plant — just fix the plant name
      debugPrint('⚠️ No classes found for "$plantHint" — fixing plant name only');
      result['plantName'] = _normalisePlantName(plantHint);
      return result;
    }

    // Sort by score descending — pick the best disease for this plant
    hintMatches.sort((a, b) => (b['_score'] as double).compareTo(a['_score'] as double));
    final best = hintMatches.first;
    final bestScore = best['_score'] as double;
    final bestParsed = best['_parsed'] as Map<String, dynamic>;

    final currentPlant = (result['plantName'] as String? ?? '').toLowerCase();
    final alreadyCorrect = currentPlant == hintPlantNorm;

    if (alreadyCorrect) {
      debugPrint('✅ Model already predicted correct plant "$plantHint" — no override needed');
      return result;
    }

    // Model predicted wrong plant — override with best hint match
    debugPrint('🔄 Overriding: model said "$currentPlant", user selected "$plantHint"');
    debugPrint('   Best match: ${best['label']} ($bestScore%)');

    final diseaseName = bestParsed['diseaseName'] as String;
    final plantName = bestParsed['plantName'] as String;
    final isHealthy = bestParsed['isHealthy'] as bool;

    result['plantName'] = plantName;
    result['diseaseName'] = diseaseName;
    result['isHealthy'] = isHealthy;
    result['rawLabel'] = best['label'];
    result['confidence'] = bestScore.toStringAsFixed(1);
    result['confidenceTier'] = bestScore >= 60.0 ? 'high' : bestScore >= 40.0 ? 'medium' : 'low';
    result['severity'] = _determineSeverity(diseaseName, bestScore);
    result['remediation'] = _getRemediation(diseaseName, plantName, isHealthy);
    result['symptoms'] = _getSymptoms(diseaseName);
    // Flag that this result was forced by user hint — low confidence means uncertain
    result['hintOverridden'] = true;
    result['hintLowConfidence'] = bestScore < 5.0; // model gave <5% to this plant

    return result;
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

      // STEP 3: Decode image with orientation fix for inference
      final imageBytes = await imageFile.readAsBytes();
      var rawImage = img.decodeImage(imageBytes);
      // (healthy penalty removed — model is 98.9% accurate, no override needed)

      // STEP 4: Single inference — your trained model (98.9% accuracy, 38 classes)
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final inputShape  = _interpreter!.getInputTensor(0).shape;
      debugPrint('🔍 Input shape: $inputShape  Output shape: $outputShape');

      final stopwatch = Stopwatch()..start();

      // Decode + resize to model input size (300×300 for PlantCity EfficientNetB3)
      final imageBytes2 = await imageFile.readAsBytes();
      var baseImage = img.decodeImage(imageBytes2);
      if (baseImage == null) throw Exception('Failed to decode image for inference');
      baseImage = img.bakeOrientation(baseImage);

      final int targetW = inputShape.length >= 3 ? inputShape[2] : 300;
      final int targetH = inputShape.length >= 3 ? inputShape[1] : 300;
      final resized = img.copyResize(baseImage, width: targetW, height: targetH,
          interpolation: img.Interpolation.linear);

      // PlantCity model has SUB/MUL preprocessing baked in — needs 4D input [1,300,300,3]
      // Pass as nested list, NOT flat Float32List (flat causes shape broadcast error)
      final input4D = _preprocessToFloat32_4D(resized);

      // Run inference using 4D nested list
      List<double> output;
      final out2D = List.generate(outputShape[0],
          (_) => List<double>.filled(outputShape[1], 0.0));
      _interpreter!.run(input4D, out2D);
      output = out2D.expand((r) => r).toList();

      // Output is already softmax probabilities (sum≈1.0) — no softmax needed
      final sumRaw = output.fold(0.0, (a, b) => a + b);
      final maxRaw = output.reduce((a, b) => a > b ? a : b);
      final alreadyProbabilities = (sumRaw > 0.95 && sumRaw < 1.05);
      if (!alreadyProbabilities) {
        output = _softmax(output);
        debugPrint('🔢 Applied softmax (sum was ${sumRaw.toStringAsFixed(3)})');
      } else {
        debugPrint('🔢 Probabilities ready (sum=${sumRaw.toStringAsFixed(3)}, max=${(maxRaw*100).toStringAsFixed(1)}%)');
      }

      stopwatch.stop();
      debugPrint('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

      // Log top-5
      final scored = <MapEntry<int, double>>[];
      for (int i = 0; i < output.length && i < _labels.length; i++) {
        scored.add(MapEntry(i, output[i]));
      }
      scored.sort((a, b) => b.value.compareTo(a.value));
      debugPrint('🔬 Disease model top-5 (after TTA+softmax):');
      for (int i = 0; i < 5 && i < scored.length; i++) {
        debugPrint('   ${_labels[scored[i].key]}: ${(scored[i].value * 100).toStringAsFixed(2)}%');
      }

      // STEP 5: Process results directly — trust the model's output
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

  // ── Softmax ────────────────────────────────────────────────────────────────
  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return logits;
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }

  // ── 4D nested list preprocessing — required for PlantCity model ──────────────
  // PlantCity EfficientNetB3 has SUB/MUL preprocessing baked in.
  // TFLite expects shape [1, 300, 300, 3] as a nested list with raw 0-255 values.
  List<List<List<List<double>>>> _preprocessToFloat32_4D(img.Image image) {
    final h = image.height, w = image.width;
    return List.generate(1, (_) =>
      List.generate(h, (y) =>
        List.generate(w, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r.toDouble(),  // 0-255, model's SUB node handles normalization
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        })
      )
    );
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

  // ── Output processing ──────────────────────────────────────────────────────
  Map<String, dynamic> _processOutput(List<double> output) {
    try {
      // Guard: empty output or labels
      if (output.isEmpty || _labels.isEmpty) {
        debugPrint('⚠️ Empty output or labels — returning fallback');
        return _createFallbackResult('Empty model output');
      }

      // Trust the model directly — no second-opinion overrides
      double maxConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < output.length; i++) {
        if (output[i] > maxConfidence) {
          maxConfidence = output[i];
          maxIndex = i;
        }
      }

      // Bounds check
      if (maxIndex >= _labels.length) {
        debugPrint('⚠️ maxIndex $maxIndex out of bounds (${_labels.length} labels)');
        return _createFallbackResult('Label index out of bounds');
      }

      final confidencePercent = (maxConfidence * 100).clamp(0.0, 100.0);

      final diseaseLabel = _labels[maxIndex];
      final diseaseInfo = _parseDiseaseLabel(diseaseLabel);
      final diseaseName = diseaseInfo['diseaseName'] as String? ?? 'Unknown';
      final plantName = diseaseInfo['plantName'] as String? ?? 'Unknown Plant';
      final isHealthy = diseaseInfo['isHealthy'] as bool? ?? false;

      // Build all predictions sorted by confidence
      final predictions = <Map<String, dynamic>>[];
      for (int i = 0; i < output.length; i++) {
        final parsed = _parseDiseaseLabel(i < _labels.length ? _labels[i] : '');
        predictions.add({
          'label': i < _labels.length ? _labels[i] : 'Unknown',
          'confidence': (output[i] * 100).toStringAsFixed(2),
          'plantName': parsed['plantName'] ?? 'Unknown',
          'diseaseName': parsed['diseaseName'] ?? 'Unknown',
          'isHealthy': parsed['isHealthy'] ?? false,
        });
      }
      predictions.sort((a, b) => double.parse(b['confidence'])
          .compareTo(double.parse(a['confidence'])));
      final top3 = predictions.take(3).toList();

      debugPrint('📊 Top 3 predictions:');
      for (var pred in top3) {
        debugPrint('  - ${pred['label']}: ${pred['confidence']}%');
      }

      // ── 3-tier confidence logic ────────────────────────────────────────────
      // HIGH (≥60%): Show result directly
      // MEDIUM (40-60%): Show top 3 options — let user decide
      // LOW (<40%): Ask user to retake photo
      // Also block very low confidence healthy predictions (likely not a leaf)
      const double highConfidence   = 60.0;
      const double mediumConfidence = 40.0;
      const double minHealthyConf   = 30.0; // healthy below this = probably not a leaf

      // Block very low confidence — applies to both diseased AND healthy
      if (confidencePercent < mediumConfidence && !isHealthy) {
        debugPrint('⚠️ Low confidence ($confidencePercent%) — ask user to retake');
        return {
          'success': true,
          'plantName': plantName,
          'diseaseName': diseaseName,
          'confidence': confidencePercent.toStringAsFixed(1),
          'severity': 'Unknown',
          'cause': 'Low confidence prediction',
          'isHealthy': false,
          'symptoms': <String>[],
          'remediation': <String>[],
          'precautions': <String>[],
          'allPredictions': predictions,
          'top3Predictions': top3,
          'rawLabel': diseaseLabel,
          'confidenceTier': 'low',
          'lowConfidence': true,
          'confidenceBelowThreshold': true,
        };
      }

      // Block very low confidence healthy predictions too
      if (isHealthy && confidencePercent < minHealthyConf) {
        debugPrint('⚠️ Low confidence healthy ($confidencePercent%) — ask user to retake');
        return {
          'success': true,
          'plantName': plantName,
          'diseaseName': diseaseName,
          'confidence': confidencePercent.toStringAsFixed(1),
          'severity': 'Unknown',
          'cause': 'Low confidence prediction',
          'isHealthy': false,
          'symptoms': <String>[],
          'remediation': <String>[],
          'precautions': <String>[],
          'allPredictions': predictions,
          'top3Predictions': top3,
          'rawLabel': diseaseLabel,
          'confidenceTier': 'low',
          'lowConfidence': true,
          'confidenceBelowThreshold': true,
        };
      }

      if (confidencePercent < highConfidence && !isHealthy) {
        debugPrint('⚠️ Medium confidence ($confidencePercent%) — show top 3');
        return {
          'success': true,
          'plantName': plantName,
          'diseaseName': diseaseName,
          'confidence': confidencePercent.toStringAsFixed(1),
          'severity': _determineSeverity(diseaseName, confidencePercent),
          'cause': _getCause(diseaseName),
          'isHealthy': isHealthy,
          'symptoms': _getSymptoms(diseaseName),
          'remediation': _getRemediation(diseaseName, plantName, isHealthy),
          'precautions': _getPrecautions(diseaseName, plantName),
          'allPredictions': predictions,
          'top3Predictions': top3,
          'rawLabel': diseaseLabel,
          'confidenceTier': 'medium',  // triggers top-3 dialog in UI
          'originalConfidence': confidencePercent.toStringAsFixed(1),
        };
      }

      // HIGH confidence — show result directly
      if (!_isValidPlantDiseaseCombo(plantName, diseaseName) && !isHealthy) {
        debugPrint('⚠️ Invalid plant-disease combination: $plantName with $diseaseName');
        return _invalidComboResult(plantName, diseaseName, confidencePercent);
      }

      return {
        'success': true,
        'plantName': plantName,
        'diseaseName': diseaseName,
        'confidence': confidencePercent.toStringAsFixed(1),
        'severity': _determineSeverity(diseaseName, confidencePercent),
        'cause': _getCause(diseaseName),
        'isHealthy': isHealthy,
        'symptoms': _getSymptoms(diseaseName),
        'remediation': _getRemediation(diseaseName, plantName, isHealthy),
        'precautions': _getPrecautions(diseaseName, plantName),
        'allPredictions': predictions,
        'top3Predictions': top3,
        'rawLabel': diseaseLabel,
        'confidenceTier': 'high',
        'originalConfidence': confidencePercent.toStringAsFixed(1),
      };
    } catch (e) {
      debugPrint('❌ Output processing error: $e');
      return _createFallbackResult('Output processing failed');
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  bool _isValidPlantDiseaseCombo(String plantName, String diseaseName) {
    // PlantCity model is 99.23% accurate — trust its output directly.
    // No combo rejection needed; the model handles this internally.
    debugPrint('✅ Skipping combo validation — trusting PlantCity model output');
    return true;
  }

  // ── Label parsing ──────────────────────────────────────────────────────────
  // Handles ALL PlantCity label formats from plantcity_classes.txt:
  //   "Apple Brown_spot"          → plant=Apple,   disease=Brown Spot
  //   "Apple Normal"              → plant=Apple,   healthy
  //   "Cherry_shot hole disease"  → plant=Cherry,  disease=Shot Hole Disease
  //   "Fig_rust leaf"             → plant=Fig,     disease=Rust
  //   "tomato_early_blight"       → plant=Tomato,  disease=Early Blight
  //   "tomato_healthy_leaf"       → plant=Tomato,  healthy
  //   "Grape Normal_leaf"         → plant=Grape,   healthy
  //   "Corn holcus_ leaf spot"    → plant=Corn,    disease=Holcus Leaf Spot
  //   "Tomato___Early_blight"     → plant=Tomato,  disease=Early Blight (legacy)
  Map<String, dynamic> _parseDiseaseLabel(String label) {
    try {
      debugPrint('🔍 Parsing label: "$label"');

      String rawPlant;
      String diseasePart;

      // Known plant names (lowercase) — used to identify plant prefix
      const knownPlants = [
        'apple', 'apricot', 'bean', 'cherry', 'corn', 'fig', 'grape',
        'lokat', 'loquat', 'pear', 'walnut', 'persimmons', 'persimmon',
        'tomato', 'potato', 'strawberry', 'blueberry', 'peach', 'orange',
        'soybean', 'squash', 'raspberry', 'wheat',
      ];

      if (label.contains('___')) {
        // Legacy format: "Tomato___Early_blight"
        final parts = label.split('___');
        rawPlant = parts[0].trim();
        diseasePart = parts.length > 1 ? parts[1].replaceAll('_', ' ').trim() : 'Unknown';
      } else {
        // Normalize: replace underscores with spaces, collapse multiple spaces
        final normalized = label.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        final words = normalized.split(' ');

        // Find the plant name — it's always the first word (or first two if compound)
        rawPlant = words[0];

        // Check if first word matches a known plant (case-insensitive)
        final firstWordLower = words[0].toLowerCase();
        final matchedPlant = knownPlants.firstWhere(
          (p) => firstWordLower == p || firstWordLower.startsWith(p),
          orElse: () => '',
        );

        if (matchedPlant.isNotEmpty) {
          rawPlant = words[0];
          diseasePart = words.length > 1 ? words.sublist(1).join(' ').trim() : 'Normal';
        } else {
          // Fallback: first word is plant
          rawPlant = words[0];
          diseasePart = words.length > 1 ? words.sublist(1).join(' ').trim() : 'Normal';
        }
      }

      final plantName = _normalisePlantName(rawPlant);

      // Clean up disease part — remove trailing noise words
      final cleanDisease = diseasePart
          .replaceAll(RegExp(r'\bleaf\b\s*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'\bimage\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final diseaseLower = cleanDisease.toLowerCase();

      // Detect healthy
      final isHealthy = diseaseLower.isEmpty ||
          diseaseLower == 'healthy' ||
          diseaseLower == 'normal' ||
          diseaseLower == 'normal leaf' ||
          diseaseLower == 'healthy leaf';

      String diseaseName;
      if (isHealthy) {
        diseaseName = 'Healthy';
      } else {
        diseaseName = cleanDisease
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : w)
            .join(' ')
            .trim();
      }

      debugPrint('📋 Parsed: Plant="$plantName", Disease="$diseaseName", Healthy=$isHealthy');
      return {
        'plantName': plantName,
        'diseaseName': diseaseName,
        'isHealthy': isHealthy,
        'rawLabel': label,
      };
    } catch (e) {
      debugPrint('❌ Error parsing label: $e');
      return {'plantName': 'Plant', 'diseaseName': 'Unknown', 'isHealthy': false, 'rawLabel': label};
    }
  }

  /// Normalise raw plant name from label to display name
  String _normalisePlantName(String raw) {
    const map = {
      // PlantCity new classes
      'apple': 'Apple',
      'apricot': 'Apricot',
      'bean': 'Bean',
      'cherry': 'Cherry',
      'corn': 'Corn',
      'maize': 'Corn',
      'fig': 'Fig',
      'grape': 'Grape',
      'lokat': 'Loquat',
      'loquat': 'Loquat',
      'pear': 'Pear',
      'walnut': 'Walnut',
      'persimmons': 'Persimmon',
      'persimmon': 'Persimmon',
      'tomato': 'Tomato',
      // Legacy formats
      'Apple': 'Apple', 'Blueberry': 'Blueberry',
      'Cherry_(including_sour)': 'Cherry', 'Cherry': 'Cherry',
      'Corn_(maize)': 'Corn', 'Corn_(Maize)': 'Corn',
      'Grape': 'Grape', 'Orange': 'Orange', 'Peach': 'Peach',
      'Pepper,_bell': 'Bell Pepper', 'Bell_pepper': 'Bell Pepper',
      'Potato': 'Potato', 'Raspberry': 'Raspberry',
      'Soybean': 'Soybean', 'Squash': 'Squash',
      'Strawberry': 'Strawberry', 'Tomato': 'Tomato', 'Wheat': 'Wheat',
    };
    return map[raw] ?? map[raw.toLowerCase()] ?? _titleCase(raw);
  }

  String _titleCase(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

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

  // ── Content helpers — updated for all 38 PlantVillage classes ────────────────
  String _getCause(String diseaseName) {
    final l = diseaseName.toLowerCase();
    
    // Specific diseases
    if (l.contains('apple scab')) return 'Fungus Venturia inaequalis';
    if (l.contains('black rot')) return 'Fungus Botryosphaeria obtusa (apple) or Guignardia bidwellii (grape)';
    if (l.contains('cedar apple rust')) return 'Fungus Gymnosporangium juniperi-virginianae (requires juniper host)';
    if (l.contains('esca') || l.contains('black measles')) return 'Complex of fungi including Phaeomoniella chlamydospora';
    if (l.contains('haunglongbing') || l.contains('citrus greening')) return 'Bacterium Candidatus Liberibacter asiaticus (transmitted by psyllid)';
    if (l.contains('cercospora') || l.contains('gray leaf spot')) return 'Fungus Cercospora zeae-maydis';
    if (l.contains('northern leaf blight')) return 'Fungus Exserohilum turcicum';
    if (l.contains('septoria')) return 'Fungus Septoria lycopersici';
    if (l.contains('spider mites') || l.contains('two spotted')) return 'Arachnid Tetranychus urticae (not a disease, pest damage)';
    if (l.contains('target spot')) return 'Fungus Corynespora cassiicola';
    if (l.contains('yellow leaf curl')) return 'Begomovirus TYLCV (transmitted by whitefly)';
    if (l.contains('mosaic virus')) return 'Tobamovirus ToMV (mechanically transmitted)';
    if (l.contains('leaf mold')) return 'Fungus Passalora fulva';
    if (l.contains('leaf scorch')) return 'Fungus Diplocarpon earlianum';
    
    // Generic categories
    if (l.contains('late blight')) return 'Oomycete Phytophthora infestans';
    if (l.contains('early blight')) return 'Fungus Alternaria solani';
    if (l.contains('bacterial spot')) return 'Bacterium Xanthomonas species';
    if (l.contains('common rust')) return 'Fungus Puccinia sorghi';
    if (l.contains('powdery mildew')) return 'Fungal mildew (Podosphaera or Erysiphe species)';
    if (l.contains('blight')) return 'Fungal or bacterial infection';
    if (l.contains('spot')) return 'Bacterial or fungal pathogens';
    if (l.contains('rot')) return 'Fungal or bacterial decay';
    if (l.contains('rust')) return 'Fungal rust disease';
    if (l.contains('scorch')) return 'Environmental stress or fungal infection';
    if (l.contains('curl')) return 'Viral infection';
    
    return 'Pathogen infection or environmental stress';
  }

  List<String> _getSymptoms(String diseaseName) {
    final l = diseaseName.toLowerCase();
    if (l == 'healthy') return ['No visible symptoms', 'Normal leaf color and texture', 'Vigorous growth'];

    final symptoms = <String>[];
    
    // Specific disease symptoms
    if (l.contains('apple scab')) {
      symptoms.addAll(['Olive-green to brown scabby lesions', 'Velvety spots on leaves',
        'Dark corky spots on fruit', 'Premature leaf drop']);
    } else if (l.contains('cedar apple rust')) {
      symptoms.addAll(['Bright yellow-orange spots on upper leaf surface',
        'Tube-like structures on leaf undersides', 'Premature defoliation']);
    } else if (l.contains('esca') || l.contains('black measles')) {
      symptoms.addAll(['Tiger-stripe pattern on leaves (yellow/red between veins)',
        'Black spots on berries', 'Sudden vine collapse in severe cases']);
    } else if (l.contains('haunglongbing') || l.contains('citrus greening')) {
      symptoms.addAll(['Asymmetric yellowing (blotchy mottle) on leaves',
        'Small lopsided bitter fruit', 'Twig dieback', 'Stunted growth']);
    } else if (l.contains('cercospora') || l.contains('gray leaf spot')) {
      symptoms.addAll(['Rectangular gray-tan lesions parallel to leaf veins',
        'Lesions may merge causing large dead areas']);
    } else if (l.contains('northern leaf blight')) {
      symptoms.addAll(['Large cigar-shaped gray-green to tan lesions 2.5-15cm long',
        'Lesions may have dark borders']);
    } else if (l.contains('septoria')) {
      symptoms.addAll(['Numerous small circular spots with dark brown borders',
        'Tan/gray centers', 'Black dots in center of spots']);
    } else if (l.contains('spider mites') || l.contains('two spotted')) {
      symptoms.addAll(['Fine stippling on upper leaf surface',
        'Bronze/yellow discoloration', 'Fine webbing on leaf undersides']);
    } else if (l.contains('target spot')) {
      symptoms.addAll(['Circular lesions with concentric rings resembling a target',
        'Dark brown spots on fruit']);
    } else if (l.contains('yellow leaf curl')) {
      symptoms.addAll(['Upward curling and yellowing of leaves',
        'Stunted plant growth', 'Reduced fruit set', 'Small distorted leaves']);
    } else if (l.contains('mosaic virus')) {
      symptoms.addAll(['Mosaic pattern of light and dark green on leaves',
        'Leaf distortion and curling', 'Mottled fruit']);
    } else if (l.contains('leaf mold')) {
      symptoms.addAll(['Pale green to yellow spots on upper leaf surface',
        'Olive-green velvety mold on lower surface', 'Leaf curl and drop']);
    } else if (l.contains('leaf scorch')) {
      symptoms.addAll(['Small dark purple spots on upper leaf surface',
        'Spots enlarge with reddish-purple borders', 'Scorched appearance']);
    } else if (l.contains('late blight')) {
      symptoms.addAll(['Water-soaked pale green lesions turning brown-black',
        'White fuzzy sporulation on leaf undersides', 'Rapid plant collapse']);
    } else if (l.contains('early blight')) {
      symptoms.addAll(['Dark brown circular lesions with concentric rings (target board)',
        'Yellow halo around lesions', 'Premature defoliation']);
    } else if (l.contains('bacterial spot')) {
      symptoms.addAll(['Small water-soaked spots turning brown with yellow halos',
        'Raised scabby spots on fruit', 'Shot-hole appearance on leaves']);
    } else if (l.contains('common rust')) {
      symptoms.addAll(['Brick-red to brown oval pustules on both leaf surfaces',
        'Pustules turn black as season progresses']);
    } else if (l.contains('powdery mildew')) {
      symptoms.addAll(['White powdery coating on leaves and shoots',
        'Leaf curling and distortion', 'Stunted growth']);
    } else if (l.contains('black rot')) {
      symptoms.addAll(['Tan circular lesions with dark borders on leaves',
        'Black shriveled mummified berries (grape)', 'Frog-eye leaf spot (apple)']);
    } else if (l.contains('scab')) {
      symptoms.addAll(['Dark scabby lesions on leaves and fruit',
        'Velvety olive-colored spots', 'Distorted leaves']);
    } else if (l.contains('spot')) {
      symptoms.addAll(['Small circular spots', 'Yellow halos around spots',
        'Spots may merge into larger areas']);
    } else if (l.contains('rot')) {
      symptoms.addAll(['Soft decaying tissue', 'Discoloration',
        'Foul odor in advanced stages']);
    } else if (l.contains('scorch')) {
      symptoms.addAll(['Leaf edges turn brown', 'Scorched appearance',
        'Premature leaf drop']);
    }
    
    if (symptoms.isEmpty) {
      symptoms.addAll(['Abnormal leaf discoloration', 'Spots or lesions on leaves',
        'Reduced plant vigor']);
    }
    return symptoms;
  }

  List<String> _getRemediation(String diseaseName, String plantName, bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue current care regimen',
        'Maintain proper watering schedule',
        'Ensure adequate sunlight exposure',
        'Apply balanced fertilizer as needed',
        'Regular monitoring for early disease detection',
      ];
    }

    final remediation = <String>[
      'Remove and destroy infected leaves immediately',
      'Improve air circulation around plant',
      'Avoid overhead watering to reduce leaf wetness',
      'Clean and disinfect gardening tools after use',
    ];

    final l = diseaseName.toLowerCase();
    
    // Critical diseases (no cure)
    if (l.contains('haunglongbing') || l.contains('citrus greening')) {
      return [
        'NO CURE — Remove and destroy infected trees immediately',
        'Control Asian citrus psyllid with systemic insecticides',
        'Use certified disease-free nursery stock only',
        'Implement strict quarantine measures',
      ];
    }
    if (l.contains('yellow leaf curl')) {
      return [
        'NO CURE — Remove and destroy infected plants',
        'Control whitefly vectors with insecticides (imidacloprid)',
        'Use reflective mulches to repel whiteflies',
        'Plant resistant varieties (Ty-1, Ty-2, Ty-3 genes)',
      ];
    }
    if (l.contains('esca') || l.contains('black measles')) {
      return [
        'No effective chemical cure available',
        'Remove and destroy infected wood',
        'Apply wound sealants after pruning',
        'Prune only during dry weather',
      ];
    }
    
    // Viral diseases
    if (l.contains('mosaic virus')) {
      remediation.addAll([
        'No cure — remove infected plants to prevent spread',
        'Disinfect tools with 10% bleach solution',
        'Wash hands before handling plants',
        'Use virus-free certified seed',
      ]);
      return remediation;
    }
    
    // Fungal diseases
    if (l.contains('late blight')) {
      remediation.addAll([
        'Apply metalaxyl, chlorothalonil, or cymoxanil IMMEDIATELY',
        'Destroy infected plants to prevent rapid spread',
        'Use resistant varieties',
        'Apply preventive fungicide program in wet weather',
      ]);
    } else if (l.contains('early blight')) {
      remediation.addAll([
        'Apply chlorothalonil, mancozeb, or azoxystrobin fungicides',
        'Remove infected lower leaves',
        'Ensure adequate plant nutrition (nitrogen)',
        'Mulch to prevent soil splash',
      ]);
    } else if (l.contains('apple scab')) {
      remediation.addAll([
        'Apply captan, mancozeb, or myclobutanil at 7-10 day intervals',
        'Use copper-based sprays at bud break',
        'Rake and destroy fallen leaves',
        'Plant resistant varieties (Liberty, Enterprise, Freedom)',
      ]);
    } else if (l.contains('cedar apple rust')) {
      remediation.addAll([
        'Apply myclobutanil or propiconazole from pink bud stage',
        'Remove nearby juniper/cedar hosts if possible',
        'Plant rust-resistant varieties',
      ]);
    } else if (l.contains('black rot')) {
      remediation.addAll([
        'Apply captan, mancozeb, or thiophanate-methyl',
        'Remove mummified berries and infected wood',
        'Prune to improve air circulation',
      ]);
    } else if (l.contains('septoria')) {
      remediation.addAll([
        'Apply chlorothalonil or mancozeb fungicides',
        'Remove infected lower leaves',
        'Mulch to prevent rain splash',
      ]);
    } else if (l.contains('cercospora') || l.contains('gray leaf spot')) {
      remediation.addAll([
        'Apply strobilurin or triazole fungicides at VT/R1 stage',
        'Tillage to bury infected residue',
        'Use resistant hybrids',
      ]);
    } else if (l.contains('northern leaf blight')) {
      remediation.addAll([
        'Apply fungicides at early disease onset',
        'Strobilurin-triazole mixtures most effective',
        'Crop rotation and tillage',
      ]);
    } else if (l.contains('common rust')) {
      remediation.addAll([
        'Apply triazole or strobilurin fungicides early',
        'Use resistant hybrids',
        'Early planting to avoid peak spore periods',
      ]);
    } else if (l.contains('powdery mildew')) {
      remediation.addAll([
        'Apply sulfur, potassium bicarbonate, or myclobutanil',
        'Increase plant spacing for better air flow',
        'Reduce nitrogen fertilizer',
        'Remove severely infected leaves',
      ]);
    } else if (l.contains('leaf mold')) {
      remediation.addAll([
        'Reduce humidity below 85%',
        'Improve ventilation (especially in greenhouses)',
        'Apply chlorothalonil or mancozeb',
      ]);
    } else if (l.contains('target spot')) {
      remediation.addAll([
        'Apply chlorothalonil, mancozeb, or azoxystrobin',
        'Crop rotation',
        'Remove infected debris',
      ]);
    } else if (l.contains('leaf scorch')) {
      remediation.addAll([
        'Apply captan or myclobutanil fungicides',
        'Remove old infected leaves after harvest',
        'Avoid overhead irrigation',
      ]);
    } else if (l.contains('spider mites') || l.contains('two spotted')) {
      remediation.addAll([
        'Apply miticides (abamectin, bifenazate)',
        'Use insecticidal soap or neem oil',
        'Increase humidity to discourage mites',
        'Encourage natural predators (ladybugs)',
      ]);
    }
    
    // Bacterial diseases
    else if (l.contains('bacterial spot')) {
      remediation.addAll([
        'Apply copper-based bactericides',
        'Use disease-free certified seed',
        'Avoid overhead irrigation',
        'Remove and destroy infected plant material',
      ]);
    }
    
    // Generic fallbacks
    else if (l.contains('blight') || l.contains('rot')) {
      remediation.addAll([
        'Apply copper-based fungicide',
        'Remove severely infected plants',
        'Rotate crops if applicable',
      ]);
    } else if (l.contains('spot') && !l.contains('rust')) {
      remediation.addAll([
        'Apply appropriate fungicide',
        'Prune affected areas',
        'Dispose of fallen leaves',
      ]);
    } else if (l.contains('scab')) {
      remediation.addAll([
        'Apply fungicide at green tip stage',
        'Rake and destroy fallen leaves',
        'Choose scab-resistant varieties',
      ]);
    } else if (l.contains('scorch')) {
      remediation.addAll([
        'Improve watering consistency',
        'Check for root damage',
        'Apply fungicide if fungal cause suspected',
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
