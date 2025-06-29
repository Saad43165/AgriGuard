import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  label: 'Scan',
                  index: 1,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: () => _handleTap(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? colorScheme.primary.withOpacity(0.2) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? colorScheme.primary : Colors.transparent,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive
                    ? colorScheme.onPrimary
                    : isLightMode
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive
                    ? colorScheme.primary
                    : isLightMode
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (index == selectedIndex) return;

    HapticFeedback.lightImpact();

    if (onTap != null) {
      onTap!(index);
    } else {
      _navigateToRoute(context, index);
    }
  }

  void _navigateToRoute(BuildContext context, int index) {
    String routeName;
    switch (index) {
      case 0:
        routeName = AppRoutes.home;
        break;
      case 1:
        routeName = AppRoutes.scan;
        break;
      case 2:
        routeName = AppRoutes.profile;
        break;
      default:
        routeName = AppRoutes.home;
    }

    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: ModalRoute.of(context)?.settings.arguments,
      );
    }
  }
}