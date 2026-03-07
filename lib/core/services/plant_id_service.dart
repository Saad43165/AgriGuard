// lib/services/plant_id_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import 'image_preprocessor.dart';

class PlantIdService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  static const String _modelPath = 'assets/models/plant_species_final_quantized.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;

  static const double _baseConfidenceThreshold = 0.60;
  static const double _highConfidenceThreshold = 0.80;
  static const double _minAcceptableConfidence = 0.50;

  final String _normalizationScheme = '[-1, 1]';

  late TensorType _inputType;
  late TensorType _outputType;
  late List<int> _inputShape;
  late List<int> _outputShape;
  int _numClasses = 0;

  final Map<String, double> _classSpecificThresholds = {
    'Soybean': 0.50,
    'Wheat': 0.50,
    'Cherry': 0.45,
    'Peach': 0.45,
    'Strawberry': 0.45,
    'Bell pepper': 0.48,
    'Potato': 0.50,
    'Apple': 0.50,
    'Grape': 0.50,
    'Corn (Maize)': 0.50,
    'Tomato': 0.50,
  };

  bool get isLoaded => _isLoaded;

  // ── Leaf detection ─────────────────────────────────────────────────────────
  // FIXED: Old rule (green > 25%) rejected diseased leaves (rust, scab,
  // blight, scorch) whose green drops to ~22% while warm orange/brown pixels
  // increase. New rule adds warm pixel counting so diseased leaves pass.
  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img_lib.decodeImage(bytes);
      if (image == null) {
        return {'isLeaf': true, 'confidence': 50.0, 'message': 'Failed to decode image'};
      }

      final resizedImage = img_lib.copyResize(image, width: 300);

      int greenPixels = 0;
      int warmPixels  = 0;   // orange / yellow / brown — diseased leaf colours
      int totalPixels = resizedImage.width * resizedImage.height;
      int edgeCount   = 0;
      const edgeThreshold = 25;

      for (int y = 0; y < resizedImage.height; y++) {
        for (int x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          // Green pixel (healthy leaf)
          if (g > r * 1.2 && g > b * 1.2 && g > 30) greenPixels++;

          // Warm pixel: rust / blight / scorch / scab colours
          // High red, some green, low blue
          if (r > 100 && g > 40 && b < 110 && r > b * 1.4) warmPixels++;

          // Edge check
          if (y < resizedImage.height - 1 && x < resizedImage.width - 1) {
            final current = (r + g + b) / 3;
            final rightPixel = resizedImage.getPixel(x + 1, y);
            final right = (rightPixel.r + rightPixel.g + rightPixel.b) / 3;
            final downPixel = resizedImage.getPixel(x, y + 1);
            final down = (downPixel.r + downPixel.g + downPixel.b) / 3;
            if ((current - right).abs() > edgeThreshold ||
                (current - down).abs() > edgeThreshold) {
              edgeCount++;
            }
          }
        }
      }

      final greenPct = (greenPixels / totalPixels) * 100;
      final warmPct  = (warmPixels  / totalPixels) * 100;
      final edgeDensity = (edgeCount / totalPixels) * 100;

      // Combined plant coverage: green + discounted warm pixels
      // Warm pixels are discounted (×0.5) to avoid false positives on
      // wooden tables, soil, etc. that are warm but not leaves.
      final plantPct = greenPct + (warmPct * 0.5);

      // OLD rule (broken): greenPct > 25 && edgeDensity > 5
      //   → Apple Scab image: green=22.3% → REJECTED ✗
      //
      // NEW rule: plant coverage > 15% with edges, OR strong edge alone
      //   → Apple Scab image: green=22.3% + warm≈50% → plantPct≈47% → PASS ✓
      final isLeaf = (plantPct > 15 && edgeDensity > 4) ||
          (edgeDensity > 8 && plantPct > 8);

      final confidence = (plantPct * 0.55) + (edgeDensity * 0.45);

      print('🍃 Plant ID Service Leaf Detection:');
      print('   Green: ${greenPct.toStringAsFixed(1)}%');
      print('   Warm:  ${warmPct.toStringAsFixed(1)}%');
      print('   Plant: ${plantPct.toStringAsFixed(1)}%');
      print('   Edge Density: ${edgeDensity.toStringAsFixed(1)}%');
      print('   Is Leaf: $isLeaf');
      print('   Confidence: ${confidence.toStringAsFixed(1)}%');

      return {
        'isLeaf': isLeaf,
        'confidence': confidence,
        'greenPercentage': greenPct,
        'warmPercentage': warmPct,
        'plantPercentage': plantPct,
        'edgeDensity': edgeDensity,
        'message': isLeaf
            ? 'Image appears to be a plant leaf'
            : 'Image does not appear to be a plant leaf',
      };
    } catch (e) {
      print('❌ Leaf detection error: $e');
      return {'isLeaf': true, 'confidence': 50.0, 'message': 'Detection error'};
    }
  }

  // ── Model loading ──────────────────────────────────────────────────────────
  Future<void> loadModel() async {
    try {
      print('🌱 Loading Plant Species Identification Model...');
      print('   Model Accuracy: 93.1% | Classes: 11');
      print('   Using adaptive confidence thresholds');

      _interpreter = await Interpreter.fromAsset(_modelPath);
      await _discoverTensorSpecs();
      await _loadLabels();

      if (_labels.length != _numClasses) {
        print('⚠️ Warning: Labels (${_labels.length}) don\'t match model output ($_numClasses)');
        _adjustLabelsToMatchModel();
      }

      print('✅ Using [-1, 1] normalization (as per training)');
      await _runQuickTest();

      _isLoaded = true;
      print('✅ Plant Species Model loaded successfully!');
      print('   Input: $_inputShape ${_tensorTypeToString(_inputType)}');
      print('   Output: $_outputShape ${_tensorTypeToString(_outputType)}');
      print('   Classes: $_numClasses plant species');
    } catch (e) {
      print('❌ Failed to load plant species model: $e');
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
      print('✅ Loaded ${_labels.length} plant species labels');
      print('📋 Plant Species in model (with thresholds):');
      for (int i = 0; i < _labels.length; i++) {
        final label = _labels[i];
        final threshold = _getClassThreshold(label);
        print('   ${i + 1}. $label: ${(threshold * 100).toStringAsFixed(0)}% threshold');
      }
    } catch (e) {
      print('⚠️ Failed to load labels, using default: $e');
      _labels = [
        'Apple', 'Bell pepper', 'Cherry', 'Corn (Maize)',
        'Grape', 'Peach', 'Potato', 'Soybean',
        'Strawberry', 'Tomato', 'Wheat',
      ];
    }
  }

  void _adjustLabelsToMatchModel() {
    if (_labels.length > _numClasses) {
      _labels = _labels.sublist(0, _numClasses);
      print('✅ Trimmed labels to $_numClasses to match model');
    } else if (_labels.length < _numClasses) {
      final needed = _numClasses - _labels.length;
      for (int i = 0; i < needed; i++) {
        _labels.add('Unknown_Plant_${_labels.length + 1}');
      }
      print('✅ Added $needed placeholder labels to match model');
    }
  }

  Future<void> _runQuickTest() async {
    print('\n🧪 Running quick model test...');
    final testImage = _createSolidImage(50, 150, 50);
    try {
      final input = _prepareInput(testImage);
      final probabilities = _runInference(input);
      final maxIndex = _getMaxIndex(probabilities);
      final maxConfidence = probabilities[maxIndex];
      final predictedLabel = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
      print('   Test inference successful');
      print('   Top prediction: $predictedLabel (${(maxConfidence * 100).toStringAsFixed(1)}%)');
      if (maxConfidence < 0.1) print('   ⚠️ Very low confidence - check normalization');
    } catch (e) {
      print('   ❌ Test failed: $e');
    }
  }

  // ── Inference helpers ──────────────────────────────────────────────────────
  dynamic _prepareInput(img_lib.Image image) {
    if (_inputType == TensorType.uint8) return _prepareUint8Input(image);

    final bytes = image.getBytes(order: img_lib.ChannelOrder.rgba);
    final floatList = Float32List(3 * _inputSize * _inputSize);
    int floatIndex = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      for (int c = 0; c < 3; c++) {
        floatList[floatIndex++] = (bytes[i + c].toDouble() / 127.5) - 1.0;
      }
    }
    return _reshapeFloat32(floatList);
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
    List<double> probabilities;
    if (_outputType == TensorType.float32) {
      probabilities = List<double>.from(output[0]);
    } else if (_outputType == TensorType.uint8) {
      probabilities = List<int>.from(output[0]).map((v) => v / 255.0).toList();
    } else if (_outputType == TensorType.int8) {
      probabilities = List<int>.from(output[0]).map((v) => (v + 128) / 255.0).toList();
    } else {
      throw Exception('Unknown output type');
    }
    if (probabilities.length != _numClasses) {
      probabilities = probabilities.sublist(0, min(probabilities.length, _numClasses));
    }
    return probabilities;
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
      print('\n🌿 Identifying plant species...');

      // STEP 1: Leaf detection (with warm pixel fix)
      print('🍃 Performing leaf detection...');
      final leafAnalysis = await _performLeafDetection(imageFile);
      final isLeaf        = leafAnalysis['isLeaf'] as bool;
      final leafConfidence = leafAnalysis['confidence'] as double;

      if (!isLeaf) {
        print('❌ Image does not appear to be a plant leaf. Skipping species identification.');
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

      // STEP 3: Inference
      final input = _prepareInput(image);
      final stopwatch = Stopwatch()..start();
      final probabilities = _runInference(input);
      stopwatch.stop();
      print('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

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
      print('\n📊 Plant Species Identification Results:');
      print('   ┌─────────────────────────────────────┐');
      print('   │ ★ $topLabel');
      print('   │ Confidence: ${(topConfidence * 100).toStringAsFixed(1)}%');
      print('   │ Threshold: ${((analysis["thresholdUsed"] as double) * 100).toStringAsFixed(1)}%');
      print('   │ Leaf Check: ✅ Passed (${leafConfidence.toStringAsFixed(1)}%)');
      if (confidenceGap > 0) {
        print('   │ Gap to 2nd: ${(confidenceGap * 100).toStringAsFixed(1)}%');
      }
      print('   │ Status: ${isUnknown ? "⚠️ Low Confidence" : "✅ Confident Identification"}');
      print('   └─────────────────────────────────────┘');

      if (allPredictions.length > 1 && topConfidence < 0.8) {
        print('\n   Alternatives:');
        for (int i = 1; i < min(3, allPredictions.length); i++) {
          final conf = ((allPredictions[i]['confidence'] as double) * 100).toStringAsFixed(1);
          print('   $i. ${allPredictions[i]['label']}: $conf%');
        }
      }
      if (isUnknown) print('\n   Reason: $reasoning');

      String confidenceLevel = 'Low';
      if (topConfidence >= _highConfidenceThreshold)  confidenceLevel = 'High';
      else if (topConfidence >= _baseConfidenceThreshold) confidenceLevel = 'Medium';

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
      print('❌ Plant species identification failed: $e');
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

    if (allPredictions.length > 1) {
      final secondConfidence = allPredictions[1]['confidence'] as double;
      if (confidenceGap < 0.15 && topConfidence < 0.7 && secondConfidence > 0.3) {
        return {
          'isUnknown': true,
          'thresholdUsed': classThreshold,
          'reasoning': 'Ambiguous prediction '
              '(gap: ${(confidenceGap * 100).toStringAsFixed(1)}%, '
              '2nd: ${(secondConfidence * 100).toStringAsFixed(1)}%)',
        };
      }
    }

    if (topConfidence < 0.3) {
      return {
        'isUnknown': true,
        'thresholdUsed': classThreshold,
        'reasoning': 'Unusually low confidence (${(topConfidence * 100).toStringAsFixed(1)}%)',
      };
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
    print('♻️ Plant Species Model disposed');
  }
}