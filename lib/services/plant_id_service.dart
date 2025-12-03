// lib/services/plant_id_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import 'image_preprocessor.dart';

class PlantIdService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  // Model configuration
  static const String _modelPath = 'assets/models/plant_species_dynamic_quant.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;
  static const int _numClasses = 12;
  static const double _oodThreshold = 0.70; // Lowered threshold for testing

  // Model specs discovered at runtime
  late TensorType _inputType;
  late TensorType _outputType;
  late List<int> _inputShape;
  late List<int> _outputShape;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      print('🌱 Loading Plant Identification Model...');

      // Load interpreter
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Discover tensor specifications
      await _discoverTensorSpecs();

      // Load labels
      await _loadLabels();

      // Run health check
      await _runHealthCheck();

      _isLoaded = true;
      print('✅ Model loaded successfully!');

    } catch (e) {
      print('❌ Failed to load model: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  Future<void> _discoverTensorSpecs() async {
    final inputTensor = _interpreter!.getInputTensors().first;
    final outputTensor = _interpreter!.getOutputTensors().first;

    _inputType = inputTensor.type;
    _outputType = outputTensor.type;
    _inputShape = inputTensor.shape;
    _outputShape = outputTensor.shape;

    print('📥 Input: $_inputShape ${_tensorTypeToString(_inputType)}');
    print('📤 Output: $_outputShape ${_tensorTypeToString(_outputType)}');

    // Validate shapes
    if (_inputShape[1] != _inputSize || _inputShape[2] != _inputSize) {
      print('⚠️ WARNING: Expected input size $_inputSize x $_inputSize, got ${_inputShape[1]} x ${_inputShape[2]}');
    }

    if (_outputShape[1] != _numClasses) {
      print('⚠️ WARNING: Expected $_numClasses classes, got ${_outputShape[1]}');
    }
  }

  String _tensorTypeToString(TensorType type) {
    switch (type) {
      case TensorType.uint8: return 'UINT8';
      case TensorType.float32: return 'FLOAT32';
      case TensorType.int8: return 'INT8';
      default: return 'UNKNOWN';
    }
  }

  Future<void> _loadLabels() async {
    try {
      final txt = await rootBundle.loadString(_labelsPath);
      _labels = txt.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      if (_labels.length != _numClasses) {
        print('⚠️ Label count mismatch: expected $_numClasses, got ${_labels.length}');
      }

      print('🏷️ Loaded ${_labels.length} labels');
    } catch (e) {
      print('⚠️ Failed to load labels, using defaults: $e');
      _labels = [
        'Apple',
        'Bell pepper',
        'Cedar_Apple_Rust',
        'Cherry',
        'Corn (Maize)',
        'Grape',
        'Peach',
        'Potato',
        'Soybean',
        'Strawberry',
        'Tomato',
        'Wheat'
      ];
    }
    print('Labels: ${_labels.join(", ")}');
  }

  Future<void> _runHealthCheck() async {
    print('🧪 Running health check...');

    try {
      // Test with different colored images
      final testCases = [
        {'name': 'Gray', 'r': 128, 'g': 128, 'b': 128},
        {'name': 'Red', 'r': 255, 'g': 0, 'b': 0},
        {'name': 'Green', 'r': 0, 'g': 255, 'b': 0},
      ];

      final Map<String, int> predictions = {};

      for (final test in testCases) {
        final testImage = _createSolidImage(
          test['r'] as int,
          test['g'] as int,
          test['b'] as int,
        );
        
        final input = _prepareInput(testImage);
        final output = _runInference(input);
        
        final maxIndex = _getMaxIndex(output);
        final prediction = _labels[maxIndex];
        
        predictions[prediction] = (predictions[prediction] ?? 0) + 1;
        
        print('  ${test['name']}: $prediction (${(output[maxIndex] * 100).toStringAsFixed(1)}%)');
      }

      // Check if all predictions are the same
      if (predictions.length == 1) {
        print('🚨 WARNING: All test images predict the same class: ${predictions.keys.first}');
        print('   This indicates a preprocessing or model issue!');
      } else {
        print('✅ Model shows varied predictions - looks good!');
      }

    } catch (e) {
      print('❌ Health check failed: $e');
      rethrow;
    }
  }

  // ========== CRITICAL FIX: PROPER INPUT PREPARATION ==========

  dynamic _prepareInput(img_lib.Image image) {
    if (_inputType == TensorType.uint8) {
      // For uint8 input: use raw pixel values [0-255]
      final Uint8List bytes = ImagePreprocessor.imageToUint8List(image);
      
      // Convert to proper shape [1, 224, 224, 3]
      final shaped = <List<List<List<int>>>>[];
      shaped.add(<List<List<int>>>[]);
      
      int byteIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        shaped[0].add(<List<int>>[]);
        for (int x = 0; x < _inputSize; x++) {
          shaped[0][y].add([
            bytes[byteIndex++],
            bytes[byteIndex++],
            bytes[byteIndex++],
          ]);
        }
      }
      
      return shaped;
      
    } else if (_inputType == TensorType.float32) {
      // For float32 input: apply MobileNetV3 preprocessing [-1, 1]
      final Float32List floats = ImagePreprocessor.imageToFloat32List(image);
      
      // Convert to proper shape [1, 224, 224, 3]
      final shaped = <List<List<List<double>>>>[];
      shaped.add(<List<List<double>>>[]);
      
      int floatIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        shaped[0].add(<List<double>>[]);
        for (int x = 0; x < _inputSize; x++) {
          shaped[0][y].add([
            floats[floatIndex++],
            floats[floatIndex++],
            floats[floatIndex++],
          ]);
        }
      }
      
      return shaped;
      
    } else {
      throw Exception('Unsupported input type: ${_tensorTypeToString(_inputType)}');
    }
  }

  // ========== CRITICAL FIX: PROPER INFERENCE EXECUTION ==========

  List<double> _runInference(dynamic input) {
    // Create output buffer based on output type
    dynamic output;

    if (_outputType == TensorType.float32) {
      // Float32 output - create nested list structure
      output = List.generate(1, (_) => List<double>.filled(_numClasses, 0.0));
    } else if (_outputType == TensorType.uint8) {
      // Uint8 output - create nested list structure
      output = List.generate(1, (_) => List<int>.filled(_numClasses, 0));
    } else if (_outputType == TensorType.int8) {
      // Int8 output - create nested list structure
      output = List.generate(1, (_) => List<int>.filled(_numClasses, 0));
    } else {
      throw Exception('Unsupported output type: ${_tensorTypeToString(_outputType)}');
    }

    // Run inference
    _interpreter!.run(input, output);

    // Convert to probabilities
    return _convertToProbabilities(output);
  }

  // ========== CRITICAL FIX: PROPER OUTPUT CONVERSION ==========

  List<double> _convertToProbabilities(dynamic output) {
    List<double> probabilities;

    if (_outputType == TensorType.float32) {
      // Already float32 - extract from nested list
      if (output is List<List<double>>) {
        probabilities = List<double>.from(output[0]);
      } else {
        probabilities = List<double>.from(output);
      }
      
    } else if (_outputType == TensorType.uint8) {
      // Dequantize uint8 [0, 255] to float [0, 1]
      List<int> intOutput;
      if (output is List<List<int>>) {
        intOutput = output[0];
      } else {
        intOutput = List<int>.from(output);
      }
      probabilities = intOutput.map((val) => val / 255.0).toList();
      
    } else if (_outputType == TensorType.int8) {
      // Dequantize int8 [-128, 127] to float [0, 1]
      List<int> intOutput;
      if (output is List<List<int>>) {
        intOutput = output[0];
      } else {
        intOutput = List<int>.from(output);
      }
      probabilities = intOutput.map((val) => (val + 128) / 255.0).toList();
      
    } else {
      throw Exception('Unknown output type: ${_tensorTypeToString(_outputType)}');
    }

    // Verify probabilities
    final sum = probabilities.fold(0.0, (a, b) => a + b);
    print('  Probability sum: ${sum.toStringAsFixed(3)} (should be ~1.0 for softmax)');

    // Apply softmax if sum is way off (e.g., logits instead of probabilities)
    if (sum < 0.1 || sum > 10.0) {
      print('  ⚠️ Applying softmax normalization');
      probabilities = _softmax(probabilities);
    }

    return probabilities;
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expValues = logits.map((x) => exp(x - maxLogit)).toList();
    final sumExp = expValues.fold(0.0, (a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  double exp(double x) {
    // Simple exp approximation
    return (1.0 + x / 256.0).toDouble() * (1.0 + x / 256.0).toDouble() * 
           (1.0 + x / 256.0).toDouble() * (1.0 + x / 256.0).toDouble() *
           (1.0 + x / 256.0).toDouble() * (1.0 + x / 256.0).toDouble() *
           (1.0 + x / 256.0).toDouble() * (1.0 + x / 256.0).toDouble();
  }

  int _getMaxIndex(List<double> values) {
    double maxVal = values[0];
    int maxIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  // ========== MAIN PREDICTION FUNCTION ==========

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      print('\n🔍 Analyzing plant image...');

      // Load and preprocess image
      final image = await ImagePreprocessor.preprocess(
        imageFile,
        modelInputSize: _inputSize,
      );

      if (image == null) {
        throw Exception('Failed to load image');
      }

      // Debug: show sample pixels
      ImagePreprocessor.debugPixels(image);

      // Prepare input
      final input = _prepareInput(image);

      // Run inference
      final stopwatch = Stopwatch()..start();
      final probabilities = _runInference(input);
      stopwatch.stop();

      print('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

      // Get top predictions
      final results = _getTopPredictions(probabilities, topK: 3);

      // Check OOD threshold
      final topPrediction = results[0];
      final isUnknown = topPrediction['confidence'] < _oodThreshold;

      print('\n📊 Results:');
      for (int i = 0; i < results.length; i++) {
        final marker = i == 0 ? '★' : ' ';
        print('  $marker ${results[i]['label']}: ${(results[i]['confidence'] * 100).toStringAsFixed(1)}%');
      }

      if (isUnknown) {
        print('⚠️ Low confidence - might be unknown species');
      }

      return {
        'label': topPrediction['label'],
        'confidence': topPrediction['confidence'],
        'isUnknown': isUnknown,
        'allPredictions': results,
        'inferenceTime': stopwatch.elapsedMilliseconds,
      };

    } catch (e) {
      print('❌ Prediction failed: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getTopPredictions(List<double> probabilities, {int topK = 3}) {
    List<Map<String, dynamic>> predictions = [];

    for (int i = 0; i < probabilities.length; i++) {
      predictions.add({
        'label': _labels[i],
        'confidence': probabilities[i],
        'index': i,
      });
    }

    predictions.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    return predictions.take(topK).toList();
  }

  img_lib.Image _createSolidImage(int r, int g, int b) {
    final img = img_lib.Image(width: _inputSize, height: _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        img.setPixelRgb(x, y, r, g, b);
      }
    }
    return img;
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
    print('♻️ Model disposed');
  }

  // Emergency diagnostic
  Future<void> runDiagnostics(File imageFile) async {
    print('\n${'='*60}');
    print('🔬 RUNNING FULL DIAGNOSTICS');
    print('='*60);

    // Load image
    final image = await ImagePreprocessor.preprocess(imageFile, modelInputSize: _inputSize);
    if (image == null) {
      print('❌ Failed to load image for diagnostics');
      return;
    }

    print('\n1. Image Stats:');
    ImagePreprocessor.debugPixels(image, samples: 10);

    print('\n2. Input Preparation:');
    final input = _prepareInput(image);
    print('  Input type: ${input.runtimeType}');
    print('  Input shape: $_inputShape');

    print('\n3. Running Inference:');
    final output = _runInference(input);

    print('\n4. Output Analysis:');
    print('  Output length: ${output.length}');
    print('  Output sum: ${output.fold(0.0, (a, b) => a + b).toStringAsFixed(3)}');
    print('  Min: ${output.reduce((a, b) => a < b ? a : b).toStringAsFixed(6)}');
    print('  Max: ${output.reduce((a, b) => a > b ? a : b).toStringAsFixed(6)}');

    print('\n5. All Predictions:');
    for (int i = 0; i < output.length; i++) {
      print('  ${_labels[i].padRight(20)}: ${output[i].toStringAsFixed(6)}');
    }

    print('\n${'='*60}');
  }
}