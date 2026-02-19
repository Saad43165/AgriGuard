import 'package:flutter/material.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final bool isHighlight;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? const Color(0xFF8B5CF6);
    final effectiveValueColor = valueColor ?? (isDark ? Colors.white : Colors.black87);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container
        Container(
          padding: EdgeInsets.all(isHighlight ? 12 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                effectiveIconColor.withOpacity(0.2),
                effectiveIconColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(isHighlight ? 14 : 12),
            border: Border.all(
              color: effectiveIconColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: isHighlight
                ? [
              BoxShadow(
                color: effectiveIconColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: isHighlight ? 28 : 24,
          ),
        ),
        const SizedBox(width: 16),
        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isHighlight ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.4),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 20 : 16,
                  fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
                  color: effectiveValueColor,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}