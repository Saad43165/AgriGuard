import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agriguard_fyp/features/ResultScreen/presentation/components/next_steps_card.dart';
import 'package:agriguard_fyp/features/ResultScreen/presentation/components/result_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../../../core/constants/app_routes.dart';
import '../../../core/widgets/floating_orb.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import '../../home/screens/bottom_sheet_widgets/pdf_success_dialog.dart';
import '../../home/screens/bottom_sheet_widgets/services/pdf_action_services.dart';
import 'components/analysis_details_card.dart';
import 'components/diagnosis_card.dart';
import 'components/diagnosis_result.dart';
import 'components/disease_cause_card.dart';
import 'components/floating_advance_search_banner.dart';
import 'components/recommentations_card.dart';
import 'components/pdf_floating_button.dart';
import '../../../../core/repositories/scan_repository.dart';
import '../../../../core/services/severity_id_service.dart';

// Enhanced Leaf Detection Helper
class LeafDetectionUtils {
  static Future<Map<String, dynamic>> analyzeImageForLeafDetection(
      String? imagePath, String? imageBase64) async {
    try {
      if (imagePath == null && imageBase64 == null) {
        return {'isLeaf': true, 'confidence': 50.0, 'reasons': ['No image available for analysis']};
      }

      Uint8List imageBytes;

      if (imageBase64 != null) {
        imageBytes = base64Decode(imageBase64);
      } else {
        imageBytes = await File(imagePath!).readAsBytes();
      }

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return {'isLeaf': true, 'confidence': 50.0, 'reasons': ['Failed to decode image']};
      }

      final resizedImage = img.copyResize(image, width: 300);

      final greenAnalysis = _analyzeGreenDominance(resizedImage);
      final textureAnalysis = _analyzeTexture(resizedImage);
      final shapeAnalysis = _analyzeShape(resizedImage);
      final colorAnalysis = _analyzeColorDistribution(resizedImage);
      final edgeAnalysis = _analyzeEdgeFeatures(resizedImage);

      double totalScore = 0.0;
      int factorCount = 0;

      if (greenAnalysis['score'] != null) {
        totalScore += greenAnalysis['score'] * 0.4;
        factorCount++;
      }

      if (textureAnalysis['score'] != null) {
        totalScore += textureAnalysis['score'] * 0.25;
        factorCount++;
      }

      if (shapeAnalysis['score'] != null) {
        totalScore += shapeAnalysis['score'] * 0.2;
        factorCount++;
      }

      if (edgeAnalysis['score'] != null) {
        totalScore += edgeAnalysis['score'] * 0.15;
        factorCount++;
      }

      final normalizedScore = totalScore * 100;

      List<String> reasons = [];
      bool isLeaf = normalizedScore > 40;

      if (!isLeaf) {
        reasons.add('Image appears to be non-plant material');
        if (greenAnalysis['greenPercentage'] < 20) {
          reasons.add('Low green color presence (${greenAnalysis['greenPercentage'].toStringAsFixed(1)}%)');
        }
        if (textureAnalysis['isTooUniform'] ?? false) {
          reasons.add('Texture appears artificial or uniform');
        }
        if (colorAnalysis['hasTooManyColors'] ?? false) {
          reasons.add('Unnatural color distribution for plant leaves');
        }
        if (edgeAnalysis['hasTooManyStraightEdges'] ?? false) {
          reasons.add('Contains many straight edges (uncommon for leaves)');
        }
      } else {
        reasons.add('Image characteristics match plant leaves');
        if (greenAnalysis['greenPercentage'] > 40) {
          reasons.add('Significant green color present (${greenAnalysis['greenPercentage'].toStringAsFixed(1)}%)');
        }
        if (textureAnalysis['hasComplexTexture'] ?? false) {
          reasons.add('Complex texture pattern detected');
        }
      }

      debugPrint('🍃 Leaf Detection Results:');
      debugPrint('   Overall Score: ${normalizedScore.toStringAsFixed(1)}%');
      debugPrint('   Green: ${greenAnalysis['greenPercentage'].toStringAsFixed(1)}%');
      debugPrint('   Texture Score: ${((textureAnalysis['score'] ?? 0) * 100).toStringAsFixed(1)}%');
      debugPrint('   Shape Score: ${((shapeAnalysis['score'] ?? 0) * 100).toStringAsFixed(1)}%');
      debugPrint('   Is Leaf: $isLeaf');

      return {
        'isLeaf': isLeaf,
        'confidence': normalizedScore,
        'details': {
          'greenAnalysis': greenAnalysis,
          'textureAnalysis': textureAnalysis,
          'shapeAnalysis': shapeAnalysis,
          'colorAnalysis': colorAnalysis,
          'edgeAnalysis': edgeAnalysis,
        },
        'reasons': reasons,
      };
    } catch (e) {
      debugPrint('Leaf detection error: $e');
      return {'isLeaf': true, 'confidence': 50.0, 'reasons': ['Detection error, defaulting to leaf']};
    }
  }

  static Map<String, dynamic> _analyzeGreenDominance(img.Image image) {
    int greenPixels = 0;
    int totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        if (g > r * 1.2 && g > b * 1.2 && g > 30) {
          greenPixels++;
        }
      }
    }

    final greenPercentage = (greenPixels / totalPixels) * 100;

    double score = 0.0;
    if (greenPercentage > 60) {
      score = 1.0;
    } else if (greenPercentage > 40) score = 0.8;
    else if (greenPercentage > 20) score = 0.5;
    else if (greenPercentage > 10) score = 0.3;

    return {
      'greenPercentage': greenPercentage,
      'score': score,
      'greenPixels': greenPixels,
      'totalPixels': totalPixels,
    };
  }

  static Map<String, dynamic> _analyzeTexture(img.Image image) {
    final gray = img.grayscale(image);

    int edgeCount = 0;
    final edgeThreshold = 25;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final center = _getLuminance(gray.getPixel(x, y));
        final right = _getLuminance(gray.getPixel(x + 1, y));
        final bottom = _getLuminance(gray.getPixel(x, y + 1));

        if ((center - right).abs() > edgeThreshold ||
            (center - bottom).abs() > edgeThreshold) {
          edgeCount++;
        }
      }
    }

    final edgeDensity = (edgeCount / (gray.width * gray.height)) * 100;

    double score = 0.0;
    if (edgeDensity > 5 && edgeDensity < 40) {
      score = 0.7 + (edgeDensity / 100);
    } else if (edgeDensity < 2) {
      return {'score': 0.2, 'edgeDensity': edgeDensity, 'isTooUniform': true};
    } else if (edgeDensity > 50) {
      return {'score': 0.3, 'edgeDensity': edgeDensity, 'isTooNoisy': true};
    }

    return {
      'score': score,
      'edgeDensity': edgeDensity,
      'hasComplexTexture': edgeDensity > 10,
    };
  }

  static Map<String, dynamic> _analyzeShape(img.Image image) {
    final aspectRatio = image.width / image.height;

    double score = 0.0;

    if (aspectRatio >= 1.2 && aspectRatio <= 4.0) {
      score = 0.8;
    } else if (aspectRatio >= 1.0 && aspectRatio <= 1.5) {
      score = 0.5;
    } else {
      score = 0.3;
    }

    return {
      'score': score,
      'aspectRatio': aspectRatio,
      'width': image.width,
      'height': image.height,
    };
  }

  static Map<String, dynamic> _analyzeColorDistribution(img.Image image) {
    Map<String, int> colorBins = {};

    for (int y = 0; y < image.height; y += 2) {
      for (int x = 0; x < image.width; x += 2) {
        final pixel = image.getPixel(x, y);
        final colorKey = '${(pixel.r ~/ 32)}-${(pixel.g ~/ 32)}-${(pixel.b ~/ 32)}';
        colorBins[colorKey] = (colorBins[colorKey] ?? 0) + 1;
      }
    }

    final uniqueColors = colorBins.length;
    final totalSamples = (image.width / 2) * (image.height / 2);
    final colorVariety = (uniqueColors / totalSamples) * 100;

    return {
      'uniqueColors': uniqueColors,
      'colorVariety': colorVariety,
      'hasTooManyColors': colorVariety > 15,
    };
  }

  static Map<String, dynamic> _analyzeEdgeFeatures(img.Image image) {
    final gray = img.grayscale(image);
    final edges = img.sobel(gray);

    int straightEdgeCount = 0;
    int totalEdgePixels = 0;

    for (int y = 1; y < edges.height - 1; y++) {
      for (int x = 1; x < edges.width - 1; x++) {
        final pixel = edges.getPixel(x, y);
        final luminance = _getLuminance(pixel);

        if (luminance > 100) {
          totalEdgePixels++;

          final neighbors = [
            _getLuminance(edges.getPixel(x-1, y-1)),
            _getLuminance(edges.getPixel(x, y-1)),
            _getLuminance(edges.getPixel(x+1, y-1)),
            _getLuminance(edges.getPixel(x-1, y)),
            _getLuminance(edges.getPixel(x+1, y)),
            _getLuminance(edges.getPixel(x-1, y+1)),
            _getLuminance(edges.getPixel(x, y+1)),
            _getLuminance(edges.getPixel(x+1, y+1)),
          ];

          int alignedNeighbors = 0;
          for (final neighbor in neighbors) {
            if (neighbor > 50) alignedNeighbors++;
          }

          if (alignedNeighbors >= 4) {
            straightEdgeCount++;
          }
        }
      }
    }

    final straightEdgeRatio = totalEdgePixels > 0
        ? (straightEdgeCount / totalEdgePixels) * 100
        : 0;

    double score = 0.0;
    if (straightEdgeRatio < 20) {
      score = 0.8;
    } else if (straightEdgeRatio < 40) {
      score = 0.5;
    } else {
      score = 0.2;
    }

    return {
      'score': score,
      'straightEdgeRatio': straightEdgeRatio,
      'totalEdgePixels': totalEdgePixels,
      'straightEdgeCount': straightEdgeCount,
      'hasTooManyStraightEdges': straightEdgeRatio > 30,
    };
  }

  static double _getLuminance(img.Pixel pixel) {
    return (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
  }
}

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ResultsScreen({
    required this.scanData,
    super.key,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  // State Variables
  bool _isSaving = false;
  bool _isAlreadySaved = false;
  bool _showAdvancedSearchBanner = false;
  bool _jsonLoaded = false;
  bool _isLeafImage = true;
  bool _checkingLeafDetection = false;
  bool _isGeneratingPdf = false;
  Timer? _advancedSearchTimer;

  // Data Variables
  final Map<String, dynamic> _diseaseCauses = {};
  final Map<String, dynamic> _diseaseMapping = {};
  final List<String> _diseaseCausesList = [];

  // Severity and Remediation from Service
  String _severity = 'Medium';
  List<String> _remediation = [];
  bool _isLoadingSeverityRemediation = false;

  // Repository and Services
  late final ScanRepository _scanRepository;
  late final SeverityIdService _severityIdService;
  final PdfActionsService _pdfService = PdfActionsService();

  // Constants
  static const _advancedSearchDelay = Duration(seconds: 4);
  static const _advancedSearchDuration = Duration(seconds: 8);
  static const _minimumConfidence = 30.0;
  static const _scanIdPrefix = 'ondevice_';
  static const _nonLeafConfidence = 95.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scanRepository = ScanRepository();
    _severityIdService = SeverityIdService();
    _loadJsonData();
    _scheduleAdvancedSearchBanner();
    _checkLeafAndSaveScan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _advancedSearchTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLeafAndSaveScan() async {
    try {
      if (mounted) {
        setState(() => _checkingLeafDetection = true);
      }

      final imagePath = widget.scanData['imagePath'] as String?;
      final imageBase64 = widget.scanData['imageBase64'] as String?;

      final leafAnalysis = await LeafDetectionUtils.analyzeImageForLeafDetection(
          imagePath,
          imageBase64
      );

      _isLeafImage = leafAnalysis['isLeaf'] as bool;
      final detectionConfidence = leafAnalysis['confidence'] as double;

      debugPrint('🍃 Enhanced Leaf Detection:');
      debugPrint('   Is Leaf: $_isLeafImage');
      debugPrint('   Confidence: ${detectionConfidence.toStringAsFixed(1)}%');

      if (!_isLeafImage) {
        widget.scanData['diseaseName'] = 'Image Not Recognized';
        widget.scanData['plantName'] = 'Non-Plant Image';
        widget.scanData['confidence'] = detectionConfidence.toStringAsFixed(1);
        widget.scanData['isHealthy'] = false;
        widget.scanData['severity'] = 'N/A';
        widget.scanData['description'] = 'The uploaded image does not appear to be a plant leaf. Our analysis detected this as non-plant material with ${detectionConfidence.toStringAsFixed(1)}% confidence.';
        widget.scanData['skipSave'] = true;
        widget.scanData['remediation'] = leafAnalysis['reasons']?.cast<String>() ?? [
          'Please upload a clear photo of a plant leaf',
          'Ensure the leaf fills most of the frame',
          'Take the photo in good lighting conditions',
          'Avoid blurry or distant photos'
        ];

        widget.scanData['leafDetectionDetails'] = leafAnalysis['details'];

        _severity = 'N/A';
        _remediation = widget.scanData['remediation'] as List<String>;
      } else {
        await _getSeverityAndRemediation();
      }

      await _checkAndSaveScan();
    } catch (e) {
      debugPrint('Leaf detection error: $e');
      _isLeafImage = true;
    } finally {
      if (mounted) {
        setState(() => _checkingLeafDetection = false);
      }
    }
  }

  Future<void> _getSeverityAndRemediation() async {
    try {
      if (mounted) {
        setState(() => _isLoadingSeverityRemediation = true);
      }

      debugPrint('🔍 Getting severity and remediation from service...');

      final severityResult = await _severityIdService.getSeverityAndRemediation(
        diseaseName: widget.scanData['diseaseName']?.toString() ?? '',
        plantName: widget.scanData['plantName']?.toString() ?? '',
        confidence: double.tryParse(widget.scanData['confidence']?.toString() ?? '0') ?? 0,
        imagePath: widget.scanData['imagePath'] as String?,
        imageBase64: widget.scanData['imageBase64'] as String?,
      );

      if (severityResult != null) {
        _severity = severityResult['severity']?.toString() ??
            widget.scanData['severity']?.toString() ??
            'Medium';

        final remediationData = severityResult['remediation'];
        if (remediationData != null) {
          if (remediationData is List) {
            _remediation = remediationData.cast<String>();
          } else if (remediationData is String) {
            _remediation = remediationData
                .split(RegExp(r'[,;\n]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }

        widget.scanData['severity'] = _severity;
        widget.scanData['remediation'] = _remediation;

        debugPrint('✅ Severity: $_severity');
        debugPrint('✅ Remediation count: ${_remediation.length}');
      } else {
        _severity = widget.scanData['severity']?.toString() ?? 'Medium';
        _remediation = _parseStringToList(widget.scanData['remediation'] ?? widget.scanData['treatment']);
        debugPrint('⚠️ Using fallback severity and remediation');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting severity and remediation: $e');
      debugPrint('Stack trace: $stackTrace');

      _severity = widget.scanData['severity']?.toString() ?? 'Medium';
      _remediation = _parseStringToList(widget.scanData['remediation'] ?? widget.scanData['treatment']);
    } finally {
      if (mounted) {
        setState(() => _isLoadingSeverityRemediation = false);
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  Future<void> _loadJsonData() async {
    try {
      debugPrint('📚 Loading JSON data...');

      final causesFuture = rootBundle.loadString('assets/data/disease_causes.json');
      final mappingFuture = rootBundle.loadString('assets/data/mapping.json');

      final results = await Future.wait([causesFuture, mappingFuture]);

      _diseaseCauses.addAll(json.decode(results[0]));
      _diseaseMapping.addAll(json.decode(results[1]));

      _extractDiseaseCauses();

      if (mounted) {
        setState(() => _jsonLoaded = true);
      }
    } catch (e) {
      debugPrint('❌ Error loading JSON data: $e');
      if (mounted) {
        setState(() => _jsonLoaded = true);
      }
    }
  }

  Future<void> _checkAndSaveScan() async {
    if (_shouldSkipSave()) {
      debugPrint('📂 Skipping auto-save for existing/advanced scan');
      if (mounted) {
        setState(() => _isAlreadySaved = true);
      }
      return;
    }

    if (_isAlreadySaved || _isSaving) {
      debugPrint('✅ Scan already processed in this session');
      return;
    }

    await _saveScanToDatabase();
  }

  bool _shouldSkipSave() {
    final data = widget.scanData;

    return data['isFromHistory'] == true ||
        data['skipSave'] == true ||
        data['databaseId'] != null ||
        data['isAdvanced'] == true ||
        data['analysisSource'] != null ||
        (data['id'] != null &&
            (data['id'] as String).startsWith(_scanIdPrefix) ||
            (data['id'] as String).startsWith('advanced_'));
  }

  Future<void> _saveScanToDatabase() async {
    try {
      if (mounted) {
        setState(() => _isSaving = true);
      }

      final scanId = _generateScanId();
      final existingScan = await _scanRepository.getScanById(scanId);

      if (existingScan != null) {
        debugPrint('✅ Scan already exists in database');
        _updateSaveState(false, true);
        return;
      }

      final processedData = await _processScanData(scanId);
      await _scanRepository.saveOnDeviceScan(
        scanData: processedData,
        imagePath: widget.scanData['imagePath'] as String?,
      );

      debugPrint('✅ Scan saved successfully: $scanId');
      _updateSaveState(false, true);
    } catch (e, stackTrace) {
      debugPrint('❌ Save error: $e\n$stackTrace');
      _updateSaveState(false, false);

      if (!_isDuplicateError(e)) {
        _showSaveError();
      }
    }
  }

  String _generateScanId() {
    final data = widget.scanData;
    final hash = jsonEncode({
      'plant': data['plantName'],
      'disease': data['diseaseName'],
      'confidence': data['confidence'],
      'image': data['imagePath']?.hashCode ?? 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).hashCode.abs();

    return '$_scanIdPrefix${hash}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<Map<String, dynamic>> _processScanData(String scanId) async {
    final processedData = Map<String, dynamic>.from(widget.scanData);

    final imageBase64 = await _getImageBase64();
    if (imageBase64 != null) {
      processedData['imageBase64'] = imageBase64;
    }

    _fixDataTypes(processedData);
    processedData['id'] = scanId;

    return processedData;
  }

  Future<String?> _getImageBase64() async {
    final imageBase64 = widget.scanData['imageBase64'] as String?;
    if (imageBase64 != null) return imageBase64;

    final imagePath = widget.scanData['imagePath'] as String?;
    if (imagePath != null) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to convert image: $e');
      }
    }

    return null;
  }

  void _fixDataTypes(Map<String, dynamic> data) {
    if (data['confidence'] is String) {
      if (!_isLeafImage) {
        final leafAnalysis = data['leafDetectionDetails'];
        if (leafAnalysis != null) {
          data['confidence'] = data['confidence'] as double;
        } else {
          data['confidence'] = _nonLeafConfidence;
        }
      } else {
        data['confidence'] = double.tryParse(data['confidence']) ?? 0.0;
      }
    } else if (data['confidence'] == null && !_isLeafImage) {
      data['confidence'] = _nonLeafConfidence;
    }

    data['symptoms'] = _parseStringToList(data['symptoms']);

    if (_remediation.isNotEmpty) {
      data['remediation'] = _remediation;
    } else if (data['remediation'] != null) {
      data['remediation'] = _parseStringToList(data['remediation']);
    } else if (data['treatment'] != null) {
      data['treatment'] = _parseStringToList(data['treatment']);
      data['remediation'] = data['treatment'];
    } else {
      data['remediation'] = [];
    }

    data['precautions'] = _parseStringToList(data['precautions']);

    if (_severity.isNotEmpty) {
      data['severity'] = _severity;
    }
  }

  List<String> _parseStringToList(dynamic input) {
    if (input == null) return [];
    if (input is List) return List<String>.from(input);
    if (input is String) {
      return input
          .split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  bool _isDuplicateError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('duplicate') ||
        errorString.contains('already exists');
  }

  void _updateSaveState(bool isSaving, bool isSaved) {
    if (mounted) {
      setState(() {
        _isSaving = isSaving;
        _isAlreadySaved = isSaved;
      });
    }
  }

  void _extractDiseaseCauses() {
    try {
      if (!_isLeafImage) {
        _diseaseCausesList.addAll([
          'The uploaded image does not appear to be a plant leaf',
          'Plant disease detection requires clear photos of plant leaves',
          'Our analysis detected non-plant characteristics:',
          '• Image likely shows non-plant material',
          '• Insufficient green color presence for plant leaves',
          '• Texture patterns not matching typical leaves',
          '• May contain man-made objects or other non-plant items'
        ]);
        return;
      }

      final rawLabel = widget.scanData['rawLabel']?.toString();
      final diseaseName = widget.scanData['diseaseName']?.toString();
      final plantName = widget.scanData['plantName']?.toString();
      final confidence = _getConfidence();

      if (_isFailedAnalysis(diseaseName)) {
        _diseaseCausesList.addAll(_getFailedAnalysisCauses());
        return;
      }

      if (_isUnknownPlant(plantName)) {
        _diseaseCausesList.addAll(_getUnknownPlantCauses());
        return;
      }

      if (_isHealthyPlant(diseaseName)) {
        _diseaseCausesList.addAll(_getHealthyPlantCauses());
        return;
      }

      if (confidence < _minimumConfidence) {
        _diseaseCausesList.addAll(_getLowConfidenceCauses());
        return;
      }

      final diseaseKey = _findDiseaseKey(rawLabel, diseaseName, plantName);
      if (diseaseKey != null && _diseaseCauses.containsKey(diseaseKey)) {
        final causes = _extractCausesFromKey(diseaseKey);
        if (causes.isNotEmpty) {
          _diseaseCausesList.addAll(causes);
          return;
        }
      }

      _tryGeneralCauses(diseaseName);
    } catch (e) {
      debugPrint('❌ Error extracting causes: $e');
      _diseaseCausesList.addAll([
        'Error loading disease information',
        'Please try again or consult an expert'
      ]);
    }
  }

  double _getConfidence() {
    if (!_isLeafImage) {
      return _nonLeafConfidence;
    }
    return double.tryParse(widget.scanData['confidence']?.toString() ?? '0') ?? 0;
  }

  bool _isFailedAnalysis(String? diseaseName) {
    return diseaseName == null ||
        diseaseName.toLowerCase().contains('unable to determine') ||
        diseaseName.toLowerCase().contains('image quality issue') ||
        diseaseName.toLowerCase().contains('analysis required');
  }

  bool _isUnknownPlant(String? plantName) {
    return plantName == null ||
        plantName.toLowerCase().contains('unknown') ||
        plantName.toLowerCase().contains('unable to determine');
  }

  bool _isHealthyPlant(String? diseaseName) {
    return diseaseName?.toLowerCase() == 'healthy' ||
        diseaseName?.toLowerCase().contains('healthy') == true ||
        (widget.scanData['isHealthy'] as bool? ?? false);
  }

  List<String> _getFailedAnalysisCauses() {
    return [
      'Analysis could not be completed successfully',
      'This may be due to poor image quality or unclear symptoms',
      'Please try again with a clearer photo'
    ];
  }

  List<String> _getUnknownPlantCauses() {
    return [
      'Plant species could not be identified',
      'Specific disease causes require plant identification',
      'For accurate diagnosis, please ensure:',
      '• Clear photo of the whole plant',
      '• Good lighting conditions',
      '• Focus on affected leaves'
    ];
  }

  List<String> _getHealthyPlantCauses() {
    return [
      'Plant appears to be in good health',
      'No visible signs of disease or stress',
      'Maintaining current care practices is recommended'
    ];
  }

  List<String> _getLowConfidenceCauses() {
    return [
      'Low confidence in disease identification',
      'Possible causes could include:',
      '• Environmental stress factors',
      '• Mild pathogen infection',
      '• Natural leaf variations',
      'Consult an expert for accurate diagnosis'
    ];
  }

  String? _findDiseaseKey(String? rawLabel, String? diseaseName, String? plantName) {
    if (rawLabel != null && _diseaseCauses.containsKey(rawLabel)) {
      return rawLabel;
    }

    if (rawLabel != null && _diseaseMapping.containsKey(rawLabel)) {
      final displayName = _diseaseMapping[rawLabel]['display_name']?.toString();
      if (displayName != null) {
        return _findKeyByDisplayName(displayName);
      }
    }

    if (plantName != null && diseaseName != null) {
      final constructedKey = '${plantName.replaceAll(' ', '_')}___${diseaseName.replaceAll(' ', '_').toLowerCase()}';
      if (_diseaseCauses.containsKey(constructedKey)) {
        return constructedKey;
      }
    }

    return null;
  }

  String? _findKeyByDisplayName(String displayName) {
    if (!displayName.contains(' - ')) return null;

    final parts = displayName.split(' - ');
    if (parts.length != 2) return null;

    final plant = parts[0].replaceAll(' ', '_');
    final disease = parts[1].replaceAll(' ', '_').toLowerCase();

    final key = '${plant}___$disease';
    if (_diseaseCauses.containsKey(key)) return key;

    if (disease == 'healthy') {
      final healthyKey = '${plant}___healthy';
      if (_diseaseCauses.containsKey(healthyKey)) return healthyKey;
    }

    return null;
  }

  List<String> _extractCausesFromKey(String key) {
    final diseaseData = _diseaseCauses[key];
    if (diseaseData is Map && diseaseData.containsKey('causes')) {
      final causes = diseaseData['causes'];
      if (causes is List && causes.isNotEmpty) {
        return List<String>.from(causes);
      }
    }
    return [];
  }

  void _tryGeneralCauses(String? diseaseName) {
    if (diseaseName == null || !_diseaseCauses.containsKey('general_disease_causes')) {
      _diseaseCausesList.addAll(_getFallbackCauses(diseaseName));
      return;
    }

    final generalCauses = _diseaseCauses['general_disease_causes'];
    if (generalCauses is! Map) return;

    final lowerDisease = diseaseName.toLowerCase();
    String? causeType;

    if (lowerDisease.contains('spot')) {
      causeType = 'bacterial_spot';
    } else if (lowerDisease.contains('blight')) causeType = 'blight';
    else if (lowerDisease.contains('rust')) causeType = 'rust_disease';
    else if (lowerDisease.contains('mildew')) causeType = 'powdery_mildew';

    if (causeType != null && generalCauses.containsKey(causeType)) {
      final causes = generalCauses[causeType]['general_causes'];
      if (causes is List && causes.isNotEmpty) {
        _diseaseCausesList.addAll(List<String>.from(causes));
        return;
      }
    }

    _diseaseCausesList.addAll(_getFallbackCauses(diseaseName));
  }

  List<String> _getFallbackCauses(String? diseaseName) {
    return [
      'Specific causes for "${diseaseName ?? 'this disease'}" not available',
      'General disease prevention tips:',
      '• Ensure proper plant spacing',
      '• Water at soil level to avoid wet leaves',
      '• Remove infected plant material',
      '• Rotate crops annually'
    ];
  }

  void _scheduleAdvancedSearchBanner() {
    _advancedSearchTimer = Timer(_advancedSearchDelay, () {
      if (!mounted) return;

      setState(() => _showAdvancedSearchBanner = true);

      _advancedSearchTimer = Timer(_advancedSearchDuration, () {
        if (mounted) {
          setState(() => _showAdvancedSearchBanner = false);
        }
      });
    });
  }

  void _navigateToAdvancedSearch() {
    setState(() => _showAdvancedSearchBanner = false);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedSearchScreen(
          originalScanData: widget.scanData,
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    if (_isSaving) return;
    HapticFeedback.lightImpact();

    final previousRoute = widget.scanData['previousRoute'] as String?;
    final fromCapture = widget.scanData['fromCapture'] as bool? ?? false;

    if (fromCapture) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.scan,
            (route) => false,
      );
    } else if (previousRoute != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        previousRoute,
            (route) => false,
      );
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
            (route) => false,
      );
    }
  }

  Future<void> _generatePdfReport() async {
    if (_isGeneratingPdf) {
      debugPrint('⚠️ PDF generation already in progress');
      return;
    }

    debugPrint('🔘 Generate PDF button pressed!');

    setState(() => _isGeneratingPdf = true);

    try {
      // Prepare comprehensive scan data for PDF
      final pdfScanData = {
        ...widget.scanData,
        'severity': _severity,
        'remediation': _remediation,
        'symptoms': _diseaseCausesList,
        'plantName': _resolvePlantName(),
        'diseaseName': _getDiseaseName(),
        'confidence': widget.scanData['confidence']?.toString() ?? '0',
      };

      debugPrint('📊 PDF Data prepared with ${pdfScanData.keys.length} keys');

      await _pdfService.generateAndShowPdf(
        context: context,
        scan: pdfScanData,
        onError: (msg) {
          debugPrint('❌ PDF Error callback: $msg');
          if (mounted) {
            setState(() => _isGeneratingPdf = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(msg)),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        onSuccess: (file) async {
          debugPrint('✅ PDF Success callback triggered!');
          debugPrint('   File path: ${file.path}');
          debugPrint('   Widget mounted: $mounted');

          if (!mounted) {
            debugPrint('❌ Widget not mounted - cannot show dialog');
            return;
          }

          setState(() => _isGeneratingPdf = false);

          // Small delay to ensure UI is ready
          await Future.delayed(const Duration(milliseconds: 200));

          if (!mounted) {
            debugPrint('❌ Widget unmounted after delay');
            return;
          }

          debugPrint('🎯 Showing PdfSuccessDialog...');

          try {
            await showDialog(
              context: context,
              barrierDismissible: true,
              useRootNavigator: true,
              builder: (dialogContext) {
                debugPrint('✅ Dialog builder called');
                return PdfSuccessDialog(pdfFile: file);
              },
            );
            debugPrint('✅ Dialog closed');
          } catch (e) {
            debugPrint('❌ Error showing dialog: $e');
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ PDF generation error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  DiagnosisResult _getDiagnosisResult() {
    try {
      final plantName = _resolvePlantName();
      final diseaseName = _getDiseaseName();
      final isHealthy = _isPlantHealthy(diseaseName);

      final severity = _severity;
      final recommendations = _remediation.isNotEmpty ? _remediation : _getFallbackRecommendations(isHealthy);

      return DiagnosisResult(
        disease: diseaseName,
        severity: severity,
        recommendations: recommendations,
        plantName: plantName,
        confidence: widget.scanData['confidence']?.toString() ?? '0',
        description: widget.scanData['description']?.toString(),
        scientificName: widget.scanData['scientificName']?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Error creating DiagnosisResult: $e');
      return const DiagnosisResult(
        disease: 'Healthy',
        severity: 'None',
        recommendations: ['Please consult an agricultural expert for proper diagnosis'],
        plantName: 'Plant',
        confidence: '0',
      );
    }
  }

  String _resolvePlantName() {
    String plantName = widget.scanData['plantName']?.toString() ?? 'Unknown Plant';
    final rawLabel = widget.scanData['rawLabel']?.toString();

    if (rawLabel != null && rawLabel.contains('___')) {
      final parts = rawLabel.split('___');
      if (parts.length >= 2) {
        final diseasePlantName = parts[0].replaceAll('_', ' ').trim();
        final diseaseName = _getDiseaseName();

        if (diseasePlantName.isNotEmpty &&
            diseasePlantName.toLowerCase() != plantName.toLowerCase() &&
            diseasePlantName != 'Unknown Plant' &&
            diseaseName.toLowerCase() != 'healthy') {
          return diseasePlantName;
        }
      }
    }

    return plantName;
  }

  String _getDiseaseName() {
    return widget.scanData['diseaseName']?.toString() ??
        widget.scanData['diagnosis']?.toString() ??
        'Healthy';
  }

  List<String> _getFallbackRecommendations(bool isHealthy) {
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

  bool _isPlantHealthy(String diseaseName) {
    return diseaseName.toLowerCase() == 'healthy' ||
        diseaseName.toLowerCase().contains('no disease') ||
        (widget.scanData['isHealthy'] as bool? ?? false);
  }

  Widget _buildImageSection() {
    final imagePath = widget.scanData['imagePath'] as String?;
    final imageUrl = widget.scanData['imageUrl'] as String?;
    final imageBase64 = widget.scanData['imageBase64'] as String?;

    final imageWidget = _getImageWidget(imagePath, imageUrl, imageBase64);

    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageWidget,
      ),
    );
  }

  Widget _getImageWidget(String? imagePath, String? imageUrl, String? imageBase64) {
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        debugPrint('❌ Error decoding base64 image: $e');
      }
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildNoImagePlaceholder(),
      );
    }

    return _buildNoImagePlaceholder();
  }

  Widget _buildNoImagePlaceholder() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_rounded,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No image available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSearchButton() {
    if (!_isLeafImage) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.primary.withOpacity(0.05),
            ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToAdvancedSearch,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: _AdvancedSearchButtonContent(),
          ),
        ),
      ),
    );
  }

  void _showSaveError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Failed to save scan'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLeafDetection || _isLoadingSeverityRemediation) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _checkingLeafDetection ? 'Analyzing image...' : 'Getting severity and recommendations...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                _checkingLeafDetection ? 'Checking if image is a plant leaf' : 'Analyzing disease severity and treatment options',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final diagnosisResult = _getDiagnosisResult();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBackNavigation();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarContent(
          title: 'Analysis Results',
          showBackButton: !_isSaving,
          onBackPressed: _handleBackNavigation,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? const [
                Color(0xFF0F0F23),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
                Color(0xFF0F0F23),
              ]
                  : [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface.withOpacity(0.8),
                theme.colorScheme.surface,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(
                8,
                    (index) => FloatingOrb(
                  index: index,
                  maxWidth: MediaQuery.of(context).size.width,
                  fadeController: _fadeController,
                  scaleAnimation: _scaleAnimation,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 20),
                      DiagnosisCard(diagnosisResult: diagnosisResult),
                      const SizedBox(height: 20),
                      AnalysisDetailsCard(scanData: widget.scanData),
                      const SizedBox(height: 20),
                      if (_jsonLoaded)
                        DiseaseCausesCard(causes: _diseaseCausesList),
                      const SizedBox(height: 20),
                      RecommendationsCard(
                        recommendations: diagnosisResult.recommendations,
                      ),
                      const SizedBox(height: 20),
                      if (_isLeafImage) ...[
                        const NextStepsCard(),
                        const SizedBox(height: 20),
                      ],
                      _buildAdvancedSearchButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              if (_showAdvancedSearchBanner && _isLeafImage)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: FloatingAdvancedSearchBanner(
                    onTap: _navigateToAdvancedSearch,
                    onDismiss: () {
                      if (mounted) {
                        setState(() => _showAdvancedSearchBanner = false);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: _isLeafImage && !_isGeneratingPdf && !_isSaving
            ? Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PdfFloatingButton(
            onPressed: _generatePdfReport,
            isGenerating: _isGeneratingPdf,
          ),
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class _AdvancedSearchButtonContent extends StatelessWidget {
  const _AdvancedSearchButtonContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Want deeper analysis?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try Advanced AI Search with AI & Plant.id',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_rounded,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}