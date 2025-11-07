// lib/core/Species_widgets/severity_indicator.dart
import 'package:flutter/material.dart';

/// A widget that displays a severity level with color-coded styling.
/// Accepts a severity string (e.g., 'Low', 'Moderate', 'High', 'Unknown') and
/// renders it with appropriate colors and an optional icon.
class SeverityIndicator extends StatelessWidget {
  final String severity;

  const SeverityIndicator({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    // Map severity levels to colors and icons
    final Map<String, (Color, IconData?)> severityConfig = {
      'Low': (Colors.green, Icons.check_circle_outline),
      'Moderate': (Colors.orange, Icons.warning_amber),
      'High': (Colors.red, Icons.error_outline),
      'Unknown': (Colors.grey, Icons.help_outline),
    };

    // Get config for the provided severity, default to 'Unknown' if not found
    final (color, icon) =
        severityConfig[severity] ?? severityConfig['Unknown']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            severity,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}