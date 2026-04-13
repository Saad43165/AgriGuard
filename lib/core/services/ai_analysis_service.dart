// lib/core/services/ai_analysis_service.dart
//
// Plant Analysis Service — orchestrates species ID, disease detection, and severity.
//
//   1. disease_id_service returns plantName from the disease label
//      e.g. "Tomato___healthy" → plantName = "Tomato"
//   2. plant_id_service returns the true species e.g. "Apple" (78.6%)
//   3. plant_analysis_service.dart NEVER reconciled these two.
//      It blindly used disease model's plant name in the final result.
//
// FIX: _reconcilePlantName() applies clear priority rules:
//   • Healthy plant   → ALWAYS trust plant ID model (disease model just
//                        picks whichever healthy label scored highest).
//   • Diseased plant  → Trust disease model for the disease name, but
//                        use plant ID model species if confidence ≥ 0.65.
//   • Plant ID < 0.5  → Fall back to disease model's plant name.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'plant_id_service.dart';
import 'disease_id_service.dart';
import 'severity_id_service.dart';
import 'leaf_detector.dart';

class PlantAnalysisService {
  final PlantIdService _speciesService;
  final DiseaseIdService _diseaseService;
  final SeverityIdService _severityService;
  bool _modelsLoaded = false;

  PlantAnalysisService({
    PlantIdService? speciesService,
    DiseaseIdService? diseaseService,
    SeverityIdService? severityService,
  })  : _speciesService = speciesService ?? PlantIdService(),
        _diseaseService = diseaseService ?? DiseaseIdService(),
        _severityService = severityService ?? SeverityIdService();

  Future<void> _ensureModelsLoaded() async {
    if (_modelsLoaded) return;
    try {
      if (!_speciesService.isLoaded) {
        await _speciesService.loadModel();
      }
      if (!_diseaseService.isLoaded) {
        await _diseaseService.loadModel();
      }
      await _severityService.initialize();
      _modelsLoaded = true;
    } catch (e) {
      // Don't permanently block retries if a load failed.
      _modelsLoaded = false;
      rethrow;
    }
  }

  // ── Leaf detection ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) =>
      LeafDetector.detect(imageFile);

  // ══════════════════════════════════════════════════════════════════════════
  // ▶ FIX: Plant name reconciliation
  //
  // Parameters:
  //   plantIdName       — species from plant_id_service   (e.g. "Apple")
  //   plantIdConfidence — confidence from plant_id_service (e.g. 0.786)
  //   diseasePlantName  — species embedded in disease label (e.g. "Tomato")
  //   isHealthy         — whether disease model returned "Healthy"
  //
  // Returns the correct final plant name to display.
  // ══════════════════════════════════════════════════════════════════════════
  String _reconcilePlantName({
    required String plantIdName,
    required double plantIdConfidence,
    required String diseasePlantName,
    required bool isHealthy,
  }) {
    // Normalise for comparison
    final idLower = plantIdName.trim().toLowerCase();
    final disLower = diseasePlantName.trim().toLowerCase();

    // ── Same result from both models — easy ──────────────────────────────
    if (idLower == disLower) {
      debugPrint('✅ Both models agree: $plantIdName');
      return plantIdName;
    }

    debugPrint('⚠️  Mismatch: PlantID="$plantIdName" (${ (plantIdConfidence * 100).toStringAsFixed(1)}%) '
        'vs Disease="$diseasePlantName" (isHealthy=$isHealthy)');

    // ── Healthy plant — ALWAYS use plant ID model ─────────────────────────
    // The disease model only knows which healthy *training class* scored
    // highest — that's irrelevant to the actual species in the photo.
    if (isHealthy) {
      if (plantIdConfidence >= 0.50) {
        debugPrint('✅ Healthy plant: trusting PlantID model → $plantIdName');
        return plantIdName;
      } else {
        debugPrint('⚠️  Healthy + low PlantID confidence. '
            'Using PlantID anyway: $plantIdName');
        return plantIdName;
      }
    }

    if (plantIdConfidence >= 0.75) {
      debugPrint('✅ Diseased plant, high PlantID confidence: trusting PlantID → $plantIdName');
      return plantIdName;
    }

    if (plantIdConfidence >= 0.60) {
      debugPrint('✅ Diseased plant, medium PlantID confidence: trusting PlantID → $plantIdName');
      return plantIdName;
    }

    debugPrint('✅ Diseased plant, low PlantID confidence: trusting Disease model → $diseasePlantName');
    return diseasePlantName;
  }

  // ── Severity helper ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _getSeverityAndRemediation({
    required File imageFile,
    required String diseaseName,
    required String plantName,
    required double confidence,
    required bool isHealthy,
  }) async {
    try {
      if (isHealthy || diseaseName.toLowerCase() == 'healthy') {
        debugPrint('🌿 Plant is healthy, skipping severity analysis');
        return {
          'severity': 'None',
          'remediation': ['Continue regular plant care', 'Monitor for any changes'],
          'severityLevel': 'None',
          'severityConfidence': 1.0,
          'effect': 'No disease effect detected',
          'colorCode': '#4CAF50',
          'description': 'Plant appears to be in good health',
          'action': 'Continue regular care and monitoring',
        };
      }

      if (diseaseName == 'Image Not Recognized' || plantName == 'Non-Plant Image') {
        return {
          'severity': 'N/A',
          'remediation': ['Please upload a clear photo of a plant leaf'],
          'severityLevel': 'N/A',
          'severityConfidence': 1.0,
          'effect': 'Non-plant image detected',
          'colorCode': '#9E9E9E',
          'description': 'Image does not appear to be a plant leaf',
          'action': 'Upload a plant leaf image',
        };
      }

      debugPrint('🔍 Getting severity and remediation for $plantName - $diseaseName');

      if (!_severityService.isReady()) {
        try {
          await _severityService.initialize();
        } catch (e) {
          debugPrint('⚠️ Failed to initialize SeverityIdService: $e');
          return _getFallbackSeverity(diseaseName, plantName, confidence);
        }
      }

      final severityResult = await _severityService.getSeverityAndRemediation(
        diseaseName: diseaseName,
        plantName: plantName,
        confidence: confidence,
        imagePath: imageFile.path,
        imageBase64: null,
      );

      return severityResult ?? _getFallbackSeverity(diseaseName, plantName, confidence);
    } catch (e, st) {
      debugPrint('❌ Error in severity analysis: $e\n$st');
      return _getFallbackSeverity(diseaseName, plantName, confidence);
    }
  }

  Map<String, dynamic> _getFallbackSeverity(
      String diseaseName, String plantName, double confidence) {
    String severity;
    List<String> remediation;

    if (confidence > 70) {
      severity = 'High';
      remediation = [
        'Apply appropriate fungicide/pesticide immediately',
        'Remove and destroy infected plant parts',
        'Isolate plant to prevent spread',
        'Consult agricultural expert',
      ];
    } else if (confidence > 40) {
      severity = 'Medium';
      remediation = [
        'Apply recommended treatment',
        'Improve plant growing conditions',
        'Monitor plant health daily',
        'Consider preventive measures',
      ];
    } else if (confidence > 20) {
      severity = 'Low';
      remediation = [
        'Monitor plant closely',
        'Apply preventive treatments',
        'Improve air circulation',
        'Adjust watering schedule',
      ];
    } else {
      severity = 'None';
      remediation = [
        'Plant appears healthy',
        'Continue regular care',
        'Monitor for changes',
        'Maintain optimal growing conditions',
      ];
    }

    return {
      'severity': severity,
      'remediation': remediation,
      'severityLevel': severity,
      'severityConfidence': 0.5,
      'effect': 'Fallback analysis used',
      'colorCode': '#FFC107',
      'description': 'Severity estimated based on confidence level',
      'action': 'Follow recommended remediation steps',
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Main entry point
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    try {
      debugPrint('🔍 Starting comprehensive plant analysis...');

      // STEP 0: Leaf detection
      debugPrint('🍃 Running enhanced leaf detection...');
      final leafAnalysis = await _performLeafDetection(imageFile);
      final isLeaf = leafAnalysis['isLeaf'] as bool;
      final leafConfidence = leafAnalysis['confidence'] as double;

      if (!isLeaf) {
      debugPrint('❌ Non-leaf image detected. Skipping further analysis.');
        return _nonLeafResult(leafConfidence, leafAnalysis);
      }

      // Ensure models are loaded before any inference.
      await _ensureModelsLoaded();

      // STEP 1: Plant species identification
      debugPrint('🌱 Running species identification...');
      final speciesResult = await _speciesService.predict(imageFile);

      final isSpeciesUnknown = speciesResult['isUnknown'] ?? true;
      final speciesName = (speciesResult['label'] ?? 'Unknown Plant') as String;
      final speciesConfidence = (speciesResult['confidence'] ?? 0.0) as double;
      final isLeafFromSpecies = speciesResult['isLeaf'] ?? true;

      if (!isLeafFromSpecies) {
        // Species model leaf heuristics are stricter and can false-reject valid leaves
        // (e.g., close-up blur / low edges). We already passed the global leaf check,
        // and the disease model has its own leaf check. So we do NOT stop here.
        debugPrint('⚠️ Species service marked non-leaf; continuing with disease detection.');
      }

      // STEP 2: Disease detection
      debugPrint('🩺 Running disease detection...');
      final diseaseResult = await _diseaseService.predict(imageFile);

      if (diseaseResult['isLeaf'] == false) {
        // Both plant ID and disease service rejected this as non-leaf
        return _nonLeafResult(
            diseaseResult['leafConfidence'] ?? leafConfidence, leafAnalysis,
            allChecks: true);
      }

      // ── STEP 2b: Cross-model plant consistency check + name reconciliation
      //
      // When plant ID model fails (returns Non-Plant / 0% confidence) but
      // disease model succeeds, trust the disease model's plant name.
      //
      // When both succeed but disagree, apply reconciliation rules.
      // When disease model's plant name doesn't match plant ID model but
      // the disease result is 'Healthy', always prefer plant ID model.
      String finalPlantName;
      bool diseaseModelPlantTrusted = false;

      final diseasePlantName =
      (diseaseResult['plantName'] ?? 'Unknown Plant') as String;
      final diseaseIsHealthy = (diseaseResult['isHealthy'] ?? true) as bool;
      final diseaseConfidenceRaw = diseaseResult['confidence'] != null
          ? double.tryParse(diseaseResult['confidence'].toString()) ?? 0.0
          : 0.0;

      if (isSpeciesUnknown || speciesConfidence < 0.50) {
        // Plant ID failed or very low confidence — use disease model's plant
        finalPlantName = diseasePlantName == 'Unknown Plant' || diseasePlantName.isEmpty
            ? 'Unknown Plant'
            : diseasePlantName;
        diseaseModelPlantTrusted = true;
        debugPrint('📌 Plant ID failed/uncertain — using disease model plant: $finalPlantName');
      } else {
        // Both models produced a result — reconcile
        finalPlantName = _reconcilePlantName(
          plantIdName: speciesName,
          plantIdConfidence: speciesConfidence,
          diseasePlantName: diseasePlantName,
          isHealthy: diseaseIsHealthy,
        );
        debugPrint('📌 Reconciled plant name: $finalPlantName');
      }

      // ── Cross-model disease validity check ──────────────────────────────
      // If disease model says plant=Tomato+Healthy but plant ID says Apple,
      // and they don't match, the healthy result is suspicious — flag it.
      bool diseaseResultSuspect = false;
      if (!diseaseModelPlantTrusted && diseaseIsHealthy) {
        final idLower = speciesName.trim().toLowerCase();
        final disLower = diseasePlantName.trim().toLowerCase();
        if (idLower != disLower && speciesConfidence >= 0.65) {
          // Disease model picked a healthy class from the WRONG plant.
          diseaseResultSuspect = true;
          debugPrint('⚠️ Disease model plant ($diseasePlantName) != PlantID ($speciesName) '
              'and result is Healthy — disease result suspect!');
        }
      }

      // Use disease result values but with suspect flag for UI/severity
      final rawDiseaseName = diseaseResultSuspect
          ? 'Unable to Determine'  // Don't claim healthy when we're unsure
          : (diseaseResult['diseaseName'] ?? diseaseResult['diagnosis'] ?? 'Unknown Disease')
              .toString();
      final isHealthyPlant = diseaseResultSuspect ? false
          : (diseaseResult['isHealthy'] ?? true) as bool;
      final diseaseConfidence = diseaseResultSuspect ? 0.0 : diseaseConfidenceRaw;

      // Low-confidence guard: don't claim a specific disease when the model is unsure.
      // This prevents wrong labels like "Apple Black Rot" at ~20% from being treated as real.
      const double minDiseaseConfidenceToClaim = 35.0; // percentage
      final bool diseaseTooUncertain =
          !isHealthyPlant && diseaseConfidence > 0 && diseaseConfidence < minDiseaseConfidenceToClaim;

      // Cross-plant mismatch guard:
      // If the disease model thinks the plant is a different species than the (high-confidence)
      // species model, and the disease confidence isn't strong, treat as uncertain.
      final bool plantMismatch =
          diseasePlantName.trim().isNotEmpty &&
          speciesName.trim().isNotEmpty &&
          diseasePlantName.trim().toLowerCase() != speciesName.trim().toLowerCase();
      const double minDiseaseConfidenceWhenPlantMismatch = 55.0; // percentage
      final bool mismatchTooWeak =
          !isHealthyPlant &&
          plantMismatch &&
          speciesConfidence >= 0.70 &&
          diseaseConfidence > 0 &&
          diseaseConfidence < minDiseaseConfidenceWhenPlantMismatch;

      final bool shouldGuardDisease = diseaseTooUncertain || mismatchTooWeak;
      final String guardedDiseaseName =
          shouldGuardDisease ? 'Unable to Determine' : rawDiseaseName;
      final double guardedDiseaseConfidence =
          shouldGuardDisease ? 0.0 : diseaseConfidence;


      // STEP 3: Severity & remediation
      Map<String, dynamic>? severityResult;
      List<String> combinedRemediation = [];
      String finalSeverity = 'Unknown';


      if (!isHealthyPlant && !diseaseTooUncertain) {
        debugPrint('⚡ Running severity analysis for $guardedDiseaseName...');
        severityResult = await _getSeverityAndRemediation(
          imageFile: imageFile,
          diseaseName: guardedDiseaseName,
          plantName: finalPlantName,
          confidence: guardedDiseaseConfidence,
          isHealthy: false,
        );

        if (severityResult != null) {
          finalSeverity = severityResult['severity']?.toString() ?? 'Unknown';
          final diseaseRemediation =
          _parseRemediation(diseaseResult['remediation'] ?? diseaseResult['treatment']);
          final severityRemediation = severityResult['remediation'] is List
              ? List<String>.from(severityResult['remediation'])
              : <String>[];
          final all = [...diseaseRemediation, ...severityRemediation];
          combinedRemediation = all.toSet().toList();
          if (combinedRemediation.isEmpty) {
            combinedRemediation = severityResult['remediation'] ?? [
              'Consult with agricultural expert',
              'Apply appropriate treatment',
              'Remove infected plant parts',
            ];
          }
        }
      } else if (isHealthyPlant) {
        // Short-circuit: getSeverityAndRemediation returns a static map for
        // healthy plants without running the TFLite model, so skip the call.
        severityResult = {
          'severity': 'None',
          'remediation': ['Continue regular plant care', 'Monitor for any changes'],
          'severityLevel': 'None',
          'severityConfidence': 1.0,
          'effect': 'No disease effect detected',
          'colorCode': '#4CAF50',
          'description': 'Plant appears to be in good health',
          'action': 'Continue regular care and monitoring',
        };
        finalSeverity = 'None';
        combinedRemediation = List<String>.from(severityResult['remediation']);
      } else {
        // Not healthy but too uncertain to claim a disease.
        finalSeverity = 'Unknown';
        combinedRemediation = const [
          'Take a clearer close-up photo of the affected leaf',
          'Ensure good lighting and focus',
          'Try Advanced Scan for better accuracy',
        ];
      }

      // STEP 4: Analysis status
      final String analysisStatus;
      final String displayMessage;

      if (isSpeciesUnknown) {
        analysisStatus = 'UNKNOWN_PLANT';
        displayMessage =
        'Plant species could not be identified with confidence. Try a clearer image.';
      } else if (speciesConfidence >= 0.8) {
        analysisStatus = 'HIGH_CONFIDENCE';
        displayMessage = 'Plant confidently identified as $finalPlantName';
      } else if (speciesConfidence >= 0.6) {
        analysisStatus = 'MEDIUM_CONFIDENCE';
        displayMessage = 'Plant identified as $finalPlantName';
      } else {
        analysisStatus = 'LOW_CONFIDENCE';
        displayMessage = 'Plant likely $finalPlantName, but low confidence';
      }

      // STEP 5: Build result
      const bool hasDiseaseData = true;

      Map<String, dynamic> result = {
        'success': true,
        'analysisType': 'combined_species_disease_severity',
        'isLeaf': true,
        'leafConfidence': leafConfidence,

        // ▶ Use reconciled name everywhere
        'species': finalPlantName,
        // Canonical keys for UI/storage
        'plantName': finalPlantName,
        'speciesConfidence': speciesConfidence,
        'isUnknown': isSpeciesUnknown,
        'analysisStatus': analysisStatus,
        'speciesMessage': displayMessage,

        'disease': rawDiseaseName,
        // Canonical keys for UI/storage
        'diseaseName': rawDiseaseName,
        'healthStatus': isHealthyPlant ? 'Healthy' : 'Diseased',
        'diseaseConfidence': diseaseConfidence,
        // Canonical key used by ResultsScreen/DiagnosisResult
        // Keep as a percentage-like value (same scale as diseaseConfidence).
        'confidence': diseaseConfidence,
        'isHealthy': isHealthyPlant,

        'hasDiseaseData': hasDiseaseData,
        'shouldShowDisease':
        !isSpeciesUnknown && speciesConfidence >= 0.6,

        'displayTitle':
        isSpeciesUnknown ? 'Plant Not Identified' : 'Plant Analysis Complete',
        'primaryMessage': _getPrimaryMessage(
            isSpeciesUnknown, finalPlantName, speciesConfidence, diseaseResult, finalSeverity),
        'secondaryMessage': _getSecondaryMessage(
            isSpeciesUnknown, speciesConfidence, diseaseResult, finalSeverity),

        '_rawSpecies': speciesResult,
        '_rawDisease': diseaseResult,
        '_leafAnalysis': leafAnalysis,

        // Convenience top-level fields for downstream components
        'rawLabel': diseaseResult['rawLabel'],

        // Debug fields — helpful for diagnosing future mismatches
        '_plantIdName': speciesName,
        '_diseasePlantName': diseaseResult['plantName'],
        '_reconciledName': finalPlantName,
        'shouldSaveToHistory': true,
      };

      // Severity data
      if (severityResult != null) {
        result.addAll({
          'severity': finalSeverity,
          'severityLevel': severityResult['severityLevel'] ?? finalSeverity,
          'severityConfidence':
          severityResult['severityConfidence'] ?? severityResult['confidence'] ?? 0.0,
          'remediation': combinedRemediation,
          'severityEffect': severityResult['effect'],
          'severityColorCode': severityResult['colorCode'],
          'severityDescription': severityResult['description'],
          'severityAction': severityResult['action'],
          'hasSeverityData': true,
        });
      } else {
        result.addAll({
          'severity': finalSeverity,
          'severityLevel': finalSeverity,
          'severityConfidence': 0.0,
          'remediation': combinedRemediation.isNotEmpty
              ? combinedRemediation
              : _getFallbackRemediations(isHealthyPlant),
          'hasSeverityData': false,
        });
      }

      if (diseaseResult['remediation'] != null) {
        final orig = _parseRemediation(diseaseResult['remediation']);
        if (orig.isNotEmpty) result['originalRemediation'] = orig;
      }

      debugPrint('✅ Analysis complete. Plant: $finalPlantName | Severity: $finalSeverity');
      return result;
    } catch (e) {
      debugPrint('❌ Plant analysis failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'species': 'Unknown Plant',
        'isUnknown': true,
        'analysisStatus': 'ERROR',
        'displayTitle': 'Analysis Failed',
        'primaryMessage': 'Unable to analyze plant image',
        'isLeaf': false,
        'severity': 'Unknown',
        'remediation': ['Please try again with a different image'],
      };
    }
  }

  // ── Non-leaf result builder ────────────────────────────────────────────────
  Map<String, dynamic> _nonLeafResult(
      double leafConfidence,
      Map<String, dynamic> leafAnalysis, {
        bool allChecks = false,
      }) {
    final String primaryMessage = allChecks
        ? 'All detection systems confirm this is not a plant leaf.'
        : 'The uploaded image does not appear to be a plant leaf.';

    return {
      'success': true,
      'analysisType': 'non_leaf_image',
      'isLeaf': false,
      'leafConfidence': leafConfidence,
      'species': 'Non-Plant Image',
      'disease': 'Image Not Recognized',
      'speciesConfidence': 0.0,
      'diseaseConfidence': 95.0,
      'isUnknown': true,
      'analysisStatus': 'NON_LEAF',
      'speciesMessage': 'Image does not appear to be a plant leaf',
      'displayTitle': 'Non-Plant Image Detected',
      'primaryMessage': primaryMessage,
      'secondaryMessage':
      'Please upload a clear photo of a plant leaf (${leafConfidence.toStringAsFixed(1)}% leaf confidence).',
      'leafAnalysis': leafAnalysis,
      'shouldShowDisease': false,
      'hasDiseaseData': false,
      'remediation': [
        'Upload a clear photo of a plant leaf',
        'Ensure the leaf fills most of the frame',
        'Avoid blurry or distant photos',
      ],
      'precautions': ['Use only plant leaf images for disease analysis'],
      'allPredictions': [],
      'rawLabel': 'non_leaf_image',
      // Guard: caller must check this before saving to scan history
      'shouldSaveToHistory': false,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<String> _parseRemediation(dynamic remediation) {
    if (remediation == null) return [];
    if (remediation is List) return List<String>.from(remediation);
    if (remediation is String) {
      return remediation
          .split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> _getFallbackRemediations(bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue regular plant care',
        'Maintain proper watering schedule',
        'Ensure adequate sunlight exposure',
        'Monitor for any changes in plant health',
      ];
    } else {
      return [
        'Apply appropriate fungicide if fungal disease is suspected',
        'Remove and destroy infected plant parts',
        'Improve air circulation around the plant',
        'Consult with agricultural expert for precise treatment',
      ];
    }
  }

  String _getPrimaryMessage(bool isUnknown, String species, double confidence,
      Map<String, dynamic>? disease, String severity) {
    if (isUnknown) return 'Plant species not recognized';
    final pct = (confidence * 100).toStringAsFixed(1);
    if (disease == null || (disease['isHealthy'] ?? true)) {
      return '$species identified with $pct% confidence';
    }
    final dn = disease['diseaseName'] ?? 'disease';
    return '$species with $dn (Severity: $severity)';
  }

  String _getSecondaryMessage(bool isUnknown, double confidence,
      Map<String, dynamic>? disease, String severity) {
    if (isUnknown) {
      if (confidence < 0.3) return 'Very low confidence — try a clearer image';
      if (confidence < 0.5) return 'Low confidence — image may be unclear';
      return 'Unable to identify plant species';
    }
    if (disease == null) {
      return 'Disease detection skipped (plant not confidently identified)';
    }
    if (disease['isHealthy'] ?? true) return 'No signs of disease detected';
    return 'Severity: $severity — Follow recommended treatment';
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