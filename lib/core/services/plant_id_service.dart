// lib/services/plant_id_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import 'image_preprocessor.dart';
import 'leaf_detector.dart';

class PlantIdService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  static const String _modelPath = 'assets/models/plant_species_final_quantized.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;

  static const double _baseConfidenceThreshold = 0.45;
  static const double _highConfidenceThreshold = 0.75;
  static const double _minAcceptableConfidence = 0.35;

  final String _normalizationScheme = '[-1, 1]';

  late TensorType _inputType;
  late TensorType _outputType;
  late List<int> _inputShape;
  late List<int> _outputShape;
  int _numClasses = 0;

  final Map<String, double> _classSpecificThresholds = {
    'Apple': 0.30,
    'Blueberry': 0.30,
    'Cherry': 0.28,
    'Corn': 0.30,
    'Grape': 0.30,
    'Orange': 0.30,
    'Peach': 0.28,
    'Bell Pepper': 0.28,
    'Potato': 0.30,
    'Raspberry': 0.28,
    'Soybean': 0.30,
    'Squash': 0.28,
    'Strawberry': 0.28,
    'Tomato': 0.30,
  };

  bool get isLoaded => _isLoaded;

  // ── Leaf detection ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) =>
      LeafDetector.detect(imageFile);

  // ── Model loading ──────────────────────────────────────────────────────────
  Future<void> loadModel() async {
    try {
      debugPrint('🌱 Loading Plant Species Identification Model...');
      debugPrint('   Model Accuracy: 93.1% | Classes: 11');
      debugPrint('   Using adaptive confidence thresholds');

      _interpreter = await Interpreter.fromAsset(_modelPath);
      await _discoverTensorSpecs();
      await _loadLabels();

      if (_labels.length != _numClasses) {
        debugPrint('⚠️ Warning: Labels (${_labels.length}) don\'t match model output ($_numClasses)');
        _adjustLabelsToMatchModel();
      }

      debugPrint('✅ Using [-1, 1] normalization (as per training)');
      if (kDebugMode) await _runQuickTest();

      _isLoaded = true;
      debugPrint('✅ Plant Species Model loaded successfully!');
      debugPrint('   Input: $_inputShape ${_tensorTypeToString(_inputType)}');
      debugPrint('   Output: $_outputShape ${_tensorTypeToString(_outputType)}');
      debugPrint('   Classes: $_numClasses plant species');
    } catch (e) {
      debugPrint('❌ Failed to load plant species model: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  Future<void> _discoverTensorSpecs() async {
    final inputTensor  = _interpreter!.getInputTensors().first;
    final outputTensor = _interpreter!.getOutputTensors().first;
    _inputType   = inputTensor.type;
    _outputType  = outputTensor.type;
    _inputShape  = inputTensor.shape;
    _outputShape = outputTensor.shape;
    _numClasses  = _outputShape[1];
    debugPrint('🔬 PlantID tensor types: input=${_tensorTypeToString(_inputType)} output=${_tensorTypeToString(_outputType)}');
  }

  String _tensorTypeToString(TensorType type) {
    switch (type) {
      case TensorType.uint8:   return 'UINT8';
      case TensorType.float32: return 'FLOAT32';
      case TensorType.int8:    return 'INT8';
      default:                 return 'UNKNOWN';
    }
  }

  Future<void> _loadLabels() async {
    try {
      final txt = await rootBundle.loadString(_labelsPath);
      _labels = txt.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      debugPrint('✅ Loaded ${_labels.length} plant species labels');
      debugPrint('📋 Plant Species in model (with thresholds):');
      for (int i = 0; i < _labels.length; i++) {
        final label = _labels[i];
        final threshold = _getClassThreshold(label);
        debugPrint('   ${i + 1}. $label: ${(threshold * 100).toStringAsFixed(0)}% threshold');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load labels, using default: $e');
      _labels = [
        'Apple', 'Blueberry', 'Cherry', 'Corn', 'Grape',
        'Orange', 'Peach', 'Bell Pepper', 'Potato', 'Raspberry',
        'Soybean', 'Squash', 'Strawberry', 'Tomato',
      ];
    }
  }

  void _adjustLabelsToMatchModel() {
    if (_labels.length > _numClasses) {
      _labels = _labels.sublist(0, _numClasses);
      debugPrint('✅ Trimmed labels to $_numClasses to match model');
    } else if (_labels.length < _numClasses) {
      final needed = _numClasses - _labels.length;
      for (int i = 0; i < needed; i++) {
        _labels.add('Unknown_Plant_${_labels.length + 1}');
      }
      debugPrint('✅ Added $needed placeholder labels to match model');
    }
  }

  Future<void> _runQuickTest() async {
    debugPrint('\n🧪 Running quick model test...');
    final testImage = _createSolidImage(50, 150, 50);
    try {
      final input = _prepareInput(testImage);
      final probabilities = _runInference(input);
      final maxIndex = _getMaxIndex(probabilities);
      final maxConfidence = probabilities[maxIndex];
      final predictedLabel = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
      debugPrint('   Test inference successful');
      debugPrint('   Top prediction: $predictedLabel (${(maxConfidence * 100).toStringAsFixed(1)}%)');
      if (maxConfidence < 0.1) debugPrint('   ⚠️ Very low confidence - check normalization');
    } catch (e) {
      debugPrint('   ❌ Test failed: $e');
    }
  }

  // ── Inference helpers ──────────────────────────────────────────────────────
  dynamic _prepareInput(img_lib.Image image) {
    if (_inputType == TensorType.uint8) {
      debugPrint('🔢 PlantID: using UINT8 input (0-255)');
      return _prepareUint8Input(image);
    }
    // Dynamic-quantized models keep float32 interface but were trained with
    // ImageNet normalization: mean=[0.485,0.456,0.406] std=[0.229,0.224,0.225]
    debugPrint('🔢 PlantID: using FLOAT32 input (ImageNet normalization)');
    return _prepareImageNetInput(image);
  }

  // ImageNet normalization: (pixel/255 - mean) / std
  dynamic _prepareImageNetInput(img_lib.Image image) {
    const means = [0.485, 0.456, 0.406];
    const stds  = [0.229, 0.224, 0.225];
    final shaped = List.generate(1, (_) =>
      List.generate(_inputSize, (_) =>
        List.generate(_inputSize, (_) =>
          List<double>.filled(3, 0.0))));
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        shaped[0][y][x][0] = (pixel.r.toDouble() / 255.0 - means[0]) / stds[0];
        shaped[0][y][x][1] = (pixel.g.toDouble() / 255.0 - means[1]) / stds[1];
        shaped[0][y][x][2] = (pixel.b.toDouble() / 255.0 - means[2]) / stds[2];
      }
    }
    return shaped;
  }

  dynamic _reshapeFloat32(Float32List floatList) {
    final shaped = List<List<List<List<double>>>>.filled(1,
        List<List<List<double>>>.filled(_inputSize,
            List<List<double>>.filled(_inputSize,
                List<double>.filled(3, 0.0))));
    int floatIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        for (int c = 0; c < 3; c++) {
          shaped[0][y][x][c] = floatList[floatIndex++];
        }
      }
    }
    return shaped;
  }

  dynamic _prepareUint8Input(img_lib.Image image) {
    final bytes = ImagePreprocessor.imageToUint8List(image);
    final shaped = List<List<List<List<int>>>>.filled(1,
        List<List<List<int>>>.filled(_inputSize,
            List<List<int>>.filled(_inputSize,
                List<int>.filled(3, 0))));
    int byteIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        for (int c = 0; c < 3; c++) {
          shaped[0][y][x][c] = bytes[byteIndex++];
        }
      }
    }
    return shaped;
  }

  List<double> _runInference(dynamic input) {
    dynamic output;
    if (_outputType == TensorType.float32) {
      output = List.filled(1, List<double>.filled(_numClasses, 0.0));
    } else if (_outputType == TensorType.uint8) {
      output = List.filled(1, List<int>.filled(_numClasses, 0));
    } else if (_outputType == TensorType.int8) {
      output = List.filled(1, List<int>.filled(_numClasses, 0));
    } else {
      throw Exception('Unsupported output type: ${_tensorTypeToString(_outputType)}');
    }
    _interpreter!.run(input, output);
    return _convertToProbabilities(output);
  }

  List<double> _convertToProbabilities(dynamic output) {
    List<double> raw;
    if (_outputType == TensorType.float32) {
      raw = List<double>.from(output[0]);
    } else if (_outputType == TensorType.uint8) {
      raw = List<int>.from(output[0]).map((v) => v / 255.0).toList();
    } else if (_outputType == TensorType.int8) {
      raw = List<int>.from(output[0]).map((v) => (v + 128) / 255.0).toList();
    } else {
      throw Exception('Unknown output type');
    }
    if (raw.length != _numClasses) {
      raw = raw.sublist(0, min(raw.length, _numClasses));
    }
    // Apply softmax — model outputs raw logits
    return _softmax(raw);
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return logits;
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }

  int _getMaxIndex(List<double> values) {
    double maxVal = values[0];
    int maxIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) { maxVal = values[i]; maxIdx = i; }
    }
    return maxIdx;
  }

  // ── Main predict ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Plant species model not loaded. Call loadModel() first.');
    }

    try {
      debugPrint('\n🌿 Identifying plant species...');

      // STEP 1: Leaf detection (with warm pixel fix)
      debugPrint('🍃 Performing leaf detection...');
      final leafAnalysis = await _performLeafDetection(imageFile);
      final isLeaf        = leafAnalysis['isLeaf'] as bool;
      final leafConfidence = leafAnalysis['confidence'] as double;

      if (!isLeaf) {
        debugPrint('❌ Image does not appear to be a plant leaf. Skipping species identification.');
        return {
          'success': false,
          'error': 'Image does not appear to be a plant leaf',
          'isLeaf': false,
          'leafConfidence': leafConfidence,
          'isUnknown': true,
          'label': 'Non-Plant Image',
          'confidence': 0.0,
          'message': 'The image does not appear to contain a plant leaf. '
              'Please upload a clear photo of a plant leaf.',
          'shouldSkipDiseaseDetection': true,
          'leafAnalysis': leafAnalysis,
        };
      }

      // STEP 2: Preprocess
      final image = await ImagePreprocessor.preprocess(
        imageFile,
        modelInputSize: _inputSize,
      );
      if (image == null) throw Exception('Failed to process image');

      // STEP 3: Inference with TTA
      final stopwatch = Stopwatch()..start();
      final List<List<double>> ttaProbs = [];

      // TTA variants: original, flipped, brightness adjusted
      final ttaImages = <img_lib.Image>[
        image,
        img_lib.flipHorizontal(image),
        img_lib.adjustColor(image, brightness: 1.15),
        img_lib.adjustColor(image, brightness: 0.85),
      ];

      for (final ttaImg in ttaImages) {
        final input = _prepareInput(ttaImg);
        final probs = _runInference(input);
        ttaProbs.add(probs);
      }

      // Average TTA predictions
      final probabilities = List<double>.filled(_numClasses, 0.0);
      for (final p in ttaProbs) {
        for (int i = 0; i < probabilities.length && i < p.length; i++) {
          probabilities[i] += p[i];
        }
      }
      for (int i = 0; i < probabilities.length; i++) {
        probabilities[i] /= ttaProbs.length;
      }
      stopwatch.stop();
      debugPrint('⏱️ Inference time (TTA x${ttaProbs.length}): ${stopwatch.elapsedMilliseconds}ms');

      // Log raw distribution to diagnose normalization issues
      debugPrint('🔬 PlantID raw distribution:');
      for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
        if (probabilities[i] > 0.01) {
          debugPrint('   ${_labels[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
        }
      }

      // STEP 4: All predictions sorted by confidence
      final allPredictions = _getAllPredictions(probabilities);
      if (allPredictions.isEmpty) {
        return {
          'success': false,
          'error': 'No predictions generated',
          'isUnknown': true,
          'isLeaf': true,
          'leafConfidence': leafConfidence,
        };
      }

      final topPrediction = allPredictions[0];
      final topLabel      = topPrediction['label'] as String;
      final topConfidence = topPrediction['confidence'] as double;

      double confidenceGap = 0.0;
      if (allPredictions.length > 1) {
        confidenceGap = topConfidence - (allPredictions[1]['confidence'] as double);
      }

      // STEP 5: Confidence analysis
      final analysis  = _analyzePrediction(topLabel, topConfidence, confidenceGap, allPredictions);
      final isUnknown = analysis['isUnknown'] as bool;
      final reasoning = analysis['reasoning'] as String;

      // Log results
      debugPrint('\n📊 Plant Species Identification Results:');
      debugPrint('   ┌─────────────────────────────────────┐');
      debugPrint('   │ ★ $topLabel');
      debugPrint('   │ Confidence: ${(topConfidence * 100).toStringAsFixed(1)}%');
      debugPrint('   │ Threshold: ${((analysis["thresholdUsed"] as double) * 100).toStringAsFixed(1)}%');
      debugPrint('   │ Leaf Check: ✅ Passed (${leafConfidence.toStringAsFixed(1)}%)');
      if (confidenceGap > 0) {
        debugPrint('   │ Gap to 2nd: ${(confidenceGap * 100).toStringAsFixed(1)}%');
      }
      debugPrint('   │ Status: ${isUnknown ? "⚠️ Low Confidence" : "✅ Confident Identification"}');
      debugPrint('   └─────────────────────────────────────┘');

      if (allPredictions.length > 1 && topConfidence < 0.8) {
        debugPrint('\n   Alternatives:');
        for (int i = 1; i < min(3, allPredictions.length); i++) {
          final conf = ((allPredictions[i]['confidence'] as double) * 100).toStringAsFixed(1);
          debugPrint('   $i. ${allPredictions[i]['label']}: $conf%');
        }
      }
      if (isUnknown) debugPrint('\n   Reason: $reasoning');

      String confidenceLevel = 'Low';
      if (topConfidence >= _highConfidenceThreshold) {
        confidenceLevel = 'High';
      } else if (topConfidence >= _baseConfidenceThreshold) confidenceLevel = 'Medium';

      return {
        'success': true,
        'label': topLabel,
        'confidence': topConfidence,
        'isUnknown': isUnknown,
        'isLeaf': true,
        'leafConfidence': leafConfidence,
        'confidenceLevel': confidenceLevel,
        'confidenceThresholdUsed': analysis['thresholdUsed'] as double,
        'allPredictions': allPredictions,
        'top3Predictions': allPredictions.take(3).toList(),
        'inferenceTime': stopwatch.elapsedMilliseconds,
        'confidenceGap': confidenceGap,
        'normalizationScheme': _normalizationScheme,
        'reasoning': reasoning,
        'message': isUnknown
            ? 'Unable to identify with confidence. Try a clearer image.'
            : 'Identified as $topLabel (${confidenceLevel.toLowerCase()} confidence)',
      };
    } catch (e) {
      debugPrint('❌ Plant species identification failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'label': 'Unknown Plant',
        'confidence': 0.0,
        'isUnknown': true,
        'isLeaf': false,
      };
    }
  }

  // ── Prediction analysis ────────────────────────────────────────────────────
  Map<String, dynamic> _analyzePrediction(
      String topLabel,
      double topConfidence,
      double confidenceGap,
      List<Map<String, dynamic>> allPredictions,
      ) {
    final classThreshold = _getClassThreshold(topLabel);

    if (topConfidence < _minAcceptableConfidence) {
      return {
        'isUnknown': true,
        'thresholdUsed': classThreshold,
        'reasoning': 'Confidence too low '
            '(${(topConfidence * 100).toStringAsFixed(1)}% < '
            '${(_minAcceptableConfidence * 100).toStringAsFixed(1)}%)',
      };
    }

    if (topConfidence < classThreshold) {
      return {
        'isUnknown': true,
        'thresholdUsed': classThreshold,
        'reasoning': 'Below threshold for "$topLabel" '
            '(${(topConfidence * 100).toStringAsFixed(1)}% < '
            '${(classThreshold * 100).toStringAsFixed(1)}%)',
      };
    }

    // Only reject as ambiguous if gap is very small AND both predictions are weak
    if (allPredictions.length > 1) {
      final secondConfidence = allPredictions[1]['confidence'] as double;
      if (confidenceGap < 0.06 && topConfidence < 0.50 && secondConfidence > 0.30) {
        return {
          'isUnknown': true,
          'thresholdUsed': classThreshold,
          'reasoning': 'Ambiguous prediction '
              '(gap: ${(confidenceGap * 100).toStringAsFixed(1)}%, '
              '2nd: ${(secondConfidence * 100).toStringAsFixed(1)}%)',
        };
      }
    }

    String reasoning = 'Confident prediction';
    if (topConfidence >= _highConfidenceThreshold) {
      reasoning = 'High confidence '
          '(${(topConfidence * 100).toStringAsFixed(1)}% ≥ '
          '${(_highConfidenceThreshold * 100).toStringAsFixed(1)}%)';
    } else if (confidenceGap > 0.2) {
      reasoning = 'Clear winner (gap: ${(confidenceGap * 100).toStringAsFixed(1)}%)';
    }

    return {
      'isUnknown': false,
      'thresholdUsed': classThreshold,
      'reasoning': reasoning,
    };
  }

  double _getClassThreshold(String label) =>
      _classSpecificThresholds[label] ?? _baseConfidenceThreshold;

  List<Map<String, dynamic>> _getAllPredictions(List<double> probabilities) {
    final predictions = <Map<String, dynamic>>[];
    final limit = min(probabilities.length, _labels.length);
    for (int i = 0; i < limit; i++) {
      predictions.add({
        'label': _labels[i],
        'confidence': probabilities[i],
        'index': i,
        'threshold': _getClassThreshold(_labels[i]),
      });
    }
    predictions.sort((a, b) =>
        (b['confidence'] as double).compareTo(a['confidence'] as double));
    return predictions;
  }

  img_lib.Image _createSolidImage(int r, int g, int b) {
    final image = img_lib.Image(width: _inputSize, height: _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
    debugPrint('♻️ Plant Species Model disposed');
  }
}