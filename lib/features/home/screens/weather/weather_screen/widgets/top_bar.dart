import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final Color weatherColor;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  const TopBar({
    super.key,
    required this.weatherColor,
    required this.onBack,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            _buildButton(
              onPressed: onBack,
              child: const Icon(Icons.arrow_back_rounded, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSearchBar(onSearch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required VoidCallback onPressed, required Widget child}) {
    return Container(
      decoration: _premiumDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: _premiumDecoration(),
          child: Row(
            children: const [
              Icon(
                Icons.search_rounded,
                size: 22,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              SizedBox(width: 12),
              Text(
                'Search location...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _premiumDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withValues(alpha: 0.3),
        Colors.black.withValues(alpha: 0.2),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.35),
      width: 2,
    ),
  );
}