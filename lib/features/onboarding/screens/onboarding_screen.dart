import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  final List<OnboardingData> _pages = OnboardingData.pages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() => _navigateToLogin();
  void _navigateToLogin() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
    _navigateToLogin();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingTopBar(
              onSkip: _onSkip,
              currentPage: _currentPage,
              totalPages: _pages.length,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, i) => OnboardingPageContent(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PageIndicators(
                    currentPage: _currentPage,
                    pageCount: _pages.length,
                    pageController: _pageController,
                  ),
                  const SizedBox(height: 32),
                  OnboardingActionButton(
                    onPressed: _onNext,
                    isLastPage: _currentPage == _pages.length - 1,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}