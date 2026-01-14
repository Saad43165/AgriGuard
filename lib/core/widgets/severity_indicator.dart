// lib/core/species/severity_indicator.dart
import 'package:flutter/material.dart';

/// A widget that displays a severity level with color-coded styling.
/// Accepts a severity string (e.g., 'Low', 'Moderate', 'High', 'Unknown') and
/// renders it with appropriate colors and an optional icon.
class SeverityIndicator extends StatelessWidget {
  final String severity;
  final bool showLabel;
  final bool showDescription;
  final Color? customColor;

  const SeverityIndicator({
    super.key,
    required this.severity,
    this.showLabel = true,
    this.showDescription = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    // Map severity levels to colors, icons, and descriptions
    final Map<String, (Color, IconData?, String)> severityConfig = {
      'Low': (Colors.green, Icons.check_circle_outline, 'Low risk - Minor intervention needed'),
      'Moderate': (Colors.orange, Icons.warning_amber, 'Medium risk - Regular monitoring required'),
      'High': (Colors.red, Icons.error_outline, 'High risk - Immediate action needed'),
      'Medium': (Colors.orange, Icons.warning_amber, 'Medium risk - Regular monitoring required'),
      'None': (Colors.blue, Icons.check_circle, 'No issues detected'),
      'Unknown': (Colors.grey, Icons.help_outline, 'Severity unknown'),
    };

    // Normalize severity string (capitalize first letter)
    String normalizedSeverity = severity;
    if (severity.isNotEmpty) {
      normalizedSeverity = severity[0].toUpperCase() + severity.substring(1).toLowerCase();
    }

    // Get config for the provided severity, default to 'Unknown' if not found
    final (defaultColor, icon, description) =
        severityConfig[normalizedSeverity] ?? severityConfig['Unknown']!;

    final Color color = customColor ?? defaultColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Severity label and icon
          Row(
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
              if (showLabel) ...[
                Text(
                  normalizedSeverity,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          // Description (optional)
          if (showDescription && description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}