import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F5F5),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Container(
        height: 75 + safeAreaBottom,
        color: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F5F5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: safeAreaBottom + 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Home Button - Rounded from right
                    Expanded(
                      child: _buildHomeButton(
                        context: context,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Scan Button - Rounded all sides (unique shape)
                    _buildScanButton(
                      context: context,
                      isDark: isDark,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(width: 6),

                    // Profile Button - Rounded from left
                    Expanded(
                      child: _buildProfileButton(
                        context: context,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Home Button - Rounded from right side
  Widget _buildHomeButton({
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final isSelected = selectedIndex == 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 58,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          )
              : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              const Color(0xFF1F1F3A).withOpacity(0.6),
              const Color(0xFF1A1A2E).withOpacity(0.8),
            ]
                : [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.3)
                : (isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.25)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_rounded,
              size: 24,
              color: isSelected
                  ? Colors.white
                  : (isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5)),
            ),
            const SizedBox(height: 3),
            Text(
              'Home',
              style: TextStyle(
                fontSize: 10.5,
                height: 1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5)),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Scan Button - Unique rounded shape (elevated circle)
  Widget _buildScanButton({
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final isSelected = selectedIndex == 1;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap(1);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.75),
            ],
          )
              : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              const Color(0xFF1F1F3A).withOpacity(0.6),
              const Color(0xFF1A1A2E).withOpacity(0.8),
            ]
                : [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.4)
                : (isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.35)
                  : Colors.black.withOpacity(isDark ? 0.25 : 0.1),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 26,
              color: isSelected
                  ? Colors.white
                  : (isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5)),
            ),
            const SizedBox(height: 2),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 9.5,
                height: 1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5)),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile Button - Rounded from left side
  Widget _buildProfileButton({
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final isSelected = selectedIndex == 2;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(2);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 58,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          )
              : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              const Color(0xFF1F1F3A).withOpacity(0.6),
              const Color(0xFF1A1A2E).withOpacity(0.8),
            ]
                : [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.3)
                : (isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.25)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_rounded,
              size: 24,
              color: isSelected
                  ? Colors.white
                  : (isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5)),
            ),
            const SizedBox(height: 3),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 10.5,
                height: 1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5)),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}