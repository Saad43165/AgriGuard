import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';
import 'onboarding_page_content.dart';

class OnboardingPageView extends StatelessWidget {
  final PageController pageController;
  final List<OnboardingData> pages;
  final int currentPage;
  final Function(int) onPageChanged;

  const OnboardingPageView({
    super.key,
    required this.pageController,
    required this.pages,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: pageController,
          builder: (context, child) {
            double value = 1.0;
            if (pageController.position.haveDimensions) {
              value = (pageController.page ?? 0) - index;
              value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
            }

            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: InteractivePageContent(
            data: pages[index],
            isActive: currentPage == index,
          ),
        );
      },
    );
  }
}