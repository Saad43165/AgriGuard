import 'dart:io';
import '../../../../../core/services/severity/severity_id_service.dart';
import '../../../../core/services/analysis/ai_analysis_service.dart';
import '../groq/groq_service.dart';
import '../plantid/plant_id_api_service.dart';
import 'advanced_api_tester.dart';
import 'advanced_groq_analyzer.dart' show AdvancedGroqAnalyzer;
import 'advanced_plantid_analyzer.dart';
import 'advanced_symptom_lookup.dart';

class AdvancedSearchService {
  final GroqService _groqService = GroqService();
  final PlantAnalysisService _onDeviceAnalysis = PlantAnalysisService();
  final SeverityIdService _severityService = SeverityIdService();
  final PlantIdService _plantIdService = PlantIdService();

  late final AdvancedApiTester _apiTester;
  late final AdvancedSymptomLookup _symptomLookup;
  late final AdvancedGroqAnalyzer _groqAnalyzer;
  late final AdvancedPlantIdAnalyzer _plantIdAnalyzer;

  AdvancedSearchService() {
    _apiTester = AdvancedApiTester(
      groqService: _groqService,
      plantIdService: _plantIdService,
    );
    _symptomLookup = AdvancedSymptomLookup();
    _groqAnalyzer = AdvancedGroqAnalyzer(
      onDeviceAnalysis: _onDeviceAnalysis,
      severityService: _severityService,
      groqService: _groqService,
      symptomLookup: _symptomLookup,
    );
    _plantIdAnalyzer = AdvancedPlantIdAnalyzer(
      plantIdService: _plantIdService,
    );
  }

  // ── API Testing ──────────────────────────────────────────────────────────

  Future<bool> testGroqApi() => _apiTester.testGroqApi();
  Future<bool> testPlantIdApi() => _apiTester.testPlantIdApi();
  Future<Map<String, dynamic>> testAllApis() => _apiTester.testAllApis();

  // ── Analysis ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzePlant(File imageFile, {required bool inUrdu}) =>
      _groqAnalyzer.analyze(imageFile, inUrdu: inUrdu);

  Future<Map<String, dynamic>> analyzeWithPlantId(File imageFile) =>
      _plantIdAnalyzer.analyze(imageFile);
}