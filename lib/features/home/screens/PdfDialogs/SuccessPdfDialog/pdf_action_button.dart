import 'package:flutter/material.dart';

class PdfActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;
  final bool isDark;

  const PdfActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF059669)
                : (isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(8),
            border: isPrimary
                ? null
                : Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF1F2937)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}