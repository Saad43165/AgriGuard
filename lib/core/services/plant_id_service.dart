// lib/services/plant_id_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
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
  static const double _confidenceThreshold = 0.65;
  static const double _minAcceptableConfidence = 0.60;

  final String _normalizationScheme = '[-1, 1]'; // Your model uses [-1, 1] normalization

  late TensorType _inputType;
  late TensorType _outputType;
  late List<int> _inputShape;
  late List<int> _outputShape;
  int _numClasses = 0;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      print('🌱 Loading Plant Species Identification Model...');

      // Load the model
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Discover model specifications
      await _discoverTensorSpecs();
      
      // Load the class labels
      await _loadLabels();
      
      // Verify labels match model output
      if (_labels.length != _numClasses) {
        print('⚠️ Warning: Labels (${_labels.length}) don\'t match model output ($_numClasses)');
        _adjustLabelsToMatchModel();
      }

      // Verify normalization scheme (based on your training)
      print('✅ Using [-1, 1] normalization (as per training)');
      
      // Run a quick test
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
    final inputTensor = _interpreter!.getInputTensors().first;
    final outputTensor = _interpreter!.getOutputTensors().first;

    _inputType = inputTensor.type;
    _outputType = outputTensor.type;
    _inputShape = inputTensor.shape;
    _outputShape = outputTensor.shape;
    _numClasses = _outputShape[1];
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
      print('✅ Loaded ${_labels.length} plant species labels');
      
      // Display all plant species
      print('📋 Plant Species in model:');
      for (int i = 0; i < _labels.length; i++) {
        print('   ${i + 1}. ${_labels[i]}');
      }
    } catch (e) {
      print('⚠️ Failed to load labels, using default: $e');
      // Default species from your training
      _labels = [
        'Apple',
        'Bell pepper',
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
    
    // Create a simple green test image (simulating a leaf)
    final testImage = _createSolidImage(50, 150, 50); // Green color
    
    try {
      final input = _prepareInput(testImage);
      final probabilities = _runInference(input);
      
      final maxIndex = _getMaxIndex(probabilities);
      final maxConfidence = probabilities[maxIndex];
      
      print('   Test inference successful');
      print('   Top prediction confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%');
      
      if (maxConfidence < 0.1) {
        print('   ⚠️ Very low confidence - check normalization');
      }
    } catch (e) {
      print('   ❌ Test failed: $e');
    }
  }

  dynamic _prepareInput(img_lib.Image image) {
    // Always use [-1, 1] normalization as per your training
    return _prepareInputWithNormalization(image, _normalizationScheme);
  }

  dynamic _prepareInputWithNormalization(img_lib.Image image, String scheme) {
    if (_inputType == TensorType.uint8) {
      return _prepareUint8Input(image);
    }

    final bytes = image.getBytes(order: img_lib.ChannelOrder.rgba);
    final floatList = Float32List(3 * _inputSize * _inputSize);

    int floatIndex = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      // RGB channels (skip alpha)
      for (int c = 0; c < 3; c++) {
        final pixelValue = bytes[i + c].toDouble();
        
        // Only [-1, 1] normalization (as used in training)
        floatList[floatIndex++] = (pixelValue / 127.5) - 1.0;
      }
    }

    // Reshape to [1, 224, 224, 3]
    return _reshapeFloat32(floatList);
  }

  dynamic _reshapeFloat32(Float32List floatList) {
    final shaped = List<List<List<List<double>>>>.filled(1, 
      List<List<List<double>>>.filled(_inputSize, 
        List<List<double>>.filled(_inputSize, 
          List<double>.filled(3, 0.0)
        )
      )
    );

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
          List<int>.filled(3, 0)
        )
      )
    );

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
    // Create output tensor based on model type
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

    // Run inference
    _interpreter!.run(input, output);

    // Convert to probabilities
    return _convertToProbabilities(output);
  }

  List<double> _convertToProbabilities(dynamic output) {
    List<double> probabilities;
    
    if (_outputType == TensorType.float32) {
      // Output is already probabilities
      probabilities = List<double>.from(output[0]);
    } else if (_outputType == TensorType.uint8) {
      final intOutput = List<int>.from(output[0]);
      probabilities = intOutput.map((val) => val / 255.0).toList();
    } else if (_outputType == TensorType.int8) {
      final intOutput = List<int>.from(output[0]);
      probabilities = intOutput.map((val) => (val + 128) / 255.0).toList();
    } else {
      throw Exception('Unknown output type');
    }

    // Ensure we have the right number of probabilities
    if (probabilities.length != _numClasses) {
      probabilities = probabilities.sublist(0, _numClasses);
    }

    return probabilities;
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

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Plant species model not loaded. Call loadModel() first.');
    }

    try {
      print('\n🌿 Identifying plant species...');

      // Preprocess image
      final image = await ImagePreprocessor.preprocess(
        imageFile,
        modelInputSize: _inputSize,
      );

      if (image == null) {
        throw Exception('Failed to process image');
      }

      // Prepare input and run inference
      final input = _prepareInput(image);
      final stopwatch = Stopwatch()..start();
      final probabilities = _runInference(input);
      stopwatch.stop();

      print('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

      // Get all predictions sorted by confidence
      final allPredictions = _getAllPredictions(probabilities);
      
      // Get top prediction
      final topPrediction = allPredictions.isNotEmpty ? allPredictions[0] : null;
      
      if (topPrediction == null) {
        return {
          'success': false,
          'error': 'No predictions generated',
        };
      }

      final topLabel = topPrediction['label'] as String;
      final topConfidence = topPrediction['confidence'] as double;
      
      // Check if confidence is high enough
      final isUnknown = topConfidence < _confidenceThreshold || 
                       topConfidence < _minAcceptableConfidence;
      
      // Get confidence gap with second prediction
      double confidenceGap = 0.0;
      if (allPredictions.length > 1) {
        final secondConfidence = allPredictions[1]['confidence'] as double;
        confidenceGap = topConfidence - secondConfidence;
      }

      // Display results
      print('\n📊 Plant Species Identification Results:');
      print('   ★ $topLabel: ${(topConfidence * 100).toStringAsFixed(1)}%');
      
      if (allPredictions.length > 1) {
        for (int i = 1; i < min(3, allPredictions.length); i++) {
          final label = allPredictions[i]['label'];
          final conf = ((allPredictions[i]['confidence'] as double) * 100).toStringAsFixed(1);
          print('   $label: $conf%');
        }
      }
      
      if (isUnknown) {
        print('   ⚠️ Low confidence - plant species may not be recognized');
      }

      return {
        'success': true,
        'label': topLabel,
        'confidence': topConfidence,
        'isUnknown': isUnknown,
        'allPredictions': allPredictions,
        'top3Predictions': allPredictions.take(3).toList(),
        'inferenceTime': stopwatch.elapsedMilliseconds,
        'confidenceGap': confidenceGap,
        'normalizationScheme': _normalizationScheme,
        'message': isUnknown 
            ? 'Plant species not recognized with confidence'
            : 'Identified as $topLabel',
      };

    } catch (e) {
      print('❌ Plant species identification failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'label': 'Unknown Plant',
        'confidence': 0.0,
        'isUnknown': true,
      };
    }
  }

  List<Map<String, dynamic>> _getAllPredictions(List<double> probabilities) {
    List<Map<String, dynamic>> predictions = [];
    
    for (int i = 0; i < min(probabilities.length, _labels.length); i++) {
      predictions.add({
        'label': _labels[i],
        'confidence': probabilities[i],
        'index': i,
      });
    }
    
    // Sort by confidence (highest first)
    predictions.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    return predictions;
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
    print('♻️ Plant Species Model disposed');
  }
}