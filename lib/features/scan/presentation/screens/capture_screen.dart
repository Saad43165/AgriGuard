import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';
import '../../../../core/constants/app_constants.dart';
import '../../../home/presentation/widgets/nav_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
        _scaleController.reset();
        _scaleController.forward();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image captured successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.failedToPickImage),
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
        ),
      );
      debugPrint('Image picker error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndNavigate() async {
    if (_imageFile == null || _isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    try {
      // Save image to permanent storage
      Directory appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('Failed to get documents directory: $e');
        appDir = await getTemporaryDirectory();
      }

      final fileName = 'leaf_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = File('${appDir.path}/$fileName');

      await File(_imageFile!.path).copy(permanentFile.path);

      if (!await permanentFile.exists()) {
        throw Exception('Failed to save image to storage');
      }

      // Simulate AI analysis with delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate mock scan result
      final _ = _generateMockScanResult(permanentFile.path);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan completed successfully!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to edit image screen with the image path
        Navigator.pushNamed(
          context,
          AppRoutes.imageEdit,
          arguments: {'imagePath': permanentFile.path},
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.failedToProcessImage),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
          ),
        );
        debugPrint('Image processing error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Map<String, dynamic> _generateMockScanResult(String imagePath) {
    final diseases = [
      'Leaf Spot Disease',
      'Powdery Mildew',
      'Rust Disease',
      'Bacterial Blight',
      'Anthracnose',
      'Healthy Plant',
      'Mosaic Virus',
      'Leaf Curl',
    ];

    final recommendations = [
      'Apply fungicide spray',
      'Improve air circulation',
      'Remove affected leaves',
      'Use copper-based treatment',
      'Reduce watering frequency',
      'No treatment needed',
      'Apply neem oil',
      'Quarantine the plant',
    ];

    final confidenceLevel = 75 + (DateTime.now().millisecondsSinceEpoch % 25);
    final randomIndex = DateTime.now().millisecondsSinceEpoch % diseases.length;

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'imageUrl': imagePath,
      'result': diseases[randomIndex],
      'confidence': confidenceLevel,
      'recommendation': recommendations[randomIndex],
      'timestamp': DateTime.now().toIso8601String(),
      'severity': randomIndex < 3 ? 'High' : randomIndex < 6 ? 'Medium' : 'Low',
      'treatment': _getTreatmentDetails(diseases[randomIndex]),
    };
  }

  String _getTreatmentDetails(String disease) {
    switch (disease) {
      case 'Leaf Spot Disease':
        return 'Remove infected leaves and apply copper fungicide. Ensure good air circulation.';
      case 'Powdery Mildew':
        return 'Spray with baking soda solution or neem oil. Avoid overhead watering.';
      case 'Rust Disease':
        return 'Apply sulfur-based fungicide and improve plant spacing for better airflow.';
      case 'Bacterial Blight':
        return 'Use copper-based bactericide and avoid watering leaves directly.';
      case 'Anthracnose':
        return 'Prune affected areas and apply preventive fungicide spray.';
      case 'Healthy Plant':
        return 'Continue current care routine. Monitor regularly for any changes.';
      case 'Mosaic Virus':
        return 'Remove infected plants to prevent spread. Control aphid vectors.';
      case 'Leaf Curl':
        return 'Check for pests and environmental stress. Adjust watering schedule.';
      default:
        return 'Consult with a plant specialist for specific treatment recommendations.';
    }
  }

  void _retakeImage() {
    HapticFeedback.lightImpact();
    setState(() => _imageFile = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image cleared. Ready for new capture.'),
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
              const Color(0xFF0F0F23),
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              const Color(0xFF0F0F23),
            ]
                : [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.9),
              Theme.of(context).colorScheme.background.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 50,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Scan Leaf',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                pinned: true,
                actions: [
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppMeasurements.smallPadding,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppMeasurements.borderRadius,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            ],
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppMeasurements.borderRadius,
                            ),
                            onTap: _retakeImage,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: AppMeasurements.defaultPadding),
                    _buildImageSection(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMeasurements.defaultPadding,
      ),
      child: _buildGlassCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
          child: _buildImagePreview(),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppMeasurements.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                  ],
                ),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppMeasurements.defaultPadding),
            Text(
              'No leaf image selected',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            Text(
              'Capture a photo with your camera \n Select from your gallery to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // Slightly higher opacity for better contrast
                fontWeight: FontWeight.w500,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16), // Responsive font size
              ),
              textAlign: TextAlign.center,
              softWrap: true, // Allows text to wrap naturally
              maxLines: 2, // Limits to two lines for consistency
              overflow: TextOverflow.ellipsis, // Handles overflow gracefully
            ),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 3.0,
        child: Stack(
          children: [
            Image.file(
              File(_imageFile!.path),
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppMeasurements.borderRadius,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 60,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppMeasurements.smallPadding),
                      Text(
                        'Failed to load image',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: AppMeasurements.smallPadding,
              left: AppMeasurements.smallPadding,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(
                    AppMeasurements.borderRadius,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Image ready',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildImageButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onPressed: () => _pickImage(ImageSource.camera),
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: AppMeasurements.smallPadding),
                  Expanded(
                    child: _buildImageButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onPressed: () => _pickImage(ImageSource.gallery),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
              if (_imageFile != null)
                const SizedBox(height: AppMeasurements.defaultPadding),
              if (_imageFile != null)
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppMeasurements.borderRadius,
                      ),
                      onTap: _isProcessing ? null : _processAndNavigate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppMeasurements.borderRadius,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: _isProcessing
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Analyzing...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analyze Leaf',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
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

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
            gradient: LinearGradient(
              colors: isPrimary
                  ? [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ]
                  : [
                Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPrimary
                        ? [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ]
                        : [
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppMeasurements.smallPadding),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 1 || !mounted) return;

    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.home);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }
}