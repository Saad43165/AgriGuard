import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../services/plant_id_service.dart';
import '../../Navbar/presentation/nav_bar.dart';
import '../../Profile/presentation/Components/floating_orb.dart';
import '../../home/screens/components/scan_service.dart';
import 'components/app_bar_content.dart';
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

  // ---------- ANIMATIONS ----------
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();

  // ---------- PLANT-ID ----------
  final PlantIdService _plantService = PlantIdService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // LOAD MODEL ON START
    _plantService.loadModel().then((_) {
      debugPrint('AI MODEL LOADED & READY');
    }).catchError((e) {
      debugPrint('Model load error: $e');
      // Don't show error - fallback will handle it
    });
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
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _plantService.close();
    super.dispose();
  }

  // -------------------------------------------------
  // IMAGE PICKER
  // -------------------------------------------------
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
      debugPrint('Image picker error: $e');
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Failed to pick image. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // -------------------------------------------------
  // PROCESS + AI + SAVE + NAVIGATE
  // -------------------------------------------------
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

      // AI INFERENCE
      Map<String, double> aiResult;
      try {
        aiResult = await _plantService.predict(imageFile);
        debugPrint('AI Prediction successful: ${aiResult.keys.first}');
      } catch (e) {
        debugPrint('AI Prediction failed, using fallback: $e');
        aiResult = {'Unknown Plant': 0.5};
      }

      if (!mounted) return;

      final plantName = aiResult.keys.first;
      final confidence = (aiResult.values.first * 100).toStringAsFixed(1);

      // Create complete scan data
      final scanData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'status': 'identified',
        'cropType': plantName,
        'diagnosis': 'Healthy $plantName plant identified',
        'confidence': confidence,
        'treatment': 'Continue regular care. Monitor for any signs of disease or pests. Ensure adequate water and sunlight.',
        'severity': 'Healthy',
        'imagePath': _imageFile!.path,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'isFallback': _plantService.isModelFailed,
      };

      debugPrint('Saving scan data: ${scanData['cropType']}');

      // Save to database
      try {
        final scanId = await ScanService().saveScan(scanData);
        debugPrint('Scan saved with ID: $scanId');

        // Add the ID to scanData for navigation
        scanData['id'] = scanId;
      } catch (e) {
        debugPrint('Error saving scan: $e');
        // Continue anyway - we can still show results
      }

      if (!mounted) return;

      // Navigate to results screen
      // Use pushReplacement to prevent back navigation issues
      await Navigator.pushReplacementNamed(
        context,
        AppRoutes.results,
        arguments: {'scanData': scanData},
      );

      // Note: Don't show SnackBar after navigation - the widget will be disposed

    } catch (e) {
      debugPrint('Process error: $e');

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() => _isProcessing = false);

      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Helper method to show error messages
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
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

  // -------------------------------------------------
  // RETAKE & NAVIGATION
  // -------------------------------------------------
  void _retakeImage() {
    if (!mounted) return;

    HapticFeedback.lightImpact();
    setState(() => _imageFile = null);
  }

  void _handleNavigation(int index) {
    if (index == 1 || !mounted || _isProcessing) return;

    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.profile);
        break;
    }
  }

  // -------------------------------------------------
  // BUILD UI
  // -------------------------------------------------
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
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.background.withOpacity(0.9),
                Theme.of(context).colorScheme.background.withOpacity(0.8),
                Theme.of(context).colorScheme.background,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Floating orbs background
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
        bottomNavigationBar: _isProcessing
            ? null
            : BottomNavBar(
          selectedIndex: 1,
          onTap: _handleNavigation,
        ),
      ),
    );
  }
}