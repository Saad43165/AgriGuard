import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_measurements.dart';

class HistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> scan;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback? onTap; // Add this

  const HistoryCardWidget({
    super.key,
    required this.scan,
    required this.index,
    required this.onDelete,
    this.onTap, // Add this
  });

  // Check if scan is advanced
  bool _isAdvancedScan() {
    return scan['isAdvanced'] as bool? ??
        scan['scanType']?.toString() == 'advanced' ||
            scan['analysisSource']?.toString() == 'groq' ||
            scan['analysisSource']?.toString() == 'huggingface' ||
            scan['analysisSource']?.toString() == 'plantid' ||
            scan['analysisSource']?.toString() == 'plantId';
  }

  // Format date
  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      DateTime? dt;
      if (date is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(date);
      } else if (date is String) {
        dt = DateTime.tryParse(date);
      } else if (date is DateTime) {
        dt = date;
      }
      return dt != null ? DateFormat('MMM dd, yyyy').format(dt) : 'Invalid';
    } catch (_) {
      return 'Error';
    }
  }

  // Get severity color
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      case 'healthy':
      case 'none':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Navigation handlers - FIXED: Use the onTap callback instead of local navigation
  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();

    // IMPORTANT: Use the provided onTap callback which comes from HistoryScreen
    // This ensures proper data is passed with all history flags
    if (onTap != null) {
      onTap!();
    } else {
      // Fallback: Show error if onTap is not provided
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Navigation not configured'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // REMOVE THESE METHODS - They are causing the problem!
  // The navigation should be handled by HistoryScreen, not HistoryCardWidget
  // void _navigateToAdvancedResults(BuildContext context) {
  //   // REMOVED - This causes duplicates because it doesn't pass IDs properly
  // }

  // void _navigateToRegularResults(BuildContext context) {
  //   // REMOVED - This causes duplicates because it doesn't pass IDs properly
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdvanced = _isAdvancedScan();
    final diagnosis = scan['diagnosis']?.toString() ?? 'Unknown';
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final severity = scan['severity']?.toString() ?? 'Medium';
    final confidence = scan['confidence']?.toString() ?? '0';
    final date = _formatDate(scan['timestamp'] ?? scan['scanDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdvanced
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: isAdvanced ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Plant name and advanced badge
                    Row(
                      children: [
                        Text(
                          plantName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: AppMeasurements.getResponsiveFontSize(
                                context, baseSize: 16
                            ),
                          ),
                        ),
                        if (isAdvanced) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Confidence
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getSeverityColor(severity).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$confidence%',
                        style: TextStyle(
                          color: _getSeverityColor(severity),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Diagnosis and severity
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        diagnosis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppMeasurements.getResponsiveFontSize(
                              context, baseSize: 14
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          color: _getSeverityColor(severity),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date and source
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),

                    Text(
                      isAdvanced
                          ? (scan['analysisSource']?.toString() ?? 'AI Scan')
                          : 'On-Device Scan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}