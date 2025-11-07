import 'package:flutter/material.dart';

class PageIndicators extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final PageController? pageController;

  const PageIndicators({
    super.key,
    required this.currentPage,
    required this.pageCount,
    this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => GestureDetector(
          onTap: () => pageController?.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: currentPage == index ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: currentPage == index
                  ? LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              )
                  : null,
              color: currentPage == index
                  ? null
                  : colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }
}