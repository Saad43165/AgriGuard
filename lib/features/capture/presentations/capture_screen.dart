import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../services/plant_id_service.dart';
import '../../Profile/presentation/Components/floating_orb.dart';
import 'components/capture_appbar.dart';
import 'components/image_section.dart';
import 'components/action_buttons.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isProcessing = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();

  final PlantIdService _plantService = PlantIdService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      debugPrint('🌱 Initializing plant identification model...');
      await _plantService.loadModel();

      if (_plantService.isLoaded) {
        debugPrint('✅ Model loaded successfully');
      } else {
        debugPrint('⚠️ Model failed to load');
        if (mounted) {
          _showErrorSnackBar('Model initialization failed. Some features may not work.');
        }
      }
    } catch (e) {
      debugPrint('❌ Model initialization error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load AI model. Please restart the app.');
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _plantService.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;

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
        _scaleController.reset();
        _scaleController.forward();
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Failed to pick image. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processAndSendToResults() async {
    if (!mounted || _imageFile == null || _isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in to continue');
      }

      // Verify image file exists
      final imageFile = File(_imageFile!.path);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      debugPrint('📸 Processing image: ${imageFile.path}');

      // Run AI prediction
      Map<String, dynamic> predictionResult;
      try {
        // FIXED: Changed from Map<String, double> to Map<String, dynamic>
        predictionResult = await _plantService.predict(imageFile);
        debugPrint('✅ AI Prediction successful');
        debugPrint('   Label: ${predictionResult['label']}');
        debugPrint('   Confidence: ${predictionResult['confidence']}');
        
        // Optional: Run diagnostics if prediction seems wrong
        if (predictionResult['confidence'] < 0.3) {
          debugPrint('⚠️ Low confidence detected, running diagnostics...');
          await _plantService.runDiagnostics(imageFile);
        }
        
      } catch (e) {
        debugPrint('❌ AI Prediction failed: $e');
        // Use fallback
        predictionResult = {
          'label': 'Unknown Plant',
          'confidence': 0.5,
          'isUnknown': true,
          'allPredictions': [],
          'inferenceTime': 0,
        };
      }

      if (!mounted) return;

      // Extract results
      final plantName = predictionResult['label'] as String;
      final confidence = predictionResult['confidence'] as double;
      final isUnknown = predictionResult['isUnknown'] as bool? ?? false;
      final confidencePercent = (confidence * 100).toStringAsFixed(1);

      // Determine diagnosis based on confidence
      String diagnosis;
      String severity;
      String treatment;

      if (isUnknown || confidence < 0.5) {
        diagnosis = 'Unable to identify plant with confidence';
        severity = 'Unknown';
        treatment = 'Please try taking a clearer photo focusing on distinctive features like leaves, flowers, or stems.';
      } else {
        diagnosis = 'Healthy $plantName plant identified';
        severity = 'Healthy';
        treatment = 'Continue regular care. Monitor for any signs of disease or pests. Ensure adequate water and sunlight.';
      }

      // Create complete scan data
      final scanData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'status': 'identified',
        'cropType': plantName,
        'diagnosis': diagnosis,
        'confidence': confidencePercent,
        'treatment': treatment,
        'severity': severity,
        'imagePath': _imageFile!.path,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'fromCapture': true,
        'previousRoute': AppRoutes.scan,
        'isUnknown': isUnknown,
        'allPredictions': predictionResult['allPredictions'] ?? [],
        'inferenceTime': predictionResult['inferenceTime'] ?? 0,
      };

      debugPrint('📊 Navigating to results with:');
      debugPrint('   Plant: $plantName');
      debugPrint('   Confidence: $confidencePercent%');
      debugPrint('   Unknown: $isUnknown');

      if (!mounted) return;

      // Navigate to results screen
      await Navigator.pushNamed(
        context,
        AppRoutes.results,
        arguments: {'scanData': scanData},
      );

      // Reset when returning from results
      if (mounted) {
        setState(() {
          _imageFile = null;
          _isProcessing = false;
        });
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Process error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() => _isProcessing = false);

      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
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

  void _retakeImage() {
    if (!mounted) return;

    HapticFeedback.lightImpact();
    setState(() => _imageFile = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (didPop) {
        if (!didPop && _isProcessing) {
          _showErrorSnackBar('Please wait for processing to complete');
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [
                      Color(0xFF0F0F23),
                      Color(0xFF16213E),
                      Color(0xFF1A1A2E),
                      Color(0xFF0F0F23),
                    ]
                  : [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      Theme.of(context).colorScheme.surface,
                    ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Floating orbs for decoration
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
              FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: _isProcessing
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  slivers: [
                    AppBarContent(
                      imageFile: _imageFile,
                      onRetake: _isProcessing ? null : _retakeImage,
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          ImageSection(
                            imageFile: _imageFile,
                            scaleAnimation: _scaleAnimation,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 30),
                          ActionButtons(
                            isLoading: _isLoading,
                            isProcessing: _isProcessing,
                            imageFile: _imageFile,
                            onPickImage: _pickImage,
                            onProcess: _processAndSendToResults,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Processing overlay
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(32),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Analyzing plant...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take a few seconds',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}