import 'package:flutter/material.dart';

import '../../../core/constants/app_measurements.dart';

class PageIndicators extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final PageController? pageController;
  final Function(int)? onDotTapped;

  const PageIndicators({
    super.key,
    required this.currentPage,
    required this.pageCount,
    this.pageController,
    this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => GestureDetector(
          onTap: () {
            // Use the callback if provided, otherwise fallback to pageController
            if (onDotTapped != null) {
              onDotTapped!(index);
            } else if (pageController != null) {
              pageController!.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(
              horizontal: AppMeasurements.getResponsiveExtraSmallPadding(context) / 2,
            ),
            width: currentPage == index
                ? (isLargeScreen ? 40 : 32)
                : (isLargeScreen ? 10 : 8),
            height: isLargeScreen ? 10 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppMeasurements.getResponsiveBorderRadius(context) / 2,
              ),
              gradient: currentPage == index
                  ? LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
                  : null,
              color: currentPage == index
                  ? null
                  : colorScheme.primary.withOpacity(0.2),
              boxShadow: currentPage == index
                  ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}