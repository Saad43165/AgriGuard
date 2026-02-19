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
      decoration: _glassDecoration(),
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
          decoration: _glassDecoration(),
          child: Row(
            children: const [
              Icon(
                Icons.search_rounded,
                size: 22,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              SizedBox(width: 12),
              Text(
                'Search location...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
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

  BoxDecoration _glassDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0.25),
        Colors.black.withOpacity(0.15),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.35),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}