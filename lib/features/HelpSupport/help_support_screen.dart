import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/contact_form_card.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/contact_info_card.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/faq_card.dart';
import 'package:agriguard_fyp/features/HelpSupport/presentation/widgets/custom_app_bar.dart';
import '../../core/constants/app_measurements.dart';
import '../../core/constants/app_routes.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  _HelpAndSupportScreenState createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 600ms
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced from 800ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.ease), // Changed to easeInOut
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate( // Reduced scale from 0.5 to 0.8
      CurvedAnimation(parent: _scaleController, curve: Curves.ease), // Changed to easeInOut
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Changed from Offset(-1.0, 0.0) to subtle vertical slide
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.ease)); // Changed to easeInOut

    // Stagger the animations for better flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scaleController.forward();
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _slideController.forward();
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Help & Support',
        topPadding: 20.0, // Adjust this value for more/less space from top
        onBackPressed: () {
          HapticFeedback.lightImpact();
          Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.profile);
        },      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isTablet = screenWidth > 600;
          final padding = EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: AppMeasurements.defaultPadding,
          );
          final sectionSpacing = screenWidth * 0.04;

          return Container(
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
            child: SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20), // Additional space if needed
                            ContactFormCard(itemSpacing: screenWidth * 0.02),
                            SizedBox(height: sectionSpacing),
                            ContactInfoCard(itemSpacing: screenWidth * 0.02),
                            SizedBox(height: sectionSpacing),
                            FaqCard(itemSpacing: screenWidth * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}