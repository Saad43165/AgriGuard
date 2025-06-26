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

class _CaptureScreenState extends State<CaptureScreen> with TickerProviderStateMixin {
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isProcessing = false;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
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
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
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
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.9),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.failedToPickImage),
          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.9),
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

      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await Navigator.pushNamed(
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
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.9),
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

  void _retakeImage() {
    HapticFeedback.lightImpact();
    setState(() => _imageFile = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image cleared. Ready for new capture.'),
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.9),
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
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: const Color(0xFF00D4AA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
          secondary: Color(0xFF6C63FF),
          surface: Color(0xFF1A1A2E),
          background: Color(0xFF16213E),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F23),
                Color(0xFF16213E),
                Color(0xFF1A1A2E),
                Color(0xFF0F0F23),
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
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
                      ).createShader(bounds),
                      child: const Text(
                        'Scan Leaf',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0F0F23),
                            Color(0xFF1A1A2E),
                          ],
                        ),
                      ),
                    ),
                  ),
                  pinned: true,
                  actions: [
                    if (_imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppMeasurements.smallPadding),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.2),
                                Colors.purple.withOpacity(0.2),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                              onTap: _retakeImage,
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFF00D4AA),
                                  size: 24,
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
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
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
                    const Color(0xFF00D4AA).withOpacity(0.2),
                    const Color(0xFF6C63FF).withOpacity(0.2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 60,
                color: Color(0xFF00D4AA),
              ),
            ),
            const SizedBox(height: AppMeasurements.defaultPadding),
            Text(
              'No leaf image selected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppMeasurements.smallPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
              child: Text(
                'Capture a photo with your camera or select one from your gallery to get started',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image_rounded,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: AppMeasurements.smallPadding),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00D4AA),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Image ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
              if (_imageFile != null) const SizedBox(height: AppMeasurements.defaultPadding),
              if (_imageFile != null)
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                      onTap: _isProcessing ? null : _processAndNavigate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
                          ),
                        ),
                        child: _isProcessing
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_fix_high_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analyze Leaf',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                const Color(0xFF00D4AA).withOpacity(0.2),
                const Color(0xFF6C63FF).withOpacity(0.2),
              ]
                  : [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF00D4AA).withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
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
                      const Color(0xFF00D4AA),
                      const Color(0xFF6C63FF),
                    ]
                        : [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppMeasurements.smallPadding),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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