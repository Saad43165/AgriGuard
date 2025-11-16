import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_measurements.dart';

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
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final responsivePadding = AppMeasurements.getResponsivePadding(context);
    final baseHeight = (responsivePadding * 4.0 + safeAreaBottom).clamp(56.0, double.infinity);
    final navBarHeight = baseHeight.clamp(56.0, MediaQuery.of(context).size.height * 0.15);

    final colorScheme = Theme.of(context).colorScheme;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final iconSize = AppMeasurements.getResponsiveIconSizeMedium(context);

    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
            selectedFontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11),
            unselectedFontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            currentIndex: selectedIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              onTap(index);
            },
            items: [
              _buildNavItemBottomNav(
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
                colorScheme,
                smallPadding,
                iconSize,
              ),
              _buildNavItemBottomNav(
                Icons.search_outlined,
                Icons.search_rounded,
                'Scan',
                colorScheme,
                smallPadding,
                iconSize,
              ),
              _buildNavItemBottomNav(
                Icons.person_outline,
                Icons.person_rounded,
                'Profile',
                colorScheme,
                smallPadding,
                iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItemBottomNav(
      IconData icon,
      IconData activeIcon,
      String label,
      ColorScheme colorScheme,
      double smallPadding,
      double iconSize,
      ) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: iconSize, color: colorScheme.onSurface.withOpacity(0.7)),
      activeIcon: Container(
        padding: EdgeInsets.all(smallPadding * 0.45),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary,
        ),
        child: Icon(activeIcon, size: iconSize, color: colorScheme.onPrimary),
      ),
      label: label,
    );
  }
}