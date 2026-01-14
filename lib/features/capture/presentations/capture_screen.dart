import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../services/plant_id_service.dart';
import '../../../services/disease_id_service.dart';
import '../../../core/widgets/floating_orb.dart';
import '../../advance_search_screen/advanced_search_screen.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import 'components/capture_app_bar.dart';
import 'components/capture_info_dialog.dart';
import 'components/method_selection_screen.dart';
import 'components/processing_overlay.dart';
import 'components/source_selection_screen.dart';
import 'components/start_scan_button.dart';
import 'components/welcome_screen.dart';


class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  // Step management
  int _currentStep = 0; // 0: Welcome, 1: Select Method, 2: Select Source, 3: Processing
  String? _selectedMethod;

  XFile? _imageFile;
  bool _isLoading = false;
  bool _isProcessing = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  // Services
  final PlantIdService _plantService = PlantIdService();
  final DiseaseIdService _diseaseService = DiseaseIdService(); // Add disease service
  final GuestService _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _guestService.initialize();
    await _initializeModels(); // Changed to load both models
    if (mounted) setState(() {});
  }

  Future<void> _initializeModels() async {
    try {
      debugPrint('🔄 Loading both AI models...');
      await Future.wait([
        _plantService.loadModel(),
        _diseaseService.loadModel(), // Load disease model
      ]);
      debugPrint('✅ Both models loaded successfully');
      debugPrint('   Plant ID Model: ${_plantService.isLoaded ? "✅" : "❌"}');
      debugPrint('   Disease Model: ${_diseaseService.isLoaded ? "✅" : "❌"}');
    } catch (e) {
      debugPrint('❌ Model initialization error: $e');
      // Show error to user
      if (mounted) {
        _showErrorSnackBar('Failed to load AI models. Please restart the app.');
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _plantService.dispose();
    _diseaseService.dispose(); // Dispose disease service
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScanning() {
    HapticFeedback.mediumImpact();
    setState(() => _currentStep = 1);
  }

  void _selectMethod(String method) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedMethod = method;
      _currentStep = 2;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;

    if (_guestService.isGuestMode && !_guestService.hasScansRemaining) {
      _showGuestLimitDialog();
      return;
    }

    try {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted) return;

      if (picked != null) {
        setState(() => _imageFile = picked);
        if (_selectedMethod == 'tflite') {
          _processWithTFLite();
        } else {
          _navigateToAdvancedSearch();
        }
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar('Failed to pick image. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToAdvancedSearch() {
    if (_imageFile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedSearchScreen(
          originalScanData: {
            'imagePath': _imageFile!.path,
            'timestamp': DateTime.now().toIso8601String(),
            'method': 'api',
          },
        ),
      ),
    ).then((_) => _resetState());
  }

  Future<void> _processWithTFLite() async {
    if (!mounted || _imageFile == null || _isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _currentStep = 3;
    });

    try {
      User? user;
      if (!_guestService.isGuestMode) {
        user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Please sign in to continue');
      }

      final imageFile = File(_imageFile!.path);
      if (!await imageFile.exists()) throw Exception('Image file not found');

      // Run BOTH plant identification AND disease detection in parallel
      Map<String, dynamic> plantResult;
      Map<String, dynamic> diseaseResult;

      debugPrint('🤖 Starting dual AI analysis...');

      try {
        // Run both predictions in parallel for faster processing
        final results = await Future.wait([
          _plantService.predict(imageFile),
          _diseaseService.predict(imageFile),
        ]);

        plantResult = results[0];
        diseaseResult = results[1];

        debugPrint('📊 Plant ID Result:');
        debugPrint('   Plant: ${plantResult['label']}');
        debugPrint('   Confidence: ${plantResult['confidence']}');

        debugPrint('📊 Disease Detection Result:');
        debugPrint('   Disease: ${diseaseResult['diseaseName']}');
        debugPrint('   Confidence: ${diseaseResult['confidence']}%');
        debugPrint('   Severity: ${diseaseResult['severity']}');
        debugPrint('   Healthy: ${diseaseResult['isHealthy']}');
        debugPrint('   Raw Label: ${diseaseResult['rawLabel']}');

        // ✅ CRITICAL FIX: Use disease model's plant information when plant ID is uncertain
        final plantConfidence = plantResult['confidence'] as double;
        final diseaseConfidence = double.parse(diseaseResult['confidence'] as String);
        final predictedPlant = plantResult['label'] as String;
        final isPlantUnknown = plantResult['isUnknown'] as bool? ?? false;

        // Extract plant from disease label
        String correctPlantFromDisease = 'Unknown Plant';
        if (diseaseResult.containsKey('rawLabel')) {
          final rawLabel = diseaseResult['rawLabel'] as String;
          if (rawLabel.contains('___')) {
            final parts = rawLabel.split('___');
            if (parts[0].isNotEmpty) {
              correctPlantFromDisease = parts[0].replaceAll('_', ' ');
              debugPrint('✅ Extracted plant from disease model: $correctPlantFromDisease');
            }
          }
        }

        // DECISION LOGIC: When to trust disease model over plant ID
        if (isPlantUnknown || plantConfidence < 0.5) {
          // Plant ID is uncertain, use disease model's plant
          debugPrint('⚠️ Plant ID uncertain (confidence: ${(plantConfidence * 100).toStringAsFixed(1)}%)');
          debugPrint('   Using plant from disease model: $correctPlantFromDisease');

          // Update plant result
          plantResult['label'] = correctPlantFromDisease;
          plantResult['correctedFromDisease'] = true;
          plantResult['originalPrediction'] = predictedPlant;
          plantResult['correctionReason'] = 'Low plant ID confidence';
        } else if (diseaseConfidence > 70.0 && diseaseResult['isHealthy'] == true) {
          // High confidence healthy plant from disease model
          debugPrint('✅ High confidence healthy plant detected in disease model');
          debugPrint('   Disease model plant: $correctPlantFromDisease vs Plant ID: $predictedPlant');

          // If they don't match, trust the disease model for healthy plants
          if (!_plantsMatch(predictedPlant, correctPlantFromDisease)) {
            debugPrint('⚠️ Mismatch detected! Trusting disease model for healthy plant');
            plantResult['label'] = correctPlantFromDisease;
            plantResult['correctedFromDisease'] = true;
            plantResult['originalPrediction'] = predictedPlant;
            plantResult['correctionReason'] = 'Healthy plant mismatch correction';
          }
        }

        // Log inference times
        final plantTime = plantResult['inferenceTime'] ?? 0;
        final diseaseTime = diseaseResult['inferenceTime'] ?? 0;
        debugPrint('⏱️ Total inference time: ${plantTime + diseaseTime}ms');

      } catch (e) {
        debugPrint('❌ AI prediction error: $e');

        // Create fallback results
        plantResult = {
          'label': 'Unknown Plant',
          'confidence': 0.3,
          'isUnknown': true,
          'allPredictions': [],
          'inferenceTime': 0,
          'correctedFromDisease': false,
        };

        diseaseResult = {
          'success': true,
          'plantName': 'Plant',
          'diseaseName': 'Analysis Required',
          'confidence': '50.0',
          'severity': 'Unknown',
          'cause': 'AI analysis incomplete',
          'isHealthy': false,
          'symptoms': ['Analysis could not be completed'],
          'remediation': ['Please try again or use advanced analysis'],
          'precautions': ['Regular monitoring recommended'],
          'allPredictions': [],
          'rawLabel': 'Fallback Analysis',
        };
      }

      if (!mounted) return;

      // Check guest scan limits
      if (_guestService.isGuestMode) {
        final success = await _guestService.incrementScanCount();
        if (!success) {
          _showGuestLimitDialog();
          setState(() => _isProcessing = false);
          return;
        }
      }

      // Combine results into comprehensive analysis
      final result = _prepareScanData(plantResult, diseaseResult, user);
      if (!mounted) return;

      // Navigate to results screen
      await Navigator.pushNamed(
          context,
          AppRoutes.results,
          arguments: {'scanData': result}
      );

      _resetState();

    } catch (e) {
      debugPrint('❌ Process error: $e');
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() => _isProcessing = false);
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

// Helper method to check if plants match (fuzzy matching)
  bool _plantsMatch(String plant1, String plant2) {
    final p1 = plant1.toLowerCase();
    final p2 = plant2.toLowerCase();

    // Exact match
    if (p1 == p2) return true;

    // Common aliases
    final aliases = {
      'bell pepper': ['bell pepper', 'pepper'],
      'corn (maize)': ['corn', 'maize', 'corn (maize)'],
      'corn': ['corn', 'maize', 'corn (maize)'],
      'maize': ['corn', 'maize', 'corn (maize)'],
    };

    // Check if they're in the same alias group
    for (final group in aliases.values) {
      if (group.contains(p1) && group.contains(p2)) {
        return true;
      }
    }

    return false;
  }
  Map<String, dynamic> _prepareScanData(
      Map<String, dynamic> plantPrediction,
      Map<String, dynamic> diseasePrediction,
      User? user
      ) {
    final plantName = plantPrediction['label'] as String;
    final plantConfidence = plantPrediction['confidence'] as double;
    final isUnknown = plantPrediction['isUnknown'] as bool? ?? false;
    final isLikelyPlant = plantPrediction['isLikelyPlant'] as bool? ?? true; // Default to true

    // Disease information
    final diseaseName = diseasePrediction['diseaseName'] as String? ?? 'Health Analysis';
    final severity = diseasePrediction['severity'] as String? ?? 'Unknown';
    final cause = diseasePrediction['cause'] as String? ?? 'Requires analysis';
    final diseaseConfidence = diseasePrediction['confidence'] as String? ?? '0.0';
    final isHealthy = diseasePrediction['isHealthy'] as bool? ?? false;

    final plantConfidencePercent = (plantConfidence * 100).toStringAsFixed(1);
    final diseaseConfidencePercent = diseaseConfidence;

    // Determine diagnosis message
    String diagnosis;
    if (!isLikelyPlant) {
      diagnosis = '⚠️ Plant identification uncertain. The identified "${plantName}" appears to be a disease, not a plant species.';
    } else if (isUnknown || plantConfidence < 0.3) {
      diagnosis = 'Unable to identify plant with confidence';
    } else if (isHealthy) {
      diagnosis = '✅ Healthy $plantName plant identified';
    } else {
      diagnosis = '⚠️ $diseaseName detected on $plantName';
    }

    // Treatment recommendations
    String treatment;
    final remediationList = diseasePrediction['remediation'] as List<String>?;

    if (!isLikelyPlant && isHealthy) {
      // If plant ID is wrong but plant is healthy
      treatment = '• Plant identification uncertain\n• Plant appears healthy\n• Verify plant type for accurate care';
    } else if (remediationList != null && remediationList.isNotEmpty) {
      treatment = remediationList.join('\n• ');
      treatment = '• ' + treatment;

      // Add warning if plant ID might be wrong
      if (!isLikelyPlant) {
        treatment = '⚠️ NOTE: Plant identification may be incorrect. "${plantName}" appears to be a disease name.\n' + treatment;
      }
    } else if (isHealthy) {
      treatment = '• Continue regular care routine\n• Monitor for any signs of disease or pests\n• Apply balanced fertilizer as needed';
    } else {
      treatment = '• Consult agricultural expert for specific treatment\n• Isolate affected plant to prevent spread\n• Apply appropriate fungicide based on diagnosis';
    }

    // Add this warning section
    String warningNote = '';
    if (!isLikelyPlant) {
      warningNote = '''
    
⚠️ IMPORTANT NOTE:
The plant identification model predicted "${plantName}", which appears to be a disease name.
This may indicate:
1. The plant ID model is confused
2. The image shows disease symptoms
3. A different plant type

For accurate results, please:
• Take a clear photo of the whole plant
• Ensure good lighting
• Include leaves, stem, and if possible, flowers/fruits
''';
    }

    // Symptoms and precautions
    final symptomsList = diseasePrediction['symptoms'] as List<String>? ?? [];
    final precautionsList = diseasePrediction['precautions'] as List<String>? ?? [];

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'identified',
      'cropType': plantName,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'diagnosis': diagnosis,
      'confidence': diseaseConfidencePercent,
      'plantConfidence': plantConfidencePercent,
      'treatment': treatment + warningNote,
      'severity': severity,
      'cause': cause,
      'symptoms': symptomsList,
      'symptomsText': symptomsList.isNotEmpty ? symptomsList.join('\n• ') : 'No specific symptoms identified',
      'precautions': precautionsList,
      'precautionsText': precautionsList.isNotEmpty ? precautionsList.join('\n• ') : '• Maintain proper plant care\n• Regular monitoring\n• Adequate watering',
      'imagePath': _imageFile!.path,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': user?.uid ?? 'guest',
      'fromCapture': true,
      'previousRoute': AppRoutes.scan,
      'isUnknown': isUnknown,
      'isHealthy': isHealthy,
      'isLikelyPlant': isLikelyPlant,
      'allPredictions': plantPrediction['allPredictions'] ?? [],
      'diseasePredictions': diseasePrediction['allPredictions'] ?? [],
      'plantInferenceTime': plantPrediction['inferenceTime'] ?? 0,
      'diseaseInferenceTime': diseasePrediction['inferenceTime'] ?? 0,
      'isGuestScan': _guestService.isGuestMode,
      'rawPlantData': plantPrediction,
      'rawDiseaseData': diseasePrediction,
      'analysisMethod': 'tflite_dual',
      'hasDiseaseAnalysis': true,
      'plantIdWarning': !isLikelyPlant,
    };
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _imageFile = null;
        _isProcessing = false;
        _currentStep = 0;
        _selectedMethod = null;
      });
    }
  }

  void _showGuestLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Scan Limit Reached'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_guestService.getRestrictionMessage('scan_limit')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign up for unlimited scans and advanced features!',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                    (route) => false
            ),
            child: const Text('Sign In Now'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  message.length > 100
                      ? '${message.substring(0, 100)}...'
                      : message
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedMethod = null;
          _imageFile = null;
        }
      });
    }
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'AGRIGUARD';
      case 1:
        return 'Analysis Method';
      case 2:
        return 'Image Source';
      case 3:
        return 'Analyzing...';
      default:
        return 'AGRIGUARD';
    }
  }

  String _getProcessingMessage() {
    if (_selectedMethod == 'tflite') {
      return 'Running Dual AI Analysis...\n• Plant Identification\n• Disease Detection';
    }
    return 'Processing...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isProcessing && _currentStep == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentStep > 0) _goBack();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CaptureAppBar(
          currentStep: _currentStep,
          isProcessing: _isProcessing,
          appBarTitle: _getAppBarTitle(),
          onBackPressed: _isProcessing ? null : _goBack,
          onInfoPressed: _currentStep == 0
              ? () => showDialog(
            context: context,
            builder: (context) => const CaptureInfoDialog(),
          )
              : null,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                Color(0xFF0F0F23),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
              ]
                  : [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.9),
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background floating orbs
              ...List.generate(
                8,
                    (i) => FloatingOrb(
                  index: i,
                  maxWidth: MediaQuery.of(context).size.width,
                  fadeController: _fadeController,
                  scaleAnimation: _scaleAnimation,
                ),
              ),

              // Main content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentStep(),
                ),
              ),

              // Processing overlay
              if (_isProcessing)
                ProcessingOverlay(
                  selectedMethod: _selectedMethod ?? '',
                  isProcessing: _isProcessing,
                  isGuestMode: _guestService.isGuestMode,
                  remainingScans: _guestService.remainingScans,
                  pulseAnimation: _pulseAnimation,
                  processingMessage: _getProcessingMessage(),
                  modelStatuses: {
                    'Plant ID': _plantService.isLoaded,
                    'Disease Detection': _diseaseService.isLoaded,
                  },
                  onCancel: () {
                    if (_isProcessing && mounted) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isProcessing = false;
                        _currentStep = 1;
                      });
                    }
                  },
                ),
            ],
          ),
        ),
        floatingActionButton: _currentStep == 0
            ? StartScanButton(
          onPressed: _startScanning,
          animation: _pulseAnimation,
          isGuestMode: _guestService.isGuestMode,
          remainingScans: _guestService.remainingScans,
        )
            : null,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return WelcomeScreen(
          scaleAnimation: _scaleAnimation,
          isGuestMode: _guestService.isGuestMode,
          remainingScans: _guestService.remainingScans,
          modelStatuses: {
            'Plant ID Model': _plantService.isLoaded,
            'Disease Model': _diseaseService.isLoaded,
          },
          onStartScan: _startScanning,
        );
      case 1:
        return MethodSelectionScreen(
          isTFLiteReady: _plantService.isLoaded && _diseaseService.isLoaded,
          loadingText: !_plantService.isLoaded || !_diseaseService.isLoaded
              ? 'Loading AI models...'
              : null,
          onSelectTFLite: () => _selectMethod('tflite'),
          onSelectAPI: () => _selectMethod('api'),
          scrollController: _scrollController,
          modelDetails: {
            'Plant Identification': _plantService.isLoaded,
            'Disease Detection': _diseaseService.isLoaded,
          },
        );
      case 2:
        return SourceSelectionScreen(
          isLoading: _isLoading,
          selectedMethod: _selectedMethod,
          onCameraSelect: () => _pickImage(ImageSource.camera),
          onGallerySelect: () => _pickImage(ImageSource.gallery),
        );
      default:
        return Container();
    }
  }
}