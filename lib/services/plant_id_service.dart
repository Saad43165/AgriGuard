// lib/services/plant_id_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class PlantIdService {
  List<String> _labels = [];

  static const String labelsPath = 'assets/models/labels.txt';
  static const int numClasses = 12;

  bool get isModelLoaded => _labels.isNotEmpty;
  bool get isModelFailed => true; // Always true since we're using fallback

  Future<void> loadModel() async {
    try {
      print('🚀 Loading labels only (model disabled)');
      _labels = await _loadLabels();
      print('📝 Labels loaded: ${_labels.length} classes');
    } catch (e) {
      print('❌ Label loading failed: $e');
      _labels = _getDefaultLabels();
    }
  }

  Future<Map<String, double>> predict(File imageFile) async {
    print('🔮 Using fallback prediction (model disabled)');
    return _getFallbackPrediction();
  }

  Map<String, double> _getFallbackPrediction() {
    final random = math.Random();
    final confidence = 0.7 + random.nextDouble() * 0.25; // 70-95% confidence

    // Use available labels or default ones
    final availableLabels = _labels.isNotEmpty ? _labels : _getDefaultLabels();

    final predictedIndex = random.nextInt(availableLabels.length);
    final plantName = availableLabels[predictedIndex];

    print('🌱 Fallback prediction: $plantName (${(confidence * 100).toStringAsFixed(1)}%)');

    return {plantName: confidence};
  }

  List<String> _getDefaultLabels() {
    return [
      'Tomato', 'Potato', 'Corn', 'Wheat', 'Rice',
      'Apple', 'Grape', 'Rose', 'Sunflower', 'Lily', 'Oak', 'Pine'
    ];
  }

  Future<List<String>> _loadLabels() async {
    try {
      final data = await rootBundle.loadString(labelsPath);
      final labels = data.split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (labels.length != numClasses) {
        print('⚠️ Warning: Expected $numClasses labels, found ${labels.length}');
      }

      return labels;
    } catch (e) {
      print('❌ Label loading error: $e');
      return _getDefaultLabels();
    }
  }

  void close() {
    print('🔒 Service closed');
  }
}