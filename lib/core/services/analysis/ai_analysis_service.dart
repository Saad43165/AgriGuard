
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../disease/disease_id_service.dart';
import '../leaf_detector.dart';
import '../severity/severity_id_service.dart';
import 'analysis_steps.dart';


class PlantAnalysisService {
  final DiseaseIdService _diseaseService;
  final SeverityIdService _severityService;
  late final AnalysisSteps _steps;
  bool _modelsLoaded = false;

  PlantAnalysisService({
    DiseaseIdService? diseaseService,
    SeverityIdService? severityService,
  })  : _diseaseService = diseaseService ?? DiseaseIdService(),
        _severityService = severityService ?? SeverityIdService() {
    _steps = AnalysisSteps(
      diseaseService: _diseaseService,
      severityService: _severityService,
    );
  }

  Future<void> _ensureModelsLoaded() async {
    if (_modelsLoaded) return;
    try {
      if (!_diseaseService.isLoaded) {
        await _diseaseService.loadModel();
      }
      await _severityService.initialize();
      _modelsLoaded = true;
    } catch (e) {
      _modelsLoaded = false;
      rethrow;
    }
  }

  Future<bool> checkIsLeaf(File imageFile) async {
    try {
      final result = await LeafDetector.detect(imageFile);
      return result['isLeaf'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>> analyzePlant(File imageFile, {String? plantHint}) async {
    try {
      debugPrint('🔍 Starting comprehensive plant analysis...');
      await _ensureModelsLoaded();
      return await _steps.execute(imageFile, plantHint: plantHint);
    } catch (e) {
      debugPrint('❌ Plant analysis failed: $e');
      return _steps.buildErrorResult(e.toString());
    }
  }

  void dispose() {
    try {
      _severityService.dispose();
      debugPrint('✅ PlantAnalysisService disposed');
    } catch (e) {
      debugPrint('⚠️ Error disposing services: $e');
    }
  }
}