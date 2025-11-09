import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_measurements.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/floating_orb.dart';
import '../models/onboarding_data.dart';
import '../widgets/onboarding_top_bar.dart';
import '../widgets/onboarding_page_content.dart';
import '../widgets/onboarding_action_button.dart';
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
  late AnimationController _orbController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _currentPage = 0;
  bool _isLoading = false;
  bool _isTransitioning = false;
  final List<OnboardingData> _pages = OnboardingData.pages;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Orb animation
    _orbController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set status bar style after dependencies are available
    _updateStatusBar();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  void _updateStatusBar() {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  void _onSkip() {
    if (_isTransitioning) return;
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (!mounted) return;

    setState(() => _isTransitioning = true);
    _fadeController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  void _onNext() async {
    if (_isTransitioning || _isLoading) return;

    // Haptic feedback for better UX
    HapticFeedback.lightImpact();

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    // Add slight delay for better UX
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _navigateToLogin();
  }

  void _onPageChanged(int index) {
    if (_isTransitioning) return;

    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
  }

  void _onDotTapped(int index) {
    if (_isTransitioning || index == _currentPage) return;

    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppMeasurements.isLargeScreen(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Floating orbs background
          ...List.generate(
            3,
                (index) => FloatingOrb(
              index: index,
              maxWidth: screenWidth,
              fadeController: _orbController,
              scaleAnimation: _scaleAnimation,
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Top bar with logo and skip button
                  OnboardingTopBar(
                    onSkip: _onSkip,
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                  ),

                  // Main content with page view
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                            }
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: value,
                                child: child,
                              ),
                            );
                          },
                          child: OnboardingPageContent(data: _pages[index]),
                        );
                      },
                    ),
                  ),

                  // Bottom section with indicators and action button
                  Container(
                    padding: EdgeInsets.all(
                      AppMeasurements.getResponsivePadding(context),
                    ),
                    child: Column(
                      children: [
                        // Page indicators with tap functionality
                        PageIndicators(
                          currentPage: _currentPage,
                          pageCount: _pages.length,
                          pageController: _pageController,
                          onDotTapped: _onDotTapped,
                        ),

                        SizedBox(
                          height: AppMeasurements.getResponsiveSize(
                            context,
                            baseSize: isLargeScreen ? 40 : 32,
                          ),
                        ),

                        // Action button (Next/Get Started)
                        OnboardingActionButton(
                          onPressed: _onNext,
                          isLastPage: _currentPage == _pages.length - 1,
                          isLoading: _isLoading,
                        ),

                        // Optional: Add a hint for swiping on first page
                        if (_currentPage == 0)
                          Padding(
                            padding: EdgeInsets.only(
                              top: AppMeasurements.smallPadding,
                            ),
                            child: AnimatedOpacity(
                              opacity: 0.6,
                              duration: const Duration(milliseconds: 300),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.swipe_rounded,
                                    size: AppMeasurements.getResponsiveIconSizeSmall(context),
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  SizedBox(width: AppMeasurements.extraSmallPadding),
                                  Text(
                                    'Swipe to explore',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: AppMeasurements.getResponsiveFontSize(
                                        context,
                                        baseSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}