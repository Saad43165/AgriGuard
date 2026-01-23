import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class DiseaseIdService {
  static const String _modelPath = 'assets/models/plant_disease_dynamic_quant.tflite';
  static const String _labelsPath = 'assets/models/disease_labels.txt';

  // Configuration constants
  static const double _minConfidenceThreshold = 0.5; // Minimum 40% confidence
  static const double _lowConfidenceThreshold = 0.6; // Below this, mark as unknown
  static const int _minImageSize = 100; // Minimum image dimension in pixels
  static const int _minImageBytes = 10240; // Minimum 10KB file size

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;

  Future<void> loadModel() async {
    if (_isModelLoaded || _isLoading) return;

    _isLoading = true;
    try {
      debugPrint('🌱 Loading Disease Detection Model...');

      // Load labels
      await _loadLabels();
      debugPrint('✅ Labels loaded: ${_labels.length} classes');

      // Load model
      final options = InterpreterOptions();

      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: options,
      );

      // Get model details
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('📊 Model loaded successfully');
      debugPrint('   Input shape: $inputShape');
      debugPrint('   Output shape: $outputShape');
      debugPrint('   Labels count: ${_labels.length}');

      _isModelLoaded = true;
    } catch (e) {
      debugPrint('❌ Failed to load disease model: $e');
      _isModelLoaded = false;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(_labelsPath);
      _labels = labelData.split('\n').where((label) => label.trim().isNotEmpty).toList();
    } catch (e) {
      debugPrint('❌ Failed to load labels: $e');
      _labels = [];
    }
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      debugPrint('🔍 Running disease detection...');

      // Check image quality before processing
      final imageQualityCheck = await _checkImageQuality(imageFile);
      if (!imageQualityCheck['isGoodQuality']) {
        debugPrint('⚠️ Poor image quality detected: ${imageQualityCheck['reason']}');

        return {
          'success': true,
          'plantName': 'Image Quality Issue',
          'diseaseName': 'Unable to Analyze',
          'confidence': '0',
          'severity': 'Unknown',
          'cause': 'Poor image quality affecting analysis',
          'isHealthy': false,
          'symptoms': ['Image may be blurry, too small, or poor quality'],
          'remediation': [
            'Please take a clearer photo with good lighting',
            'Focus on the affected leaves',
            'Ensure the image is not blurry'
          ],
          'precautions': ['Regular monitoring recommended'],
          'allPredictions': [],
          'rawLabel': 'image_quality_issue',
          'inferenceTime': 0,
          'imageQualityIssue': true,
          'qualityReason': imageQualityCheck['reason'],
        };
      }

      // Preprocess image and get float array
      final inputArray = await _preprocessImageToFloatArray(imageFile);

      // Prepare output tensor
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('🔍 Output shape from model: $outputShape');

      // Handle both 1D and 2D output shapes
      if (outputShape.length == 2) {
        // Model returns [1, 31] - need to handle as 2D
        debugPrint('📊 Model returns 2D output, reshaping...');

        // Create a 2D array
        final output2D = List<List<double>>.filled(
            outputShape[0],
            List<double>.filled(outputShape[1], 0.0)
        );

        // Run inference with 2D output
        final stopwatch = Stopwatch()..start();
        _interpreter!.run(inputArray, output2D);
        stopwatch.stop();

        debugPrint('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

        // Flatten to 1D array for processing
        final output = output2D.expand((row) => row).toList();

        // Process results
        final result = _processOutput(output);
        result['inferenceTime'] = stopwatch.elapsedMilliseconds;

        debugPrint('✅ Disease detection completed');
        debugPrint('   Disease: ${result['diseaseName']}');
        debugPrint('   Confidence: ${result['confidence']}%');
        debugPrint('   Severity: ${result['severity']}');

        return result;
      } else {
        // Original 1D handling for backward compatibility
        final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
            .cast<double>();

        final stopwatch = Stopwatch()..start();
        _interpreter!.run(inputArray, output);
        stopwatch.stop();

        debugPrint('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

        final result = _processOutput(output);
        result['inferenceTime'] = stopwatch.elapsedMilliseconds;

        debugPrint('✅ Disease detection completed');
        debugPrint('   Disease: ${result['diseaseName']}');
        debugPrint('   Confidence: ${result['confidence']}%');
        debugPrint('   Severity: ${result['severity']}');

        return result;
      }
    } catch (e) {
      debugPrint('❌ Disease prediction error: $e');
      return _createFallbackResult(e.toString());
    }
  }

  Future<Map<String, dynamic>> _checkImageQuality(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Check file size
      if (imageBytes.length < _minImageBytes) {
        return {
          'isGoodQuality': false,
          'reason': 'Image file too small (${imageBytes.length} bytes < $_minImageBytes bytes)'
        };
      }

      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        return {
          'isGoodQuality': false,
          'reason': 'Failed to decode image'
        };
      }

      // Check image dimensions
      if (originalImage.width < _minImageSize || originalImage.height < _minImageSize) {
        return {
          'isGoodQuality': false,
          'reason': 'Image dimensions too small (${originalImage.width}x${originalImage.height} < ${_minImageSize}x$_minImageSize)'
        };
      }

      // Check if image is mostly one color (could be blurry or poor quality)
      final colorVariation = _calculateColorVariation(originalImage);
      if (colorVariation < 10.0) { // Low color variation might indicate blurry image
        return {
          'isGoodQuality': false,
          'reason': 'Low color variation detected (image may be blurry)'
        };
      }

      return {
        'isGoodQuality': true,
        'reason': 'Image quality acceptable'
      };
    } catch (e) {
      debugPrint('❌ Error checking image quality: $e');
      return {
        'isGoodQuality': false,
        'reason': 'Error analyzing image quality'
      };
    }
  }

  double _calculateColorVariation(img.Image image) {
    // Simple color variation calculation
    int totalPixels = image.width * image.height;
    if (totalPixels == 0) return 0.0;

    // Sample pixels for efficiency
    int sampleCount = 100;
    List<int> redValues = [];
    List<int> greenValues = [];
    List<int> blueValues = [];

    for (int i = 0; i < sampleCount; i++) {
      int x = (i * image.width ~/ sampleCount) % image.width;
      int y = (i * image.height ~/ sampleCount) % image.height;

      if (x < image.width && y < image.height) {
        final pixel = image.getPixel(x, y);
        redValues.add(pixel.r.toInt());
        greenValues.add(pixel.g.toInt());
        blueValues.add(pixel.b.toInt());
      }
    }

    // Calculate standard deviation of color values
    double stdDev(List<int> values) {
      if (values.isEmpty) return 0.0;
      double mean = values.reduce((a, b) => a + b) / values.length;
      double variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
      return sqrt(variance);
    }

    final redStdDev = stdDev(redValues);
    final greenStdDev = stdDev(greenValues);
    final blueStdDev = stdDev(blueValues);

    return (redStdDev + greenStdDev + blueStdDev) / 3.0;
  }

  Future<List<List<List<List<double>>>>> _preprocessImageToFloatArray(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Get model input size
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final targetHeight = inputShape[1]; // Usually 224 or 256
      final targetWidth = inputShape[2];

      debugPrint('📏 Target size: $targetWidth x $targetHeight');

      // Resize image
      final resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
      );

      // Convert to RGB (remove alpha channel if present)
      img.Image rgbImage;
      if (resizedImage.numChannels == 1) {
        // Convert grayscale to RGB
        rgbImage = img.Image(width: resizedImage.width, height: resizedImage.height, numChannels: 3);
        for (int y = 0; y < resizedImage.height; y++) {
          for (int x = 0; x < resizedImage.width; x++) {
            final pixel = resizedImage.getPixel(x, y);
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();
            rgbImage.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (resizedImage.numChannels == 4) {
        // Remove alpha channel
        rgbImage = img.Image(width: resizedImage.width, height: resizedImage.height, numChannels: 3);
        for (int y = 0; y < resizedImage.height; y++) {
          for (int x = 0; x < resizedImage.width; x++) {
            final pixel = resizedImage.getPixel(x, y);
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();
            rgbImage.setPixelRgb(x, y, r, g, b);
          }
        }
      } else {
        rgbImage = resizedImage;
      }

      // Create 4D array: [1, height, width, 3]
      final List<List<List<List<double>>>> array4d =
      List.generate(1, (_) => List.generate(
          targetHeight, (_) => List.generate(
          targetWidth, (_) => List<double>.filled(3, 0.0))));

      // Fill array with normalized pixel values
      for (int y = 0; y < targetHeight; y++) {
        for (int x = 0; x < targetWidth; x++) {
          final pixel = rgbImage.getPixel(x, y);

          // Normalize to [-1, 1] range (common for TensorFlow models)
          array4d[0][y][x][0] = (pixel.r / 127.5) - 1.0;   // R
          array4d[0][y][x][1] = (pixel.g / 127.5) - 1.0; // G
          array4d[0][y][x][2] = (pixel.b / 127.5) - 1.0;  // B
        }
      }

      debugPrint('✅ Image preprocessed successfully');
      return array4d;
    } catch (e) {
      debugPrint('❌ Image preprocessing error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _processOutput(List<double> output) {
    try {
      // Find top prediction
      double maxConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < output.length; i++) {
        if (output[i] > maxConfidence) {
          maxConfidence = output[i];
          maxIndex = i;
        }
      }

      // Convert confidence to percentage
      final confidencePercent = (maxConfidence * 100).clamp(0.0, 100.0);

      // Get disease label
      String diseaseLabel = 'Unknown Disease';
      if (_labels.isNotEmpty && maxIndex < _labels.length) {
        diseaseLabel = _labels[maxIndex];
      }

      // Parse disease information from label
      final diseaseInfo = _parseDiseaseLabel(diseaseLabel);
      final diseaseName = diseaseInfo['diseaseName'];
      final plantName = diseaseInfo['plantName'];
      final isHealthy = diseaseInfo['isHealthy'];

      // Check confidence thresholds
      if (confidencePercent < _lowConfidenceThreshold) {
        debugPrint('⚠️ Very low confidence ($confidencePercent% < $_lowConfidenceThreshold%)');

        return {
          'success': true,
          'plantName': 'Unable to Determine',
          'diseaseName': 'Unable to Determine',
          'confidence': confidencePercent.toStringAsFixed(1),
          'severity': 'Unknown',
          'cause': 'Low confidence prediction',
          'isHealthy': false,
          'symptoms': ['AI model is not confident about this prediction'],
          'remediation': [
            'Please try again with a clearer photo',
            'Focus on affected leaves with good lighting',
            'Consult agricultural expert if problem persists'
          ],
          'precautions': ['Regular plant monitoring recommended'],
          'allPredictions': [],
          'rawLabel': diseaseLabel,
          'lowConfidence': true,
          'confidenceBelowThreshold': true,
        };
      }

      // Check plant-disease compatibility
      if (!_isValidPlantDiseaseCombo(plantName, diseaseName) && !isHealthy) {
        debugPrint('⚠️ Invalid plant-disease combination: $plantName with $diseaseName');

        return {
          'success': true,
          'plantName': plantName,
          'diseaseName': 'Possible Disease',
          'confidence': confidencePercent.toStringAsFixed(1),
          'severity': 'Unknown',
          'cause': 'Unusual plant-disease combination detected',
          'isHealthy': false,
          'symptoms': ['Unusual symptoms detected for this plant type'],
          'remediation': [
            'This disease is unusual for $plantName plants',
            'Consult with agricultural expert for accurate diagnosis',
            'Take multiple photos from different angles'
          ],
          'precautions': ['Isolate plant to prevent potential spread'],
          'allPredictions': [],
          'rawLabel': diseaseLabel,
          'unusualCombination': true,
        };
      }

      // Adjust confidence for healthy plants (give them a boost)
      double adjustedConfidence = confidencePercent;
      if (isHealthy && confidencePercent < 60) {
        adjustedConfidence = 75.0; // Give healthy plants decent confidence
        debugPrint('✅ Boosting confidence for healthy plant to $adjustedConfidence%');
      }

      // Determine severity
      // final severity = _determineSeverity(diseaseName, adjustedConfidence);

      // Get treatment recommendations
      final remediation = _getRemediation(diseaseName, plantName, isHealthy);
      final precautions = _getPrecautions(diseaseName, plantName);
      final cause = _getCause(diseaseName);

      // Get top 3 predictions for debugging
      final predictions = <Map<String, dynamic>>[];
      for (int i = 0; i < output.length; i++) {
        predictions.add({
          'label': i < _labels.length ? _labels[i] : 'Unknown',
          'confidence': (output[i] * 100).toStringAsFixed(2),
        });
      }

      // Sort by confidence
      predictions.sort((a, b) => double.parse(b['confidence']).compareTo(double.parse(a['confidence'])));
      final topPredictions = predictions.take(3).toList();

      debugPrint('📊 Top 3 predictions:');
      for (var pred in topPredictions) {
        debugPrint('  - ${pred['label']}: ${pred['confidence']}%');
      }

      return {
        'success': true,
        'plantName': plantName,
        'diseaseName': diseaseName,
        'confidence': adjustedConfidence.toStringAsFixed(1),
        // 'severity': severity,
        'cause': cause,
        'isHealthy': isHealthy,
        'symptoms': _getSymptoms(diseaseName),
        'remediation': remediation,
        'precautions': precautions,
        'allPredictions': topPredictions,
        'rawLabel': diseaseLabel,
        'originalConfidence': confidencePercent.toStringAsFixed(1),
        'confidenceAdjusted': isHealthy && confidencePercent < 60,
      };
    } catch (e) {
      debugPrint('❌ Output processing error: $e');
      return _createFallbackResult('Output processing failed');
    }
  }

  bool _isValidPlantDiseaseCombo(String plantName, String diseaseName) {
    // ALLOW ALL HEALTHY PLANTS
    if (diseaseName.toLowerCase() == 'healthy') {
      debugPrint('✅ All plants can be healthy - allowing $plantName to be healthy');
      return true;
    }

    // Standardize plant names from dataset to match validation
    final Map<String, String> plantNameMapping = {
      'Bell_pepper': 'Pepper',
      'Corn_(Maize)': 'Corn',
      'Corn': 'Corn',  // Just in case
      'Maize': 'Corn',
    };

    // Use mapped name or original
    final standardizedPlantName = plantNameMapping[plantName] ?? plantName;

    // Define ALL possible combinations based on YOUR DATASET
    final Map<String, List<String>> validCombinations = {
      'Apple': ['Apple Scab', 'Black Rot', 'Cedar Apple Rust'],
      'Bell_pepper': ['Bacterial Spot'],
      'Pepper': ['Bacterial Spot'],  // Alias
      'Cherry': ['Powdery Mildew'],
      'Corn': ['Cercospora Leaf Spot', 'Common Rust', 'Northern Leaf Blight'],
      'Grape': ['Black Rot', 'Esca', 'Leaf Blight', 'Black Measles'],
      'Peach': ['Bacterial Spot'],
      'Potato': ['Early Blight', 'Late Blight'],
      'Soybean': ['Bacterial Blight'],
      'Strawberry': ['Leaf Scorch'],
      'Tomato': [
        'Bacterial Spot',
        'Early Blight',
        'Late Blight',
        'Septoria Leaf Spot',  // WAS MISSING
        'Yellow Leaf Curl Virus'  // WAS MISSING
      ],
      'Wheat': ['Stripe Rust'],
    };

    // If plant not in list, allow any disease (flexibility)
    if (!validCombinations.containsKey(standardizedPlantName)) {
      debugPrint('⚠️ Plant "$plantName" (std: $standardizedPlantName) not in validation list - allowing any disease');
      return true;
    }

    // Check if disease is valid for this plant
    final isValid = validCombinations[standardizedPlantName]!.any((disease) =>
        diseaseName.toLowerCase().contains(disease.toLowerCase()));

    if (!isValid) {
      debugPrint('❌ Invalid combination: $plantName cannot have $diseaseName');
      debugPrint('   Valid diseases for $standardizedPlantName: ${validCombinations[standardizedPlantName]}');
    } else {
      debugPrint('✅ Valid combination: $plantName with $diseaseName');
    }

    return isValid;
  }
  Map<String, dynamic> _parseDiseaseLabel(String label) {
    try {
      debugPrint('🔍 Parsing disease label: "$label"');

      // Format: "Plant___Disease" or "Plant___healthy"
      final parts = label.split('___');

      if (parts.length >= 2) {
        String plantName = parts[0].replaceAll('_', ' ').trim();
        final diseasePart = parts[1].replaceAll('_', ' ').trim();

        // Special handling for Bell_pepper -> Bell Pepper
        if (plantName.toLowerCase() == 'bell pepper') {
          plantName = 'Bell Pepper';
        }

        // Check if it's truly "healthy" or if there's an actual disease
        final isHealthy = diseasePart.toLowerCase() == 'healthy' ||
            diseasePart.toLowerCase().contains('healthy');

        String diseaseName;

        if (isHealthy) {
          diseaseName = 'Healthy';
        } else {
          // It's an actual disease name, keep it as-is
          diseaseName = diseasePart;

          // Format disease name for better readability
          diseaseName = diseaseName.split(' ')
              .map((word) {
            if (word.isNotEmpty) {
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            }
            return word;
          })
              .join(' ');
        }

        debugPrint('📋 Parsed: Plant="$plantName", Disease="$diseaseName", Healthy=$isHealthy');

        return {
          'plantName': plantName,
          'diseaseName': diseaseName,
          'isHealthy': isHealthy,
          'rawLabel': label, // Keep original label for reference
        };
      }

      debugPrint('⚠️ Could not parse label format: "$label"');

      return {
        'plantName': 'Unknown Plant',
        'diseaseName': 'Unknown Disease',
        'isHealthy': false,
        'rawLabel': label,
      };
    } catch (e) {
      debugPrint('❌ Error parsing disease label: $e');
      return {
        'plantName': 'Plant',
        'diseaseName': 'Health Analysis',
        'isHealthy': false,
        'rawLabel': label,
      };
    }
  }
  // String _determineSeverity(String diseaseName, double confidence) {
  //   debugPrint('⚖️ Determining severity for "$diseaseName" with confidence $confidence%');
  //
  //   if (diseaseName.toLowerCase() == 'healthy') {
  //     debugPrint('✅ Plant is healthy, severity: None');
  //     return 'None';
  //   }
  //
  //   // High severity diseases
  //   final highSeverity = [
  //     'late blight', 'bacterial spot', 'black rot', 'rust', 'blight'
  //   ];
  //
  //   // Medium severity diseases
  //   final mediumSeverity = [
  //     'early blight', 'powdery mildew', 'leaf spot', 'scorch'
  //   ];
  //
  //   final lowerDisease = diseaseName.toLowerCase();
  //
  //   for (var disease in highSeverity) {
  //     if (lowerDisease.contains(disease)) {
  //       debugPrint('⚠️ High severity disease detected: $diseaseName');
  //       return 'High';
  //     }
  //   }
  //
  //   for (var disease in mediumSeverity) {
  //     if (lowerDisease.contains(disease)) {
  //       debugPrint('⚠️ Medium severity disease detected: $diseaseName');
  //       return 'Medium';
  //     }
  //   }
  //
  //   // Based on confidence
  //   if (confidence > 70) {
  //     debugPrint('⚠️ High confidence disease, severity: High');
  //     return 'High';
  //   }
  //   if (confidence > 40) {
  //     debugPrint('⚠️ Medium confidence disease, severity: Medium');
  //     return 'Medium';
  //   }
  //
  //   debugPrint('⚠️ Low confidence disease, severity: Low');
  //   return 'Low';
  // }

  String _getCause(String diseaseName) {
    final lowerDisease = diseaseName.toLowerCase();

    if (lowerDisease.contains('blight')) return 'Fungal or bacterial infection';
    if (lowerDisease.contains('spot')) return 'Bacterial or fungal pathogens';
    if (lowerDisease.contains('rot')) return 'Fungal or bacterial decay';
    if (lowerDisease.contains('rust')) return 'Fungal rust disease';
    if (lowerDisease.contains('mildew')) return 'Powdery or downy mildew fungi';
    if (lowerDisease.contains('scorch')) return 'Environmental stress or fungal';
    if (lowerDisease.contains('curl')) return 'Viral infection';

    return 'Pathogen infection or environmental stress';
  }

  List<String> _getSymptoms(String diseaseName) {
    final lowerDisease = diseaseName.toLowerCase();

    if (lowerDisease == 'healthy') {
      return ['No visible symptoms', 'Normal leaf color and texture'];
    }

    final symptoms = <String>[];

    if (lowerDisease.contains('blight')) {
      symptoms.addAll([
        'Dark lesions on leaves',
        'Yellowing around lesions',
        'Rapid spreading in humid conditions'
      ]);
    }

    if (lowerDisease.contains('spot')) {
      symptoms.addAll([
        'Small circular spots',
        'Yellow halos around spots',
        'Spots may merge into larger areas'
      ]);
    }

    if (lowerDisease.contains('rot')) {
      symptoms.addAll([
        'Soft, decaying tissue',
        'Discoloration',
        'Foul odor in advanced stages'
      ]);
    }

    if (lowerDisease.contains('rust')) {
      symptoms.addAll([
        'Rust-colored pustules',
        'Yellow spots on upper leaf surface',
        'Premature leaf drop'
      ]);
    }

    if (lowerDisease.contains('mildew')) {
      symptoms.addAll([
        'White powdery coating',
        'Leaf curling',
        'Reduced photosynthesis'
      ]);
    }

    // Default symptoms if none matched
    if (symptoms.isEmpty) {
      symptoms.addAll([
        'Abnormal leaf discoloration',
        'Spots or lesions on leaves',
        'Reduced plant vigor'
      ]);
    }

    return symptoms;
  }

  List<String> _getRemediation(String diseaseName, String plantName, bool isHealthy) {
    if (isHealthy) {
      return [
        'Continue current care regimen',
        'Maintain proper watering schedule',
        'Ensure adequate sunlight exposure',
        'Apply balanced fertilizer as needed'
      ];
    }

    final remediation = <String>[];
    final lowerDisease = diseaseName.toLowerCase();

    // General remediation steps
    remediation.addAll([
      'Remove and destroy infected leaves',
      'Improve air circulation around plant',
      'Avoid overhead watering',
      'Clean gardening tools after use'
    ]);

    // Disease-specific treatments
    if (lowerDisease.contains('blight') || lowerDisease.contains('rot')) {
      remediation.addAll([
        'Apply copper-based fungicide',
        'Remove severely infected plants',
        'Rotate crops if applicable'
      ]);
    }

    if (lowerDisease.contains('spot') || lowerDisease.contains('rust')) {
      remediation.addAll([
        'Apply appropriate fungicide',
        'Prune affected areas',
        'Dispose of fallen leaves'
      ]);
    }

    if (lowerDisease.contains('mildew')) {
      remediation.addAll([
        'Apply sulfur or potassium bicarbonate spray',
        'Increase spacing between plants',
        'Reduce nitrogen fertilizer'
      ]);
    }

    if (lowerDisease.contains('curl')) {
      remediation.addAll([
        'Control insect vectors (whiteflies, aphids)',
        'Remove and destroy infected plants',
        'Use virus-free planting material'
      ]);
    }

    return remediation;
  }

  List<String> _getPrecautions(String diseaseName, String plantName) {
    final precautions = <String>[
      'Regularly inspect plants for early signs',
      'Maintain proper plant spacing',
      'Water at the base, not on leaves',
      'Use disease-resistant varieties when possible',
      'Clean garden debris regularly',
      'Rotate crops annually'
    ];

    if (diseaseName.toLowerCase() != 'healthy') {
      precautions.addAll([
        'Isolate new plants for observation',
        'Avoid working with plants when wet',
        'Sterilize tools between plants'
      ]);
    }

    return precautions;
  }

  Map<String, dynamic> _createFallbackResult(String reason) {
    debugPrint('🔄 Creating fallback result: $reason');

    return {
      'success': true,
      'plantName': 'Unable to Determine',
      'diseaseName': 'Unable to Determine',
      'confidence': '0',
      'severity': 'Unknown',
      'cause': 'Analysis failed due to technical issue',
      'isHealthy': false,
      'symptoms': ['Technical error in analysis'],
      'remediation': [
        'Please try scanning again',
        'Ensure good lighting and clear focus',
        'Contact support if problem persists'
      ],
      'precautions': [
        'Monitor plant health manually',
        'Document any changes in appearance'
      ],
      'allPredictions': [],
      'rawLabel': 'fallback_analysis',
    };
  }

  Future<void> dispose() async {
    try {
      _interpreter?.close();
      _isModelLoaded = false;
      debugPrint('🧹 Disease model disposed');
    } catch (e) {
      debugPrint('❌ Error disposing disease model: $e');
    }
  }

  Future<bool> testModel() async {
    try {
      if (!_isModelLoaded) {
        await loadModel();
      }

      // Get model input size
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final targetHeight = inputShape[1];
      final targetWidth = inputShape[2];

      // Create a dummy 4D array
      final dummyInput = List.generate(
          1, (_) => List.generate(
          targetHeight, (_) => List.generate(
          targetWidth, (_) => List<double>.filled(3, 0.5)))); // Gray color

      // Prepare output
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .cast<double>();

      // Run inference
      _interpreter!.run(dummyInput, output);

      debugPrint('✅ Disease model test passed');
      debugPrint('   Input shape: [1, $targetHeight, $targetWidth, 3]');
      debugPrint('   Output shape: $outputShape');
      debugPrint('   Number of classes: ${output.length}');

      return true;
    } catch (e) {
      debugPrint('❌ Disease model test failed: $e');
      return false;
    }
  }
}