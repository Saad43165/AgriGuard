import 'package:flutter/material.dart';
import 'app_themes.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isRounded;
  final Color? backgroundColor;
  final List<BoxShadow>? shadow;

  const AppLogo({
    super.key,
    this.size = 72,
    this.isRounded = true,
    this.backgroundColor,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: isRounded ? BorderRadius.circular(size * 0.28) : null,
        shape: isRounded ? BoxShape.rectangle : BoxShape.circle,
        boxShadow: shadow ?? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isRounded ? BorderRadius.circular(size * 0.28) : BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
