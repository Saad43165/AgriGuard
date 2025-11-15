// lib/widgets/top_bar.dart
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
            _glassButton(
              onPressed: onBack,
              child: const Icon(Icons.arrow_back_rounded, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onSearch,
                child: _glassContainer(
                  child: Row(
                    children: const [
                      Icon(Icons.search_rounded, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Search location...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassButton({required VoidCallback onPressed, required Widget child}) {
    return Container(
      decoration: _glassDecoration(),
      child: IconButton(
        icon: child,
        onPressed: onPressed,
        color: Colors.white,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: _glassDecoration(),
      child: child,
    );
  }

  BoxDecoration _glassDecoration() => BoxDecoration(
    color: Colors.white.withOpacity(0.25),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}