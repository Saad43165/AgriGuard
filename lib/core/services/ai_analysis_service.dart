// lib/services/plant_analysis_service.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'plant_id_service.dart';
import 'disease_id_service.dart';
import 'severity_id_service.dart'; // Added import

class PlantAnalysisService {
  final PlantIdService _speciesService = PlantIdService();
  final DiseaseIdService _diseaseService = DiseaseIdService();
  final SeverityIdService _severityService = SeverityIdService(); // Added service
  
  // Enhanced leaf detection
  Future<Map<String, dynamic>> _performLeafDetection(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return {'isLeaf': true, 'confidence': 50.0, 'message': 'Failed to decode image'};
      }

      final resizedImage = img.copyResize(image, width: 300);
      
      // Multiple checks
      int greenPixels = 0;
      int totalPixels = resizedImage.width * resizedImage.height;
      int edgeCount = 0;
      final edgeThreshold = 25;
      
      for (int y = 0; y < resizedImage.height; y++) {
        for (int x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          
          // Green check
          if (g > r * 1.2 && g > b * 1.2 && g > 30) {
            greenPixels++;
          }
          
          // Edge check (simple)
          if (y < resizedImage.height - 1 && x < resizedImage.width - 1) {
            final current = (r + g + b) / 3;
            final rightPixel = resizedImage.getPixel(x + 1, y);
            final right = (rightPixel.r + rightPixel.g + rightPixel.b) / 3;
            final downPixel = resizedImage.getPixel(x, y + 1);
            final down = (downPixel.r + downPixel.g + downPixel.b) / 3;
            
            if ((current - right).abs() > edgeThreshold || 
                (current - down).abs() > edgeThreshold) {
              edgeCount++;
            }
          }
        }
      }
      
      final greenPercentage = (greenPixels / totalPixels) * 100;
      final edgeDensity = (edgeCount / totalPixels) * 100;
      
      // Decision logic
      bool isLeaf = greenPercentage > 25 && edgeDensity > 5;
      double confidence = (greenPercentage * 0.6) + (edgeDensity * 0.4);
      
      print('🍃 AI Analysis Service Leaf Detection:');
      print('   Green: ${greenPercentage.toStringAsFixed(1)}%');
      print('   Edge Density: ${edgeDensity.toStringAsFixed(1)}%');
      print('   Is Leaf: $isLeaf');
      print('   Confidence: ${confidence.toStringAsFixed(1)}%');
      
      return {
        'isLeaf': isLeaf,
        'confidence': confidence,
        'greenPercentage': greenPercentage,
        'edgeDensity': edgeDensity,
        'message': isLeaf 
            ? 'Image appears to be a plant leaf'
            : 'Image does not appear to be a plant leaf',
      };
    } catch (e) {
      print('❌ Leaf detection error: $e');
      return {'isLeaf': true, 'confidence': 50.0, 'message': 'Detection error'};
    }
  }
  
  // Get severity and remediation using SeverityIdService
  Future<Map<String, dynamic>?> _getSeverityAndRemediation({
    required File imageFile,
    required String diseaseName,
    required String plantName,
    required double confidence,
    required bool isHealthy,
  }) async {
    try {
      // Don't run severity analysis for healthy plants
      if (isHealthy || diseaseName.toLowerCase() == 'healthy') {
        print('🌿 Plant is healthy, skipping severity analysis');
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
      
      // Don't run for non-leaf images
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
      
      print('🔍 Getting severity and remediation for $plantName - $diseaseName');
      
      // Initialize severity service if needed
      if (!_severityService.isReady()) {
        try {
          await _severityService.initialize();
        } catch (e) {
          print('⚠️ Failed to initialize SeverityIdService: $e');
          return _getFallbackSeverity(diseaseName, plantName, confidence);
        }
      }
      
      // Get severity and remediation from service
      final severityResult = await _severityService.getSeverityAndRemediation(
        diseaseName: diseaseName,
        plantName: plantName,
        confidence: confidence,
        imagePath: imageFile.path,
        imageBase64: null, // We'll let the service read from file
      );
      
      if (severityResult != null) {
        print('✅ Severity analysis complete: ${severityResult['severity']}');
        return severityResult;
      } else {
        print('⚠️ Severity service returned null, using fallback');
        return _getFallbackSeverity(diseaseName, plantName, confidence);
      }
    } catch (e, stackTrace) {
      print('❌ Error in severity analysis: $e');
      print('Stack trace: $stackTrace');
      return _getFallbackSeverity(diseaseName, plantName, confidence);
    }
  }
  
  // Fallback severity analysis
  Map<String, dynamic> _getFallbackSeverity(String diseaseName, String plantName, double confidence) {
    String severity;
    List<String> remediation;
    
    if (confidence > 70) {
      severity = 'High';
      remediation = [
        'Apply appropriate fungicide/pesticide immediately',
        'Remove and destroy infected plant parts',
        'Isolate plant to prevent spread',
        'Consult agricultural expert'
      ];
    } else if (confidence > 40) {
      severity = 'Medium';
      remediation = [
        'Apply recommended treatment',
        'Improve plant growing conditions',
        'Monitor plant health daily',
        'Consider preventive measures'
      ];
    } else if (confidence > 20) {
      severity = 'Low';
      remediation = [
        'Monitor plant closely',
        'Apply preventive treatments',
        'Improve air circulation',
        'Adjust watering schedule'
      ];
    } else {
      severity = 'None';
      remediation = [
        'Plant appears healthy',
        'Continue regular care',
        'Monitor for changes',
        'Maintain optimal growing conditions'
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
  
  Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    try {
      print('🔍 Starting comprehensive plant analysis...');
      
      // STEP 0: Enhanced leaf detection (FIRST AND MOST IMPORTANT)
      print('🍃 Running enhanced leaf detection...');
      final leafAnalysis = await _performLeafDetection(imageFile);
      final isLeaf = leafAnalysis['isLeaf'] as bool;
      final leafConfidence = leafAnalysis['confidence'] as double;
      
      if (!isLeaf) {
        print('❌ Image does not appear to be a plant leaf. Skipping further analysis.');
        return {
          'success': true,
          'analysisType': 'non_leaf_image',
          'isLeaf': false,
          'leafConfidence': leafConfidence,
          'species': 'Non-Plant Image',
          'disease': 'Image Not Recognized',
          'speciesConfidence': 0.0,
          'diseaseConfidence': 95.0, // High confidence it's not a leaf
          'isUnknown': true,
          'analysisStatus': 'NON_LEAF',
          'speciesMessage': 'Image does not appear to be a plant leaf',
          'displayTitle': 'Non-Plant Image Detected',
          'primaryMessage': 'The uploaded image does not appear to be a plant leaf.',
          'secondaryMessage': 'Our analysis indicates this is not plant material (${leafConfidence.toStringAsFixed(1)}% confidence). Please upload a clear photo of a plant leaf.',
          'leafAnalysis': leafAnalysis,
          'shouldShowDisease': false,
          'hasDiseaseData': false,
          'remediation': [
            'Upload a clear photo of a plant leaf',
            'Ensure the leaf fills most of the frame',
            'Avoid blurry or distant photos',
            'Check that the image shows plant material'
          ],
          'precautions': ['Use only plant leaf images for disease analysis'],
          'allPredictions': [],
          'rawLabel': 'non_leaf_image',
        };
      }
      
      // STEP 1: Identify plant species
      print('🌱 Running species identification...');
      final speciesResult = await _speciesService.predict(imageFile);
      
      final speciesSuccess = speciesResult['success'] ?? false;
      final isSpeciesUnknown = speciesResult['isUnknown'] ?? true;
      final speciesName = speciesResult['label'] ?? 'Unknown Plant';
      final speciesConfidence = speciesResult['confidence'] ?? 0.0;
      final isLeafFromSpecies = speciesResult['isLeaf'] ?? true;
      
      // Double-check leaf detection from species service
      if (!isLeafFromSpecies) {
        print('⚠️ Species service also detected non-leaf image. Confirming result.');
        return {
          'success': true,
          'analysisType': 'non_leaf_image',
          'isLeaf': false,
          'leafConfidence': speciesResult['leafConfidence'] ?? leafConfidence,
          'species': 'Non-Plant Image',
          'disease': 'Image Not Recognized',
          'speciesConfidence': 0.0,
          'diseaseConfidence': 95.0,
          'isUnknown': true,
          'analysisStatus': 'NON_LEAF',
          'displayTitle': 'Non-Plant Image Detected',
          'primaryMessage': 'Multiple checks confirm this is not a plant leaf.',
          'secondaryMessage': 'Both leaf detection systems identified this as non-plant material.',
          'shouldShowDisease': false,
          'hasDiseaseData': false,
        };
      }
      
      // STEP 2: Only run disease detection if plant is confidently identified AND it's a leaf
      Map<String, dynamic>? diseaseResult;
      if (speciesSuccess && !isSpeciesUnknown && speciesConfidence >= 0.6) {
        print('🩺 Running disease detection for $speciesName...');
        diseaseResult = await _diseaseService.predict(imageFile);
        
        // Check if disease service also detected non-leaf
        if ((diseaseResult['isLeaf'] == false)) {
          print('⚠️ Disease service detected non-leaf image. Returning non-leaf result.');
          return {
            'success': true,
            'analysisType': 'non_leaf_image',
            'isLeaf': false,
            'leafConfidence': diseaseResult['leafConfidence'] ?? leafConfidence,
            'species': 'Non-Plant Image',
            'disease': 'Image Not Recognized',
            'speciesConfidence': 0.0,
            'diseaseConfidence': 95.0,
            'isUnknown': true,
            'analysisStatus': 'NON_LEAF',
            'displayTitle': 'Non-Plant Image Detected',
            'primaryMessage': 'All detection systems confirm this is not a plant leaf.',
            'secondaryMessage': 'Multiple validations identified non-plant characteristics.',
            'shouldShowDisease': false,
            'hasDiseaseData': false,
          };
        }
      } else {
        print('⚠️ Skipping disease detection - plant not confidently identified or not a leaf');
      }
      
      // STEP 3: Run severity and remediation analysis if disease is detected
      Map<String, dynamic>? severityResult;
      List<String> combinedRemediation = [];
      String finalSeverity = 'Unknown';
      
      if (diseaseResult != null && diseaseResult['isHealthy'] == false) {
        final diseaseName = diseaseResult['diseaseName'] ?? diseaseResult['diagnosis'] ?? 'Unknown Disease';
        final diseaseConfidence = diseaseResult['confidence'] != null 
            ? double.tryParse(diseaseResult['confidence'].toString()) ?? 0.0 
            : 0.0;
        
        print('⚡ Running severity analysis for $diseaseName...');
        severityResult = await _getSeverityAndRemediation(
          imageFile: imageFile,
          diseaseName: diseaseName,
          plantName: speciesName,
          confidence: diseaseConfidence,
          isHealthy: false,
        );
        
        if (severityResult != null) {
          finalSeverity = severityResult['severity']?.toString() ?? 'Unknown';
          
          // Combine remediations from disease and severity services
          final diseaseRemediation = _parseRemediation(diseaseResult['remediation'] ?? diseaseResult['treatment']);
          final severityRemediation = severityResult['remediation'] is List 
              ? List<String>.from(severityResult['remediation'])
              : [];
          
          // Merge remediations, removing duplicates
          final allRemediations = [...diseaseRemediation, ...severityRemediation];
          combinedRemediation = List<String>.from(allRemediations.toSet().toList()); // Remove duplicates
          
          // If no remediations, use fallback
          if (combinedRemediation.isEmpty) {
            combinedRemediation = severityResult['remediation'] ?? [
              'Consult with agricultural expert',
              'Apply appropriate treatment',
              'Remove infected plant parts',
            ];
          }
        }
      } else if (diseaseResult != null && diseaseResult['isHealthy'] == true) {
        // Healthy plant - get basic severity info
        severityResult = await _getSeverityAndRemediation(
          imageFile: imageFile,
          diseaseName: 'Healthy',
          plantName: speciesName,
          confidence: speciesConfidence,
          isHealthy: true,
        );
        finalSeverity = severityResult?['severity'] ?? 'None';
        combinedRemediation = severityResult?['remediation'] ?? [
          'Continue regular plant care',
          'Monitor for any changes',
          'Maintain optimal growing conditions',
        ];
      }
      
      // STEP 4: Determine final status
      final String analysisStatus;
      final String displayMessage;
      
      if (isSpeciesUnknown) {
        analysisStatus = 'UNKNOWN_PLANT';
        displayMessage = 'Plant species could not be identified with confidence. Try a clearer image.';
      } else if (speciesConfidence >= 0.8) {
        analysisStatus = 'HIGH_CONFIDENCE';
        displayMessage = 'Plant confidently identified as $speciesName';
      } else if (speciesConfidence >= 0.6) {
        analysisStatus = 'MEDIUM_CONFIDENCE';
        displayMessage = 'Plant identified as $speciesName';
      } else {
        analysisStatus = 'LOW_CONFIDENCE';
        displayMessage = 'Plant likely $speciesName, but low confidence';
      }
      
      // STEP 5: Prepare final result
      final bool hasDiseaseData = diseaseResult != null;
      final bool isHealthyPlant = diseaseResult?['isHealthy'] ?? true;
      final String diseaseName = diseaseResult?['diseaseName'] ?? diseaseResult?['diagnosis'];
      
      // Create base result
      Map<String, dynamic> result = {
        'success': true,
        'analysisType': 'combined_species_disease_severity',
        'isLeaf': true,
        'leafConfidence': leafConfidence,
        
        // Species data
        'species': speciesName,
        'speciesConfidence': speciesConfidence,
        'isUnknown': isSpeciesUnknown,
        'analysisStatus': analysisStatus,
        'speciesMessage': displayMessage,
        
        // Disease data (only if available)
        'disease': diseaseName,
        'healthStatus': isHealthyPlant ? 'Healthy' : 'Diseased',
        'diseaseConfidence': diseaseResult?['confidence'] != null 
            ? double.tryParse(diseaseResult!['confidence'].toString()) ?? 0.0 
            : 0.0,
        
        // Flags for UI
        'hasDiseaseData': hasDiseaseData,
        'shouldShowDisease': !isSpeciesUnknown && speciesConfidence >= 0.6,
        
        // Combined messages
        'displayTitle': isSpeciesUnknown ? 'Plant Not Identified' : 'Plant Analysis Complete',
        'primaryMessage': _getPrimaryMessage(isSpeciesUnknown, speciesName, speciesConfidence, diseaseResult, finalSeverity),
        'secondaryMessage': _getSecondaryMessage(isSpeciesUnknown, speciesConfidence, diseaseResult, finalSeverity),
        
        // Raw results for debugging
        '_rawSpecies': speciesResult,
        '_rawDisease': diseaseResult,
        '_leafAnalysis': leafAnalysis,
      };
      
      // Add severity and remediation data if available
      if (severityResult != null) {
        result.addAll({
          'severity': finalSeverity,
          'severityLevel': severityResult['severityLevel'] ?? finalSeverity,
          'severityConfidence': severityResult['severityConfidence'] ?? severityResult['confidence'] ?? 0.0,
          'remediation': combinedRemediation,
          'severityEffect': severityResult['effect'],
          'severityColorCode': severityResult['colorCode'],
          'severityDescription': severityResult['description'],
          'severityAction': severityResult['action'],
          'hasSeverityData': true,
        });
      } else {
        // Fallback severity
        result.addAll({
          'severity': finalSeverity,
          'severityLevel': finalSeverity,
          'severityConfidence': 0.0,
          'remediation': combinedRemediation.isNotEmpty ? combinedRemediation : _getFallbackRemediations(isHealthyPlant),
          'hasSeverityData': false,
        });
      }
      
      // Add original disease remediation if not already included
      if (diseaseResult != null && diseaseResult['remediation'] != null) {
        final originalRemediation = _parseRemediation(diseaseResult['remediation']);
        if (originalRemediation.isNotEmpty) {
          result['originalRemediation'] = originalRemediation;
        }
      }
      
      print('✅ Analysis complete with severity: $finalSeverity');
      return result;
      
    } catch (e) {
      print('❌ Plant analysis failed: $e');
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
  
  // Helper method to parse remediation from various formats
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
  
  // Get fallback remediations
  List<String> _getFallbackRemediations(bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue regular plant care',
        'Maintain proper watering schedule',
        'Ensure adequate sunlight exposure',
        'Monitor for any changes in plant health'
      ];
    } else {
      return [
        'Apply appropriate fungicide if fungal disease is suspected',
        'Remove and destroy infected plant parts',
        'Improve air circulation around the plant',
        'Consult with agricultural expert for precise treatment'
      ];
    }
  }
  
  String _getPrimaryMessage(bool isUnknown, String species, double confidence, 
                           Map<String, dynamic>? disease, String severity) {
    if (isUnknown) {
      return 'Plant species not recognized';
    }
    
    final confidencePercent = (confidence * 100).toStringAsFixed(1);
    
    if (disease == null || (disease['isHealthy'] ?? true)) {
      return '$species identified with $confidencePercent% confidence';
    } else {
      final diseaseName = disease['diseaseName'] ?? 'disease';
      return '$species with $diseaseName (Severity: $severity)';
    }
  }
  
  String _getSecondaryMessage(bool isUnknown, double confidence, 
                            Map<String, dynamic>? disease, String severity) {
    if (isUnknown) {
      if (confidence < 0.3) return 'Very low confidence - try a clearer image';
      if (confidence < 0.5) return 'Low confidence - image may be unclear';
      return 'Unable to identify plant species';
    }
    
    if (disease == null) {
      return 'Disease detection skipped (plant not confidently identified)';
    }
    
    if (disease['isHealthy'] ?? true) {
      return 'No signs of disease detected';
    } else {
      return 'Severity: $severity - Follow recommended treatment';
    }
  }
  
  // Dispose services when done
  void dispose() {
    try {
      _severityService.dispose();
      print('✅ PlantAnalysisService disposed');
    } catch (e) {
      print('⚠️ Error disposing services: $e');
    }
  }
}