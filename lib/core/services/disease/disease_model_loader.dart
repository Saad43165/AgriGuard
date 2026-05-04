import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DiseaseModelLoader {
  static const String _modelPath = 'assets/new_model/plantcity_35classes.tflite';
  static const String _labelsPath = 'assets/new_model/plantcity_35classes.json';

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  List<String> get labels => _labels;

  List<int> get inputShape => _interpreter?.getInputTensor(0).shape ?? [1, 300, 300, 3];
  List<int> get outputShape => _interpreter?.getOutputTensor(0).shape ?? [1, 35];

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    try {
      debugPrint('🌱 Loading Disease Detection Model...');
      await _loadLabels();

      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

      debugPrint('📊 Model loaded — Input: $inputShape, Output: $outputShape');
      debugPrint('   Labels: ${_labels.length} classes');
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ Failed to load disease model: $e');
      _isLoaded = false;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final data = await rootBundle.loadString(_labelsPath);
      if (_labelsPath.endsWith('.json')) {
        _labels = (jsonDecode(data) as List).cast<String>();
      } else {
        _labels = data.split('\n').where((l) => l.trim().isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('❌ Failed to load labels: $e');
      _labels = [];
    }
  }

  List<double> runInference(List<List<List<List<double>>>> input, List<int> outShape) {
    final stopwatch = Stopwatch()..start();

    final out2D = List.generate(outShape[0], (_) => List<double>.filled(outShape[1], 0.0));
    _interpreter!.run(input, out2D);
    final output = out2D.expand((r) => r).toList();

    stopwatch.stop();
    debugPrint('⏱️ Inference: ${stopwatch.elapsedMilliseconds}ms');

    return output;
  }

  Future<bool> test() async {
    try {
      if (!_isLoaded) await load();

      final shape = _interpreter!.getInputTensor(0).shape;
      final dummyInput = List.generate(1, (_) => List.generate(
          shape[1], (_) => List.generate(shape[2], (_) => List<double>.filled(3, 0.5))));

      final outShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.filled(outShape.reduce((a, b) => a * b), 0.0);
      _interpreter!.run(dummyInput, output);

      debugPrint('✅ Model test passed');
      return true;
    } catch (e) {
      debugPrint('❌ Model test failed: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _isLoaded = false;
    debugPrint('🧹 Disease model disposed');
  }
}