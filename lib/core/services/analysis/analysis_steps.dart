import 'dart:io';
import '../disease/disease_id_service.dart';
import '../severity/severity_id_service.dart';
import '../leaf_detector.dart';
import 'analysis_result_builder.dart';
import 'analysis_helpers.dart';

class AnalysisSteps {
  final DiseaseIdService _diseaseService;
  final SeverityIdService _severityService;
  final AnalysisResultBuilder _resultBuilder = AnalysisResultBuilder();

  AnalysisSteps({
    required DiseaseIdService diseaseService,
    required SeverityIdService severityService,
  })  : _diseaseService = diseaseService,
        _severityService = severityService;

  Future<Map<String, dynamic>> execute(File imageFile, {String? plantHint}) async {
    // STEP 0: Leaf detection
    final leafAnalysis = await _performLeafDetection(imageFile);
    if (!(leafAnalysis['isLeaf'] as bool)) {
      return _resultBuilder.nonLeafResult(leafAnalysis, false);
    }

    // STEP 1: Disease detection
    final diseaseResult = await _runDiseaseDetection(imageFile, plantHint);
    if (diseaseResult['isLeaf'] == false) {
      return _resultBuilder.nonLeafResult(leafAnalysis, true);
    }

    // STEP 2: Extract plant & disease info
    final extracted = AnalysisHelpers.extractPlantDiseaseInfo(diseaseResult);

    // STEP 3: Get severity
    final severityData = await _getSeverity(
      imageFile: imageFile,
      diseaseName: extracted.guardedDiseaseName,
      plantName: extracted.finalPlantName,
      confidence: extracted.guardedDiseaseConfidence,
      isHealthy: extracted.isHealthyPlant,
      diseaseTooUncertain: extracted.diseaseTooUncertain,
    );

    // STEP 4: Determine analysis status
    final status = AnalysisHelpers.determineStatus(
      extracted.isUnknownPlant,
      extracted.diseaseConfidence,
      extracted.finalPlantName,
    );

    // STEP 5: Build final result
    return _resultBuilder.build(
      leafAnalysis: leafAnalysis,
      diseaseResult: diseaseResult,
      extracted: extracted,
      severityData: severityData,
      status: status,
    );
  }

  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) =>
      LeafDetector.detect(imageFile);

  Future<Map<String, dynamic>> _runDiseaseDetection(File imageFile, String? plantHint) async {
    if (plantHint != null && plantHint.isNotEmpty) {
      return _diseaseService.predictWithPlantHint(
        imageFile,
        plantHint: plantHint,
        plantHintConfidence: 0.95,
      );
    }
    return _diseaseService.predict(imageFile);
  }

  Future<Map<String, dynamic>> _getSeverity({
    required File imageFile,
    required String diseaseName,
    required String plantName,
    required double confidence,
    required bool isHealthy,
    required bool diseaseTooUncertain,
  }) async {
    if (isHealthy || diseaseTooUncertain) {
      return AnalysisHelpers.staticSeverityResult(isHealthy, diseaseTooUncertain);
    }

    if (!_severityService.isReady) {
      await _severityService.initialize();
    }

    final result = await _severityService.getSeverityAndRemediation(
      diseaseName: diseaseName,
      plantName: plantName,
      confidence: confidence,
      imagePath: imageFile.path,
    );

    return result ?? AnalysisHelpers.fallbackSeverity(diseaseName, plantName, confidence);
  }

  Map<String, dynamic> buildErrorResult(String error) =>
      _resultBuilder.errorResult(error);
}