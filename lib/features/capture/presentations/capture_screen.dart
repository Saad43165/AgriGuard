import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_routes.dart';
import '../../Navbar/presentation/nav_bar.dart';
import '../../Profile/presentation/Components/floating_orb.dart';
import '../../home/presentation/screens/components/scan_service.dart';
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image captured successfully!'),
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              ),
            );
          }
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image: $e'),
              backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.9),
            ),
          );
        }
      });
      debugPrint('Image picker error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndSendToEditScreen() async {
    if (_imageFile == null || _isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in.');
      }

      // Convert XFile to File
      final imageFile = File(_imageFile!.path);

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Selected image file does not exist');
      }

      // Create scan data
      final scanData = {
        'status': 'pending',
        'diagnosis': null,
        'confidence': null,
        'treatment': null,
        'cropType': null,
      };

      // Save scan using ScanService (will store image locally)
      await ScanService().saveScan(scanData, imageFile: imageFile);

      // Navigate to edit screen with the local file path
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.imageEdit,
          arguments: {
            'imagePath': _imageFile!.path, // Use original path for immediate access
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'isLocalImage': true, // Mark as local image
          },
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved locally!'),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: ${e.toString()}'),
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

  void _retakeImage() {
    HapticFeedback.lightImpact();
    setState(() => _imageFile = null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image cleared. Ready for new capture.'),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          ),
        );
      }
    });
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
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  AppBarContent(imageFile: _imageFile, onRetake: _retakeImage),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        ImageSection(
                          imageFile: _imageFile,
                          scaleAnimation: _scaleAnimation,
                          isLoading: _isLoading,
                        ),
                        ActionButtons(
                          isLoading: _isLoading,
                          isProcessing: _isProcessing,
                          imageFile: _imageFile,
                          onPickImage: _pickImage,
                          onProcess: _processAndSendToEditScreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onTap: _handleNavigation,
      ),
    );
  }
}