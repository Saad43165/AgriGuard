import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_measurements.dart';

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
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final baseHeight = AppMeasurements.getResponsivePadding(context) * 4.0 + safeAreaBottom;

    // Ensure nav bar height doesn't exceed available space
    final navBarHeight = baseHeight.clamp(
      AppMeasurements.getResponsivePadding(context) * 3.0 + safeAreaBottom, // Minimum height
      screenHeight * 0.15, // Maximum 15% of screen height to avoid overflow
    );

    return SizedBox(
      height: navBarHeight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: EdgeInsets.only(bottom: safeAreaBottom),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final iconSize = AppMeasurements.getResponsiveIconSizeMedium(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          onTap: () => _handleTap(context, index),
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: smallPadding * 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.all(smallPadding * 0.45),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? colorScheme.primary : Colors.transparent,
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: iconSize,
                    color: isActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11),
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent text overflow
                  maxLines: 1, // Limit to one line
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    if (index == selectedIndex) {
      // Optional: Scroll to top if already on the same tab
      return;
    }

    HapticFeedback.lightImpact();

    if (onTap != null) {
      onTap!(index);
    } else {
      _navigateToRoute(context, index);
    }
  }

  void _navigateToRoute(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    String targetRoute;

    switch (index) {
      case 0:
        targetRoute = AppRoutes.home;
        break;
      case 1:
        targetRoute = AppRoutes.scan;
        break;
      case 2:
        targetRoute = AppRoutes.profile;
        break;
      default:
        targetRoute = AppRoutes.home;
    }

    if (currentRoute != targetRoute) {
      // Preserve existing arguments or add new ones if needed
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (Navigator.canPop(context)) {
        Navigator.pushReplacementNamed(
          context,
          targetRoute,
          arguments: arguments,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          targetRoute,
              (route) => false,
          arguments: arguments,
        );
      }
    }
  }
}