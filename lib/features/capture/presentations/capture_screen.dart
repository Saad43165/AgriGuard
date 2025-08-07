import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../Navbar/presentation/nav_bar.dart';
import '../../Profile/presentation/Components/floating_orb.dart';
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.9),
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
              content: const Text('Failed to pick image'),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.error.withOpacity(0.9),
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

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.imageEdit,
          arguments: {'imagePath': permanentFile.path},
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to process image'),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.error.withOpacity(0.9),
              ),
            );
          }
        });
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
            backgroundColor: Theme.of(
              context,
            ).colorScheme.secondary.withOpacity(0.9),
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
            colors:
                Theme.of(context).brightness == Brightness.dark
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
