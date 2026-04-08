import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpLink extends StatelessWidget {
  final VoidCallback onPressed;

  const SignUpLink({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 46,                       // reduced from 52
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.12)),
          backgroundColor: theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1_rounded, size: 17, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Create a new account',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}