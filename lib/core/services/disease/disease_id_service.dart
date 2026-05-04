import 'dart:io';
import 'package:flutter/foundation.dart';
import '../leaf_detector.dart';
import 'disease_model_loader.dart';
import 'disease_image_preprocessor.dart';
import 'disease_output_processor.dart';

class DiseaseIdService {
  final DiseaseModelLoader _modelLoader = DiseaseModelLoader();
  final DiseaseImagePreprocessor _preprocessor = DiseaseImagePreprocessor();
  final DiseaseOutputProcessor _outputProcessor = DiseaseOutputProcessor();

  bool get isLoaded => _modelLoader.isLoaded;
  bool get isLoading => _modelLoader.isLoading;
  List<String> get labels => _modelLoader.labels;

  Future<void> loadModel() => _modelLoader.load();

  Future<Map<String, dynamic>> predictWithPlantHint(
      File imageFile, {
        String? plantHint,
        double plantHintConfidence = 0.0,
      }) async {
    final result = await predict(imageFile);
    if (plantHint == null || plantHint.isEmpty) return result;
    if (result['success'] != true) return result;
    return _outputProcessor.applyPlantHint(result, plantHint);
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_modelLoader.isLoaded) await _modelLoader.load();

    try {
      debugPrint('🔍 Running disease detection...');

      // STEP 1: Leaf detection
      final leafAnalysis = await _performLeafDetection(imageFile);
      if (!(leafAnalysis['isLeaf'] as bool)) {
        return _outputProcessor.nonLeafResult(
            leafAnalysis['confidence'] as double, leafAnalysis);
      }

      // STEP 2: Image quality check
      final qualityCheck = await _preprocessor.checkImageQuality(imageFile);
      if (!qualityCheck['isGoodQuality']) {
        return _outputProcessor.qualityIssueResult(
            leafAnalysis['confidence'] as double);
      }

      // STEP 3: Run inference
      final preprocessResult = await _preprocessor.preprocessForInference(
          imageFile, _modelLoader.inputShape, _modelLoader.outputShape);

      final output = _modelLoader.runInference(
          preprocessResult.inputData, preprocessResult.outputShape);

      // STEP 4: Process output
      final result = _outputProcessor.process(
          output, _modelLoader.labels, preprocessResult.inferenceTime);

      result['isLeaf'] = true;
      result['leafConfidence'] = leafAnalysis['confidence'];

      debugPrint('✅ Disease detection completed');
      return result;
    } catch (e) {
      debugPrint('❌ Disease prediction error: $e');
      return _outputProcessor.fallbackResult(e.toString());
    }
  }

  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) =>
      LeafDetector.detect(imageFile);

  Future<void> dispose() => _modelLoader.dispose();
  Future<bool> testModel() => _modelLoader.test();
}