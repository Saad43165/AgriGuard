import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_themes.dart';

// Navbar indices:
// 0=Home | 1=History | 2=Camera(action) | 3=AI Chat | 4=Profile
class BottomNavBar extends StatelessWidget {
  final int selectedIndex; // uses the navbar index (0,1,3,4 are real tabs; 2 is camera)
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
                  label: 'Home', navIndex: 0, selectedIndex: selectedIndex,
                  isDark: isDark, onTap: onTap),
              _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history_rounded,
                  label: 'History', navIndex: 1, selectedIndex: selectedIndex,
                  isDark: isDark, onTap: onTap),
              // Center camera FAB
              _CameraButton(onTap: () {
                HapticFeedback.mediumImpact();
                onTap(2);
              }),
              _NavItem(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded,
                  label: 'AI Chat', navIndex: 3, selectedIndex: selectedIndex,
                  isDark: isDark, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'Profile', navIndex: 4, selectedIndex: selectedIndex,
                  isDark: isDark, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int navIndex, selectedIndex;
  final bool isDark;
  final Function(int) onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.navIndex, required this.selectedIndex, required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == navIndex;
    final color = isSelected ? AppColors.primary
        : (isDark ? AppColors.darkCaption : const Color(0xFF9E9E9E));

    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(navIndex); },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            )),
          ],
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CameraButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
