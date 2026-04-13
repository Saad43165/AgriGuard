import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class SeverityResult {
  final String severity;
  final String severityLevel;
  final double confidence;
  final String remediation;
  final String effect;
  final String colorCode;
  final String description;
  final String action;

  SeverityResult({
    required this.severity,
    required this.severityLevel,
    required this.confidence,
    required this.remediation,
    required this.effect,
    required this.colorCode,
    required this.description,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'severity': severity,
      'severityLevel': severityLevel,
      'confidence': confidence,
      'remediation': remediation,
      'effect': effect,
      'colorCode': colorCode,
      'description': description,
      'action': action,
    };
  }
}

class SeverityIdService {
  // Model and metadata
  late Interpreter _interpreter;
  Map<String, dynamic> _modelInfo = {};
  Map<String, dynamic> _remediationData = {};
  final List<String> _severityLevels = ['None', 'Low', 'Medium', 'High', 'Critical'];
  bool _isInitialized = false;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadModelInfo();
      await _loadRemediationData();
      await _loadModel();
      _isInitialized = true;
      debugPrint('✅ SeverityIdService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing SeverityIdService: $e');
      rethrow;
    }
  }

  // Load model_info.json
  Future<void> _loadModelInfo() async {
    try {
      final String modelInfoString = await rootBundle.loadString('assets/models/model_info.json');
      _modelInfo = json.decode(modelInfoString);
      debugPrint('✅ Model info loaded');
    } catch (e) {
      debugPrint('❌ Error loading model info: $e');
      _modelInfo = {
        'severity_levels': {
          '0_None': {'name': 'None', 'color_code': '#4CAF50', 'description': 'No disease detected', 'action': 'Continue regular care'},
          '1_Low': {'name': 'Low', 'color_code': '#8BC34A', 'description': 'Mild infection, early stage', 'action': 'Monitor and apply preventive measures'},
          '2_Medium': {'name': 'Medium', 'color_code': '#FFC107', 'description': 'Moderate infection, spreading', 'action': 'Apply treatment and isolate plant'},
          '3_High': {'name': 'High', 'color_code': '#FF9800', 'description': 'Severe infection, advanced stage', 'action': 'Immediate treatment required'},
          '4_Critical': {'name': 'Critical', 'color_code': '#F44336', 'description': 'Critical condition, plant at risk', 'action': 'Emergency measures needed'}
        }
      };
    }
  }

  // Load remediation.json
  Future<void> _loadRemediationData() async {
    try {
      final String remediationString = await rootBundle.loadString('assets/data/remediation.json');
      _remediationData = json.decode(remediationString);
      debugPrint('✅ Remediation data loaded');
    } catch (e) {
      debugPrint('❌ Error loading remediation data: $e');
      _remediationData = {
        'remediations': {},
        'general_guidelines': {
          'severity_none': 'Continue regular plant care and monitoring.',
          'severity_low': 'Apply preventive measures and monitor closely.',
          'severity_medium': 'Begin treatment and consider plant isolation.',
          'severity_high': 'Apply intensive treatment and seek expert advice.',
          'severity_critical': 'Take immediate action to save the plant.'
        },
        'important_notes': {
          'note1': 'Always test treatments on a small area first.',
          'note2': 'Consult with agricultural experts for severe cases.',
          'note3': 'Environmental factors may affect treatment effectiveness.'
        }
      };
    }
  }

  // Load TFLite model
  Future<void> _loadModel() async {
    try {
      // Try to load the model with different possible names
        _interpreter = await Interpreter.fromAsset('assets/models/severity_dynamic_quant.tflite');
     
      
      // Get input and output tensors info
      final inputTensors = _interpreter.getInputTensors();
      final outputTensors = _interpreter.getOutputTensors();
      
      debugPrint('✅ Model loaded successfully');
      debugPrint('📊 Input shape: ${inputTensors[0].shape}');
      debugPrint('📊 Output shape: ${outputTensors[0].shape}');
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
      throw Exception('Failed to load severity model: $e');
    }
  }

  // Convert base64 to Uint8List
  Uint8List _base64ToBytes(String base64String) {
    try {
      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      
      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('❌ Error decoding base64: $e');
      throw Exception('Invalid base64 image data');
    }
  }

  // Preprocess image for MobileNetV3
  Future<Float32List> _preprocessImage(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to 224x224
      final resized = img.copyResize(image, width: 224, height: 224);
      
      // Convert to float32 and normalize: (pixel / 127.5) - 1.0
      final input = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();
          
          // Normalize to [-1, 1]
          input[pixelIndex++] = (r / 127.5) - 1.0;
          input[pixelIndex++] = (g / 127.5) - 1.0;
          input[pixelIndex++] = (b / 127.5) - 1.0;
        }
      }
      
      return input;
    } catch (e) {
      debugPrint('❌ Error preprocessing image: $e');
      throw Exception('Image preprocessing failed: $e');
    }
  }

  // Alternative preprocessing for file
  Future<Float32List> _preprocessImageFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return _preprocessImage(bytes);
  }

  List<List<List<List<double>>>> _to4dFloatInput(Float32List input) {
    const h = 224, w = 224, c = 3;
    var idx = 0;
    return List.generate(
      1,
      (_) => List.generate(
        h,
        (_) => List.generate(
          w,
          (_) => List.generate(c, (_) => input[idx++]),
        ),
      ),
    );
  }

  // Run inference on image
  Future<List<double>> _runInference(Float32List input) async {
    try {
      // The model expects a 4D tensor: [1, 224, 224, 3]
      // Note: the reshape helper used here only supports 2D reshaping,
      // so we build a nested 4D structure.
      final inputTensor = _to4dFloatInput(input);

      // Prepare output tensor
      final output = List.filled(1 * 5, 0.0).reshape([1, 5]);
      
      // Run inference
      _interpreter.run(inputTensor, output);
      
      // Apply softmax to get probabilities
      final probabilities = _softmax(output[0]);
      
      debugPrint('📈 Inference probabilities: ${probabilities.map((p) => p.toStringAsFixed(4)).toList()}');
      return probabilities;
    } catch (e) {
      debugPrint('❌ Error running inference: $e');
      throw Exception('Inference failed: $e');
    }
  }

  // Softmax function
  List<double> _softmax(List<double> logits) {
    try {
      final maxLogit = logits.reduce((a, b) => a > b ? a : b);
      final exps = logits.map((e) => math.exp(e - maxLogit)).toList();
      final sumExps = exps.reduce((a, b) => a + b);
      return exps.map((e) => e / sumExps).toList();
    } catch (e) {
      debugPrint('❌ Error in softmax: $e');
      // Return uniform distribution as fallback
      return List.filled(logits.length, 1.0 / logits.length);
    }
  }

  // Exponential function removed — use math.exp directly

  // Get remediation info based on disease and severity
  Map<String, dynamic> _getRemediationInfo(String diseaseKey, String severityLevel) {
    try {
      final remediationsRaw = _remediationData['remediations'];
      final remediations = remediationsRaw is Map<String, dynamic>
          ? remediationsRaw
          : <String, dynamic>{};
      
      if (!remediations.containsKey(diseaseKey)) {
        // Fallback: use general guidelines
        final ggRaw = _remediationData['general_guidelines'];
        final generalGuidelines =
            ggRaw is Map<String, dynamic> ? ggRaw : <String, dynamic>{};
        final guidelineKey = 'severity_${severityLevel.toLowerCase()}';
        
        return {
          'remediation': generalGuidelines[guidelineKey] ?? 'Apply appropriate treatment for plant disease. Consult an agricultural expert for specific recommendations.',
          'effect': 'General treatment guidelines for $severityLevel severity level.'
        };
      }
      
      final diseaseRaw = remediations[diseaseKey];
      final diseaseData = diseaseRaw is Map<String, dynamic>
          ? diseaseRaw
          : <String, dynamic>{};
      
      if (!diseaseData.containsKey(severityLevel)) {
        // Fallback to Medium severity if specific level not found
        final fallbackSeverity = diseaseData['Medium'] ?? diseaseData['medium'];
        if (fallbackSeverity is Map) {
          return {
            'remediation': fallbackSeverity['remediation'] ?? 'Apply standard treatment for this disease.',
            'effect': fallbackSeverity['effect'] ?? 'Treatment effect varies based on application.'
          };
        }
        
        // Final fallback to general guidelines
        final ggRaw = _remediationData['general_guidelines'];
        final generalGuidelines =
            ggRaw is Map<String, dynamic> ? ggRaw : <String, dynamic>{};
        final guidelineKey = 'severity_${severityLevel.toLowerCase()}';
        
        return {
          'remediation': generalGuidelines[guidelineKey] ?? 'Apply appropriate treatment based on disease severity.',
          'effect': 'Follow general plant care guidelines for disease management.'
        };
      }
      
      final sevRaw = diseaseData[severityLevel];
      final severityData = sevRaw is Map<String, dynamic>
          ? sevRaw
          : <String, dynamic>{};
      return {
        'remediation': severityData['remediation'] ?? 'Treatment information not available.',
        'effect': severityData['effect'] ?? 'Effect information not available.'
      };
    } catch (e) {
      debugPrint('❌ Error getting remediation info: $e');
      return {
        'remediation': 'Consult with an agricultural expert for appropriate treatment.',
        'effect': 'Expert consultation recommended for accurate treatment planning.'
      };
    }
  }

  // Get severity metadata from model_info.json
  Map<String, dynamic> _getSeverityMetadata(int severityIndex) {
    try {
      if (severityIndex < 0 || severityIndex >= _severityLevels.length) {
        severityIndex = 2; // Default to Medium
      }
      
      final severityKey = '${severityIndex}_${_severityLevels[severityIndex]}';
      final severityInfo = _modelInfo['severity_levels'][severityKey] as Map<String, dynamic>?;
      
      if (severityInfo == null) {
        // Default fallback values
        return {
          'name': _severityLevels[severityIndex],
          'colorCode': '#FFC107', // Yellow for medium
          'description': '${_severityLevels[severityIndex]} severity level disease',
          'action': 'Take appropriate measures based on severity level'
        };
      }
      
      return {
        'name': severityInfo['name'] ?? _severityLevels[severityIndex],
        'colorCode': severityInfo['color_code'] ?? '#FFC107',
        'description': severityInfo['description'] ?? '',
        'action': severityInfo['action'] ?? ''
      };
    } catch (e) {
      debugPrint('❌ Error getting severity metadata: $e');
      return {
        'name': _severityLevels[severityIndex],
        'colorCode': '#FFC107',
        'description': 'Disease severity assessment',
        'action': 'Consult expert for treatment'
      };
    }
  }

  // Main function to assess severity and get remediation
  Future<SeverityResult> assessSeverity(
    File imageFile,
    String diseaseKey, // e.g., "Apple___Apple_scab"
  ) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      debugPrint('🔍 Assessing severity for disease: $diseaseKey');
      
      // Preprocess image
      final input = await _preprocessImageFile(imageFile);
      
      // Run inference
      final probabilities = await _runInference(input);
      
      // Get highest probability index
      final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      final confidence = probabilities[maxIndex];
      
      // Get severity level
      final severityLevel = _severityLevels[maxIndex];
      
      // Get remediation info
      final remediationInfo = _getRemediationInfo(diseaseKey, severityLevel);
      
      // Get severity metadata
      final severityMetadata = _getSeverityMetadata(maxIndex);
      
      debugPrint('✅ Severity assessment complete: $severityLevel (${(confidence * 100).toStringAsFixed(1)}%)');
      
      return SeverityResult(
        severity: severityMetadata['name'],
        severityLevel: severityLevel,
        confidence: confidence,
        remediation: remediationInfo['remediation'],
        effect: remediationInfo['effect'],
        colorCode: severityMetadata['colorCode'],
        description: severityMetadata['description'],
        action: severityMetadata['action'],
      );
    } catch (e) {
      debugPrint('❌ Error in severity assessment: $e');
      // Return a default result with fallback values
      return SeverityResult(
        severity: 'Medium',
        severityLevel: 'Medium',
        confidence: 0.5,
        remediation: 'Unable to assess severity. Please consult an agricultural expert.',
        effect: 'Expert consultation required for accurate assessment.',
        colorCode: '#FFC107',
        description: 'Severity assessment could not be completed',
        action: 'Consult with plant disease expert',
      );
    }
  }

  // NEW METHOD: Get severity and remediation for results screen
  Future<Map<String, dynamic>?> getSeverityAndRemediation({
    required String diseaseName,
    required String plantName,
    required double confidence,
    String? imagePath,
    String? imageBase64,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      debugPrint('🎯 Getting severity and remediation for: $plantName - $diseaseName');
      
      // Validate inputs
      if (diseaseName.isEmpty || diseaseName.toLowerCase() == 'healthy') {
        debugPrint('⚠️ Plant is healthy, no severity assessment needed');
        return {
          'severity': 'None',
          'remediation': ['Continue regular plant care', 'Monitor for any changes'],
        };
      }
      
      // Handle non-plant images
      if (diseaseName == 'Image Not Recognized' || plantName == 'Non-Plant Image') {
        return {
          'severity': 'N/A',
          'remediation': ['Please upload a clear photo of a plant leaf'],
        };
      }
      
      // Get image bytes
      Uint8List? imageBytes;
      
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          imageBytes = _base64ToBytes(imageBase64);
        } catch (e) {
          debugPrint('⚠️ Failed to decode base64: $e');
        }
      }
      
      if (imageBytes == null && imagePath != null) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('⚠️ Failed to read image file: $e');
        }
      }
      
      // If no image available, use confidence-based fallback
      if (imageBytes == null) {
        debugPrint('⚠️ No image available for severity analysis, using confidence-based estimation');
        return _getFallbackSeverity(diseaseName, plantName, confidence);
      }
      
      // Run inference directly on imageBytes — no temp file needed.
      final input = await _preprocessImage(imageBytes);
      final probabilities = await _runInference(input);

      final maxIndex = probabilities.indexOf(
          probabilities.reduce((a, b) => a > b ? a : b));
      final inferredConfidence = probabilities[maxIndex];
      final severityLevel = _severityLevels[maxIndex];

      // Construct disease key
      final diseaseKey =
          '${plantName.replaceAll(' ', '_')}___${diseaseName.replaceAll(' ', '_').toLowerCase()}';

      final remediationInfo = _getRemediationInfo(diseaseKey, severityLevel);
      final severityMetadata = _getSeverityMetadata(maxIndex);

      List<String> remediationList = [];
      final remStr = remediationInfo['remediation'] as String? ?? '';
      if (remStr.isNotEmpty) {
        remediationList = remStr
            .split(RegExp(r'[.,;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (remediationList.isEmpty) {
        remediationList = _getGeneralRemediations(severityLevel);
      }

      return {
        'severity': severityMetadata['name'],
        'severityLevel': severityLevel,
        'confidence': inferredConfidence,
        'remediation': remediationList,
        'effect': remediationInfo['effect'],
        'colorCode': severityMetadata['colorCode'],
        'description': severityMetadata['description'],
        'action': severityMetadata['action'],
      };
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getSeverityAndRemediation: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return fallback result
      return _getFallbackSeverity(diseaseName, plantName, confidence);
    }
  }

  // Get fallback severity based on confidence
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
    };
  }

  // Get general remediations based on severity level
  List<String> _getGeneralRemediations(String severityLevel) {
    switch (severityLevel.toLowerCase()) {
      case 'critical':
        return [
          'Immediate treatment required',
          'Remove severely infected parts',
          'Apply intensive care',
          'Consult expert immediately'
        ];
      case 'high':
        return [
          'Apply strong treatment',
          'Isolate plant',
          'Remove infected leaves',
          'Monitor daily'
        ];
      case 'medium':
        return [
          'Apply standard treatment',
          'Improve growing conditions',
          'Monitor regularly',
          'Consider preventive measures'
        ];
      case 'low':
        return [
          'Monitor plant health',
          'Apply mild treatment',
          'Improve plant care',
          'Watch for progression'
        ];
      default: // 'None'
        return [
          'Continue regular care',
          'Maintain optimal conditions',
          'Monitor for changes',
          'Apply preventive care'
        ];
    }
  }

  // Get general guidelines for a severity level
  String getGeneralGuideline(String severityLevel) {
    try {
      final generalGuidelines = _remediationData['general_guidelines'] as Map<String, dynamic>;
      final guidelineKey = 'severity_${severityLevel.toLowerCase()}';
      return generalGuidelines[guidelineKey] ?? 'No guideline available.';
    } catch (e) {
      return 'Error retrieving guidelines.';
    }
  }

  // Get important notes
  Map<String, String> getImportantNotes() {
    try {
      final notes = _remediationData['important_notes'] as Map<String, dynamic>;
      return Map<String, String>.from(notes);
    } catch (e) {
      return {'error': 'Could not load important notes'};
    }
  }

  // Check if service is ready
  bool isReady() {
    return _isInitialized;
  }

  // Dispose interpreter when done
  void dispose() {
    try {
      _interpreter.close();
      _isInitialized = false;
      debugPrint('✅ SeverityIdService disposed');
    } catch (e) {
      debugPrint('⚠️ Error disposing interpreter: $e');
    }
  }
}

// Extension for reshaping lists
extension ReshapeList on List<double> {
  List<List<double>> reshape(List<int> shape) {
    if (shape.length != 2) {
      throw ArgumentError('Only 2D reshaping is supported');
    }
    
    final rows = shape[0];
    final cols = shape[1];
    
    if (length != rows * cols) {
      throw ArgumentError('List length does not match shape');
    }
    
    final result = List.generate(rows, (_) => List<double>.filled(cols, 0.0));
    
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        result[i][j] = this[i * cols + j];
      }
    }
    
    return result;
  }
}