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

  static const String _modelPath = 'assets/models/plant_species_dynamic_quant.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;
  static const double _oodThreshold = 0.50;
  static const double _minAcceptableConfidence = 0.40;

  // Auto-detected normalization scheme
  String _bestNormalizationScheme = '[-1, 1]';

  late TensorType _inputType;
  late TensorType _outputType;
  late List<int> _inputShape;
  late List<int> _outputShape;
  int _numClasses = 0;

  // Disease indicators for post-processing validation
  final List<String> _diseaseKeywords = [
    'rust', 'blight', 'spot', 'rot', 'mildew', 'scorch',
    'canker', 'scab', 'measles', 'mold', 'powdery',
    'downy', 'wilt', 'anthracnose', 'septoria', 'virus',
    'bacterial', 'cercospora', 'stripe', 'curl', 'esca'
  ];

  // Valid plant names (these should be in your labels)
  final List<String> _validPlants = [
    'Apple', 'Bell pepper', 'Cherry', 'Corn (Maize)', 'Corn', 'Maize',
    'Grape', 'Peach', 'Potato', 'Strawberry', 'Tomato',
    'Soybean', 'Wheat'
  ];

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      print('🌱 Loading Plant Identification Model...');

      _interpreter = await Interpreter.fromAsset(_modelPath);
      await _discoverTensorSpecs();
      await _loadLabels();

      if (_labels.length != _numClasses) {
        print('⚠️ WARNING: Model expects $_numClasses classes but labels file has ${_labels.length} labels');
        _adjustLabelsToMatchModel();
      }

      // Auto-detect best normalization scheme
      await _detectBestNormalization();

      // Run health check with best scheme
      await _runHealthCheck();

      _isLoaded = true;
      print('✅ Model loaded successfully!');
    } catch (e) {
      print('❌ Failed to load model: $e');
      print('Stack trace: ${StackTrace.current}');
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

    print('📥 Input: $_inputShape ${_tensorTypeToString(_inputType)}');
    print('📤 Output: $_outputShape ${_tensorTypeToString(_outputType)}');
    print('🎯 Model has $_numClasses output classes');
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
      print('✅ Loaded ${_labels.length} labels from file');

      // Print all labels for debugging
      print('📋 Labels list:');
      for (int i = 0; i < min(15, _labels.length); i++) {
        print('   ${i + 1}. ${_labels[i]}');
      }
      if (_labels.length > 15) {
        print('   ... and ${_labels.length - 15} more');
      }
    } catch (e) {
      print('⚠️ Failed to load labels: $e');
      _labels = [
        'Apple', 'Bell pepper', 'Cherry', 'Corn (Maize)', 'Grape',
        'Peach', 'Potato', 'Strawberry', 'Tomato', 'Soybean', 'Wheat'
      ];
    }
  }

  void _adjustLabelsToMatchModel() {
    if (_labels.length > _numClasses) {
      _labels = _labels.sublist(0, _numClasses);
    } else if (_labels.length < _numClasses) {
      final needed = _numClasses - _labels.length;
      for (int i = 0; i < needed; i++) {
        _labels.add('Plant_${_labels.length + 1}');
      }
    }
    print('✅ Adjusted labels to match model: ${_labels.length} items');
  }

  Future<void> _detectBestNormalization() async {
    print('\n🔬 AUTO-DETECTING BEST NORMALIZATION SCHEME...');

    final schemes = [
      {'name': '[-1, 1]', 'desc': 'MobileNet style'},
      {'name': '[0, 1]', 'desc': 'Simple 0-1 range'},
      {'name': 'ImageNet', 'desc': 'ImageNet mean/std'},
    ];

    final testImages = [
      _createSolidImage(50, 150, 50),   // Dark green (leaf)
      _createSolidImage(150, 200, 100), // Light green (leaf)
      _createSolidImage(139, 90, 43),   // Brown (soil/disease)
      _createSolidImage(255, 0, 0),     // Red (flower/disease)
    ];

    Map<String, double> schemeScores = {};

    for (final scheme in schemes) {
      final schemeName = scheme['name'] as String;
      print('\n  Testing: $schemeName (${scheme['desc']})');

      final predictions = <String>[];
      final confidences = <double>[];

      for (final testImage in testImages) {
        try {
          final input = _prepareInputWithScheme(testImage, schemeName);
          final output = _runInference(input);
          final maxIndex = _getMaxIndex(output);
          final prediction = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
          final confidence = output[maxIndex];

          predictions.add(prediction);
          confidences.add(confidence);
        } catch (e) {
          print('    ❌ Error with $schemeName: $e');
          schemeScores[schemeName] = 0.0;
          break;
        }
      }

      if (predictions.length == testImages.length) {
        final uniquePredictions = predictions.toSet().length;
        final avgConfidence = confidences.reduce((a, b) => a + b) / confidences.length;

        final diversityScore = uniquePredictions / testImages.length;
        final confidenceScore = avgConfidence.clamp(0.3, 0.8);
        final totalScore = (diversityScore * 0.4) + (confidenceScore * 0.6);

        schemeScores[schemeName] = totalScore;

        print('    Predictions: ${predictions.toSet().length}/${testImages.length} unique');
        print('    Avg confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
        print('    Score: ${(totalScore * 100).toStringAsFixed(1)}%');
      }
    }

    if (schemeScores.isNotEmpty) {
      final bestEntry = schemeScores.entries.reduce((a, b) => a.value > b.value ? a : b);
      _bestNormalizationScheme = bestEntry.key;
      print('\n✅ Selected normalization: $_bestNormalizationScheme (score: ${(bestEntry.value * 100).toStringAsFixed(1)}%)');
    } else {
      print('\n⚠️ Could not determine best scheme, using default: $_bestNormalizationScheme');
    }
  }

  dynamic _prepareInputWithScheme(img_lib.Image image, String scheme) {
    if (_inputType == TensorType.uint8) {
      return _prepareUint8Input(image);
    }

    final bytes = image.getBytes(order: img_lib.ChannelOrder.rgba);
    final floatList = Float32List(bytes.length);

    for (int i = 0; i < bytes.length; i++) {
      final channel = i % 3;
      final pixelValue = bytes[i].toDouble();

      switch (scheme) {
        case '[-1, 1]':
          floatList[i] = (pixelValue / 127.5) - 1.0;
          break;
        case '[0, 1]':
          floatList[i] = pixelValue / 255.0;
          break;
        case 'ImageNet':
          final mean = [0.485, 0.456, 0.406];
          final std = [0.229, 0.224, 0.225];
          floatList[i] = (pixelValue / 255.0 - mean[channel]) / std[channel];
          break;
        default:
          floatList[i] = pixelValue / 255.0;
      }
    }

    return _reshapeFloat32(floatList);
  }

  dynamic _prepareInput(img_lib.Image image) {
    return _prepareInputWithScheme(image, _bestNormalizationScheme);
  }

  dynamic _reshapeFloat32(Float32List floatList) {
    final shaped = <List<List<List<double>>>>[];
    shaped.add(<List<List<double>>>[]);

    int floatIndex = 0;
    for (int y = 0; y < _inputSize; y++) {
      shaped[0].add(<List<double>>[]);
      for (int x = 0; x < _inputSize; x++) {
        shaped[0][y].add([
          floatList[floatIndex++],
          floatList[floatIndex++],
          floatList[floatIndex++],
        ]);
      }
    }

    return shaped;
  }

  dynamic _prepareUint8Input(img_lib.Image image) {
    final Uint8List bytes = ImagePreprocessor.imageToUint8List(image);
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
  }

  Future<void> _runHealthCheck() async {
    print('\n🧪 Running health check with $_bestNormalizationScheme normalization...');

    final testCases = [
      {'name': 'Gray', 'r': 128, 'g': 128, 'b': 128},
      {'name': 'Dark Green', 'r': 50, 'g': 150, 'b': 50},
      {'name': 'Light Green', 'r': 150, 'g': 200, 'b': 100},
      {'name': 'Brown', 'r': 139, 'g': 90, 'b': 43},
    ];

    final Map<String, int> predictions = {};
    final List<double> confidences = [];

    for (final test in testCases) {
      final testImage = _createSolidImage(
        test['r'] as int,
        test['g'] as int,
        test['b'] as int,
      );

      final input = _prepareInput(testImage);
      final output = _runInference(input);
      final maxIndex = _getMaxIndex(output);
      final prediction = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';
      final confidence = output[maxIndex];

      predictions[prediction] = (predictions[prediction] ?? 0) + 1;
      confidences.add(confidence);

      print('  ${(test['name'] as String).padRight(12)}: $prediction (${(confidence * 100).toStringAsFixed(1)}%)');
    }

    final uniquePredictions = predictions.length;
    final avgConfidence = confidences.reduce((a, b) => a + b) / confidences.length;

    if (uniquePredictions == 1) {
      print('🚨 CRITICAL: All test images predict "${predictions.keys.first}"');
    } else if (uniquePredictions == 2) {
      print('⚠️ WARNING: Only 2 different predictions across 4 test images');
    } else if (uniquePredictions >= 3) {
      print('✅ Model shows good diversity (${uniquePredictions}/4 unique predictions)');
    }

    print('  Average confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
  }

  List<double> _runInference(dynamic input) {
    dynamic output;

    if (_outputType == TensorType.float32) {
      output = List.generate(1, (_) => List<double>.filled(_numClasses, 0.0));
    } else if (_outputType == TensorType.uint8) {
      output = List.generate(1, (_) => List<int>.filled(_numClasses, 0));
    } else if (_outputType == TensorType.int8) {
      output = List.generate(1, (_) => List<int>.filled(_numClasses, 0));
    } else {
      throw Exception('Unsupported output type: ${_tensorTypeToString(_outputType)}');
    }

    _interpreter!.run(input, output);
    return _convertToProbabilities(output);
  }

  List<double> _convertToProbabilities(dynamic output) {
    List<double> probabilities;

    if (_outputType == TensorType.float32) {
      probabilities = output is List<List<double>>
          ? List<double>.from(output[0])
          : List<double>.from(output);
    } else if (_outputType == TensorType.uint8) {
      final intOutput = output is List<List<int>> ? output[0] : List<int>.from(output);
      probabilities = intOutput.map((val) => val / 255.0).toList();
    } else if (_outputType == TensorType.int8) {
      final intOutput = output is List<List<int>> ? output[0] : List<int>.from(output);
      probabilities = intOutput.map((val) => (val + 128) / 255.0).toList();
    } else {
      throw Exception('Unknown output type: ${_tensorTypeToString(_outputType)}');
    }

    if (probabilities.length != _numClasses) {
      if (probabilities.length > _numClasses) {
        probabilities = probabilities.sublist(0, _numClasses);
      } else {
        while (probabilities.length < _numClasses) {
          probabilities.add(0.0);
        }
      }
    }

    final sum = probabilities.fold(0.0, (a, b) => a + b);
    if (sum < 0.5 || sum > 2.0) {
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
    return (1.0 + x / 256.0) * (1.0 + x / 256.0) *
        (1.0 + x / 256.0) * (1.0 + x / 256.0) *
        (1.0 + x / 256.0) * (1.0 + x / 256.0) *
        (1.0 + x / 256.0) * (1.0 + x / 256.0);
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

// In the predict method, update this section:

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      print('\n🔍 Analyzing plant image with $_bestNormalizationScheme normalization...');

      final image = await ImagePreprocessor.preprocess(
        imageFile,
        modelInputSize: _inputSize,
      );

      if (image == null) {
        throw Exception('Failed to load image');
      }

      final input = _prepareInput(image);
      final stopwatch = Stopwatch()..start();
      final probabilities = _runInference(input);
      stopwatch.stop();

      print('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

      // Get all predictions
      final allPredictions = _getAllPredictions(probabilities);

      // Filter out disease predictions
      final filteredPredictions = _filterDiseasePredictions(allPredictions);

      // If filtering removed predictions, show warning
      if (filteredPredictions.length < allPredictions.length) {
        final removedCount = allPredictions.length - filteredPredictions.length;
        print('⚠️ Filtered out $removedCount disease predictions');

        // Show what was filtered
        final removed = allPredictions.where((p) => !_isLikelyPlant(p['label'])).toList();
        for (final pred in removed.take(3)) {
          print('   - ${pred['label']}: ${(pred['confidence'] * 100).toStringAsFixed(1)}%');
        }
      }

      // Use filtered predictions
      final results = filteredPredictions.isNotEmpty ? filteredPredictions : allPredictions;
      final topPrediction = results.isNotEmpty ? results[0] : {'label': 'Unknown Plant', 'confidence': 0.0};
      final topConfidence = topPrediction['confidence'] as double;
      final secondConfidence = results.length > 1 ? results[1]['confidence'] as double : 0.0;
      final confidenceGap = topConfidence - secondConfidence;

      // Check if prediction is actually a plant
      final predictedLabel = topPrediction['label'] as String;
      final isLikelyPlant = _isLikelyPlant(predictedLabel);

      // Enhanced unknown detection
      final isUnknown = !isLikelyPlant ||
          topConfidence < _oodThreshold ||
          (confidenceGap < 0.15 && topConfidence < 0.65) ||
          topConfidence < _minAcceptableConfidence;

      print('\n📊 Plant ID Results:');
      for (int i = 0; i < min(3, results.length); i++) {
        final marker = i == 0 ? '★' : ' ';
        final label = results[i]['label'];
        final conf = ((results[i]['confidence'] as double) * 100).toStringAsFixed(1);
        final plantStatus = _isLikelyPlant(label) ? '' : ' (Disease)';
        print('  $marker $label$plantStatus: $conf%');
      }

      if (!isLikelyPlant) {
        print('⚠️ WARNING: Prediction "$predictedLabel" appears to be a disease, not a plant species');
      }

      if (isUnknown) {
        print('⚠️ Low confidence - marking as unknown');
        print('   Top: ${(topConfidence * 100).toStringAsFixed(1)}%, Gap: ${(confidenceGap * 100).toStringAsFixed(1)}%');
      }

      return {
        'label': predictedLabel,
        'confidence': topConfidence,
        'isUnknown': isUnknown,
        'isLikelyPlant': isLikelyPlant,
        'allPredictions': results,
        'filteredPredictions': filteredPredictions.length < allPredictions.length,
        'inferenceTime': stopwatch.elapsedMilliseconds,
        'confidenceGap': confidenceGap,
        'normalizationScheme': _bestNormalizationScheme,
        'success': true,
      };

    } catch (e) {
      print('❌ Plant ID prediction failed: $e');
      return {
        'success': false,
        'label': 'Unknown Plant',
        'confidence': 0.0,
        'isUnknown': true,
        'isLikelyPlant': false,
        'error': e.toString(),
      };
    }
  }

// Add these helper methods:

  List<Map<String, dynamic>> _getAllPredictions(List<double> probabilities) {
    List<Map<String, dynamic>> predictions = [];
    final limit = min(probabilities.length, _labels.length);

    for (int i = 0; i < limit; i++) {
      predictions.add({
        'label': _labels[i],
        'confidence': probabilities[i],
        'index': i,
      });
    }

    predictions.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    return predictions;
  }

  List<Map<String, dynamic>> _filterDiseasePredictions(List<Map<String, dynamic>> predictions) {
    return predictions.where((pred) => _isLikelyPlant(pred['label'])).toList();
  }

  bool _isLikelyPlant(String label) {
    final lowerLabel = label.toLowerCase();

    // Disease indicators to filter out
    final diseaseIndicators = [
      'rust', 'blight', 'spot', 'rot', 'mildew', 'scorch',
      'canker', 'scab', 'measles', 'mold', 'powdery',
      'downy', 'wilt', 'anthracnose', 'septoria', 'virus',
      'bacterial', 'cercospora', 'stripe', 'curl', 'esca'
    ];

    // Check if it contains disease keywords
    for (final indicator in diseaseIndicators) {
      if (lowerLabel.contains(indicator)) {
        return false;
      }
    }

    // Valid plant names
    final validPlants = [
      'apple', 'bell pepper', 'cherry', 'corn', 'maize',
      'grape', 'peach', 'potato', 'strawberry', 'tomato',
      'soybean', 'wheat', 'pepper'
    ];

    // Check if it's a valid plant
    for (final plant in validPlants) {
      if (lowerLabel.contains(plant)) {
        return true;
      }
    }

    // Check patterns
    if (label.contains('(') && label.contains(')')) { // Like "Corn (Maize)"
      return true;
    }

    // Single capitalized word
    if (RegExp(r'^[A-Z][a-z]+$').hasMatch(label)) {
      return true;
    }

    // Two words
    if (RegExp(r'^[A-Z][a-z]+\s+[A-Z][a-z]+$').hasMatch(label)) {
      return true;
    }

    return false;
  }

  bool _isDiseaseLabel(String label) {
    final lowerLabel = label.toLowerCase();

    // Check for disease keywords
    for (final keyword in _diseaseKeywords) {
      if (lowerLabel.contains(keyword)) {
        return true;
      }
    }

    // Check for pattern with underscores (like Cedar_Apple_Rust)
    if (label.contains('_') && !label.contains('(') && !label.contains(')')) {
      // But exclude known plants with underscores
      if (label.contains('Corn_(Maize)') || label.contains('Bell_pepper')) {
        return false;
      }
      return true;
    }

    return false;
  }

  bool _isValidPlantLabel(String label) {
    // Check if it's a disease first
    if (_isDiseaseLabel(label)) {
      return false;
    }

    // Check if it matches valid plant names
    final lowerLabel = label.toLowerCase();
    for (final plant in _validPlants) {
      if (lowerLabel.contains(plant.toLowerCase())) {
        return true;
      }
    }

    // Check for plant patterns
    if (label.contains('(') && label.contains(')')) { // Like "Corn (Maize)"
      return true;
    }

    // Single capitalized word (likely a plant)
    if (RegExp(r'^[A-Z][a-z]+$').hasMatch(label)) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> _validateAndSelectBestPlant(List<Map<String, dynamic>> allPredictions) {
    final warnings = <String>[];
    final filteredDiseases = <Map<String, dynamic>>[];
    final validPlantPredictions = <Map<String, dynamic>>[];

    // Separate valid plants from diseases
    for (final pred in allPredictions) {
      if (pred['isValidPlant'] as bool) {
        validPlantPredictions.add(pred);
      } else {
        filteredDiseases.add(pred);
      }
    }

    // If we have valid plant predictions
    if (validPlantPredictions.isNotEmpty) {
      final bestPrediction = validPlantPredictions[0];
      final topConfidence = bestPrediction['confidence'] as double;
      final secondConfidence = validPlantPredictions.length > 1
          ? validPlantPredictions[1]['confidence'] as double
          : 0.0;
      final confidenceGap = topConfidence - secondConfidence;

      // Check confidence thresholds
      final isUnknown = topConfidence < _oodThreshold ||
          (confidenceGap < 0.15 && topConfidence < 0.65) ||
          topConfidence < _minAcceptableConfidence;

      if (filteredDiseases.isNotEmpty) {
        final topDisease = filteredDiseases[0];
        final diseaseConfidence = topDisease['confidence'] as double;

        // If disease confidence is higher than plant confidence, warn
        if (diseaseConfidence > topConfidence) {
          warnings.add('Disease "${topDisease['label']}" (${(diseaseConfidence * 100).toStringAsFixed(1)}%) has higher confidence than plant prediction');
        }
      }

      return {
        'bestPrediction': bestPrediction,
        'isUnknown': isUnknown,
        'confidenceGap': confidenceGap,
        'allValidPredictions': validPlantPredictions.take(3).toList(),
        'warnings': warnings,
        'filteredDiseases': filteredDiseases.take(3).toList(),
      };
    }

    // No valid plant predictions found - use top prediction with warning
    warnings.add('No valid plant species detected. Using top prediction with warning.');

    final bestPrediction = allPredictions.isNotEmpty
        ? allPredictions[0]
        : {'label': 'Unknown Plant', 'confidence': 0.0, 'isValidPlant': false};

    return {
      'bestPrediction': bestPrediction,
      'isUnknown': true,
      'confidenceGap': 0.0,
      'allValidPredictions': [],
      'warnings': warnings,
      'filteredDiseases': [],
    };
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
    print('♻️ Plant ID Model disposed');
  }
}