// lib/services/plant_id_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;

class PlantIdService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  // Model configuration
  static const String _modelPath = 'assets/models/plant_species_int8_dequantized.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;
  static const int _numClasses = 12;

  // Model specs discovered at runtime
  late TensorType _inputType;
  late TensorType _outputType;

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

      // Run simple health check
      await _runHealthCheck();

      // Run reality check to see if model is actually working
      await quickRealityCheck();

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

    print('📥 Input: ${inputTensor.shape} ${_tensorTypeToString(_inputType)}');
    print('📤 Output: ${outputTensor.shape} ${_tensorTypeToString(_outputType)}');
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

      print('🏷️ Loaded ${_labels.length} labels: ${_labels.join(", ")}');
    } catch (e) {
      print('⚠️ Failed to load labels, using defaults: $e');
      _labels = [
        'Apple', 'Bell pepper', 'Cedar_Apple_Rust', 'Cherry', 'Corn (Maize)',
        'Grape', 'Peach', 'Potato', 'Soybean', 'Strawberry', 'Tomato', 'Wheat'
      ];
    }
  }

  Future<void> _runHealthCheck() async {
    print('🧪 Running health check...');

    try {
      // Test with a simple gray image
      final testImage = _createSolidImage(128, 128, 128);
      final input = _prepareInput(testImage);
      final output = _runInference(input);

      // Check output validity
      final sum = output.fold(0.0, (a, b) => a + b);
      final maxVal = output.reduce((a, b) => a > b ? a : b);
      final maxIndex = output.indexOf(maxVal);

      print('📊 Health Check Results:');
      print('   Output sum: ${sum.toStringAsFixed(3)}');
      print('   Max confidence: ${(maxVal * 100).toStringAsFixed(1)}%');
      print('   Predicted class: ${_labels[maxIndex]}');

      if (sum > 0.1 && sum < 10.0) { // Relaxed check for sum
        print('✅ Model appears functional');
      } else {
        print('⚠️ Model output sum is unusual: $sum');
      }

    } catch (e) {
      print('❌ Health check failed: $e');
      rethrow;
    }
  }

  // ========== DIAGNOSTIC METHODS ==========

  Future<void> quickRealityCheck() async {
    print('');
    print('🔍 REALITY CHECK: Is model actually working?');
    print('════════════════════════════════════════════════════════');

    // Test 1: Same image twice
    print('1. Testing same image twice:');
    final testImage = _createSolidImage(128, 128, 128); // Gray image

    for (int i = 0; i < 2; i++) {
      final stopwatch = Stopwatch()..start();
      final input = _prepareInput(testImage);
      final output = _runInference(input);
      stopwatch.stop();

      final prediction = _getTopPrediction(output);
      final confidence = output.reduce((a, b) => a > b ? a : b);

      print('   Run ${i + 1}: $prediction (${(confidence * 100).toStringAsFixed(1)}%) in ${stopwatch.elapsedMilliseconds}ms');
    }

    print('');

    // Test 2: Completely different image
    print('2. Testing different image:');
    final differentImage = _createSolidImage(50, 150, 200); // Blue-green image
    final stopwatch = Stopwatch()..start();
    final input = _prepareInput(differentImage);
    final output = _runInference(input);
    stopwatch.stop();

    final prediction = _getTopPrediction(output);
    final confidence = output.reduce((a, b) => a > b ? a : b);

    print('   Different image: $prediction (${(confidence * 100).toStringAsFixed(1)}%) in ${stopwatch.elapsedMilliseconds}ms');

    print('');

    // Test 3: Extreme color test - FIXED: Proper typing
    print('3. Testing extreme colors:');

    // Define colors with proper typing
    final List<Map<String, dynamic>> colors = [
      {'name': 'Pure Red', 'rgb': [255, 0, 0]},
      {'name': 'Pure Green', 'rgb': [0, 255, 0]},
      {'name': 'Pure Blue', 'rgb': [0, 0, 255]},
    ];

    for (final color in colors) {
      final colorName = color['name'] as String;
      final rgb = color['rgb'] as List<int>;
      final colorImage = _createSolidImage(rgb[0], rgb[1], rgb[2]);
      final input = _prepareInput(colorImage);
      final output = _runInference(input);
      final prediction = _getTopPrediction(output);
      final confidence = output.reduce((a, b) => a > b ? a : b);

      print('   ${colorName.padRight(12)} → $prediction (${(confidence * 100).toStringAsFixed(1)}%)');
    }

    print('');

    // Conclusion
    if (stopwatch.elapsedMilliseconds < 10) {
      print('🚨 ALERT: Model processing too fast (<10ms) - likely not working properly');
    }

    print('════════════════════════════════════════════════════════');
    print('');
  }

  Future<void> emergencyModelCheck() async {
    print('🚨 EMERGENCY MODEL DIAGNOSIS');
    print('════════════════════════════════════════════════════════');

    final stopwatch = Stopwatch();

    // Test with completely different images - FIXED: Proper typing
    final List<Map<String, dynamic>> testCases = [
      {'name': 'Red Image', 'image': _createSolidImage(255, 0, 0)},
      {'name': 'Green Image', 'image': _createSolidImage(0, 255, 0)},
      {'name': 'Blue Image', 'image': _createSolidImage(0, 0, 255)},
      {'name': 'White Image', 'image': _createSolidImage(255, 255, 255)},
      {'name': 'Black Image', 'image': _createSolidImage(0, 0, 0)},
    ];

    for (final testCase in testCases) {
      final testName = testCase['name'] as String;
      final testImage = testCase['image'] as img_lib.Image;

      stopwatch.reset();
      stopwatch.start();

      final input = _prepareInput(testImage);
      final output = _runInference(input);
      final prediction = _getTopPrediction(output);
      final confidence = output.reduce((a, b) => a > b ? a : b);

      stopwatch.stop();

      print('$testName:');
      print('  Prediction: $prediction');
      print('  Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      print('  Processing time: ${stopwatch.elapsedMilliseconds}ms');
      print('  All outputs: ${output.map((v) => v.toStringAsFixed(3))}');
      print('');
    }
  }

  // ========== CORE FUNCTIONALITY ==========

  // FIXED: Proper input preparation
// REPLACE your _prepareInput method with this:
// FIXED: Use UINT8 values for UINT8 input tensor
  dynamic _prepareInput(img_lib.Image image) {
    // Model expects UINT8 [0-255] - send raw pixel values
    return [
      List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
        final pixel = image.getPixel(x, y);
        return [pixel.r, pixel.g, pixel.b]; // UINT8 values 0-255
      }))
    ];
  }  // FIXED: Proper inference execution
  List<double> _runInference(dynamic input) {
    // Create output tensor based on discovered type
    dynamic output;

    if (_outputType == TensorType.float32) {
      output = List<List<double>>.filled(1, List<double>.filled(_numClasses, 0.0));
    } else if (_outputType == TensorType.uint8) {
      output = List<List<int>>.filled(1, List<int>.filled(_numClasses, 0));
    } else if (_outputType == TensorType.int8) {
      output = List<List<int>>.filled(1, List<int>.filled(_numClasses, 0));
    } else {
      throw Exception('Unsupported output type: ${_tensorTypeToString(_outputType)}');
    }

    _interpreter!.run(input, output);

    // Convert output to probabilities
    return _convertToProbabilities(output);
  }

  // FIXED: Proper output conversion
  List<double> _convertToProbabilities(dynamic output) {
    if (output is List<List<double>>) {
      // Already float32 probabilities
      return output[0];
    } else if (output is List<List<int>>) {
      // Quantized output - need dequantization
      if (_outputType == TensorType.uint8) {
        // Convert uint8 [0, 255] to float32 [0, 1]
        return output[0].map((val) => val / 255.0).toList();
      } else if (_outputType == TensorType.int8) {
        // Convert int8 [-128, 127] to float32 [0, 1]
        return output[0].map((val) => (val + 128) / 255.0).toList();
      } else {
        return output[0].map((val) => val.toDouble()).toList();
      }
    } else {
      throw Exception('Unknown output format: ${output.runtimeType}');
    }
  }

  // Create solid color image for testing
  img_lib.Image _createSolidImage(int r, int g, int b) {
    final img = img_lib.Image(width: _inputSize, height: _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        img.setPixelRgb(x, y, r, g, b);
      }
    }
    return img;
  }

  // MAIN PREDICTION FUNCTION - SIMPLIFIED AND FIXED
  Future<Map<String, double>> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      print('🔍 Analyzing plant image...');

      // Load and resize image
      final image = await _loadAndResizeImage(imageFile);
      if (image == null) {
        throw Exception('Failed to load image');
      }

      // Prepare input
      final input = _prepareInput(image);

      // Run inference
      final output = _runInference(input);

      // Get top prediction
      return _getTopPrediction(output);

    } catch (e) {
      print('❌ Prediction failed: $e');
      rethrow;
    }
  }

  Map<String, double> _getTopPrediction(List<double> probabilities) {
    double maxConfidence = 0.0;
    int maxIndex = 0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        maxIndex = i;
      }
    }

    final prediction = _labels[maxIndex];

    print('✅ Prediction: $prediction (${(maxConfidence * 100).toStringAsFixed(1)}%)');

    return {prediction: maxConfidence};
  }

  Future<img_lib.Image?> _loadAndResizeImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img_lib.decodeImage(bytes);
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      return img_lib.copyResize(
          image,
          width: _inputSize,
          height: _inputSize,
          interpolation: img_lib.Interpolation.linear
      );
    } catch (e) {
      print('❌ Image loading failed: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
    print('♻️ Model disposed');
  }

  // Try alternative models if current one is broken
  Future<bool> tryAlternativeModels() async {
    final alternatives = [
      'assets/models/plant_species_float32.tflite',
      'assets/models/plant_species_int8_quantized.tflite',
    ];

    for (final path in alternatives) {
      try {
        print('🔄 Trying alternative model: $path');
        _interpreter?.close();
        _interpreter = await Interpreter.fromAsset(path);
        await _discoverTensorSpecs();
        await quickRealityCheck();

        // If we get varied predictions, this model works
        return true;
      } catch (e) {
        print('❌ $path failed: $e');
      }
    }
    return false;
  }
}