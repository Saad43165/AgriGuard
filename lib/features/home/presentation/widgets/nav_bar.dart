// lib/features/home/presentation/widgets/nav_bar.dart
import 'package:flutter/material.dart';
import 'package:agriguard_fyp/Profile/presentation/screens/profile_screen.dart';
import 'package:agriguard_fyp/features/scan/presentation/screens/capture_screen.dart';
import 'package:agriguard_fyp/features/home/presentation/screens/home_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap; // Made optional with nullable type

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap ?? (index) => _handleNavigation(context, index), // Default to internal navigation if no callback
          elevation: 1,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            height: 1.5,
          ),
          items: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_filled,
              label: 'Home',
              isActive: selectedIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.camera_alt_outlined,
              activeIcon: Icons.camera_alt,
              label: 'Scan',
              isActive: selectedIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isActive: selectedIndex == 2,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: isActive
            ? Icon(activeIcon, key: ValueKey('active-$icon'))
            : Icon(icon, key: ValueKey('inactive-$icon')),
      ),
      label: label,
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (index == selectedIndex) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          switch (index) {
            case 0:
              return const HomeScreen();
            case 1:
              return CaptureScreen();
            case 2:
              return const ProfileScreen();
            default:
              return const HomeScreen();
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
          (route) => false,
    );
  }
}