import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';
import '../models/onboarding_data.dart';
import '../widgets/onboarding_action_button.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/onboarding_page_view.dart';
import '../widgets/completion_overlay.dart';
import '../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _completionController;

  int _currentPage = 0;
  bool _isCompleting = false;
  final List<OnboardingData> _pages = OnboardingData.pages;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _completionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
  }

  void _onSkip() {
    HapticFeedback.mediumImpact();
    _navigateToLogin();
  }

  void _onNext() {
    HapticFeedback.lightImpact();

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPrevious() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onDotTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isCompleting = true);
    HapticFeedback.mediumImpact();

    await _completionController.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.of(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // Solid background
          Container(color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF)),

          SafeArea(
            child: Column(
              children: [
                // Modern App Bar
                ModernAppBar(
                  onSkip: _onSkip,
                  currentPage: _currentPage,
                  totalPages: _pages.length,
                ),

                // Main Content - FIXED: Wrapped in Expanded with proper constraints
                Expanded(
                  child: OnboardingPageView(
                    pageController: _pageController,
                    pages: _pages,
                    currentPage: _currentPage,
                    onPageChanged: _onPageChanged,
                  ),
                ),

                // Bottom Section - FIXED: Removed extra space
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page Indicators
                      ModernPageIndicators(
                        currentPage: _currentPage,
                        pageCount: _pages.length,
                        onDotTapped: _onDotTapped,
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      ModernActionButtons(
                        currentPage: _currentPage,
                        totalPages: _pages.length,
                        onNext: _onNext,
                        onPrevious: _onPrevious,
                        isCompleting: _isCompleting,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Completion Overlay
          if (_isCompleting)
            CompletionOverlay(
              controller: _completionController,
            ),
        ],
      ),
    );
  }
}