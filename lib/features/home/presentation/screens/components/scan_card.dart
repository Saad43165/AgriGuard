import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Add this import
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';

class ScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final int index;
  final Animation<double> scaleAnimation;
  final Function(Map<String, dynamic>) onShowOptions;

  const ScanCard({
    super.key,
    required this.scan,
    required this.index,
    required this.scaleAnimation,
    required this.onShowOptions,
  });

  Color _getConfidenceColor(dynamic confidence) {
    final double conf = double.tryParse(confidence.toString()) ?? 0;
    if (conf >= 80) {
      return Colors.green;
    } else if (conf >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Add this method to format timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      // If it's already a string, return it
      if (timestamp is String) return timestamp;

      // If it's a Timestamp object, convert to DateTime and format
      if (timestamp is Timestamp) {
        return DateFormat('MMM dd, yyyy - HH:mm').format(timestamp.toDate());
      }

      // If it's a DateTime object, format it directly
      if (timestamp is DateTime) {
        return DateFormat('MMM dd, yyyy - HH:mm').format(timestamp);
      }

      // For any other type, try to convert to string
      return timestamp.toString();
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Alternative safe method if you're not sure about the timestamp type
  String _safeTimestampToString(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    // Try to detect and handle Timestamp type dynamically
    if (timestamp.runtimeType.toString().contains('Timestamp')) {
      try {
        // Use reflection-like approach to call toDate() if it exists
        final dynamic date = timestamp.toDate();
        if (date is DateTime) {
          return DateFormat('MMM dd, yyyy').format(date);
        }
      } catch (e) {
        // Fall through to string conversion
      }
    }

    // Final fallback
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: GlassCard(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/results', arguments: scan);
                },
                onLongPress: () => onShowOptions(scan),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: scan['imageUrl'] != null
                                ? Image.file(
                              File(scan['imageUrl']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.local_florist_rounded,
                                  size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                                : Center(
                              child: Icon(
                                Icons.local_florist_rounded,
                                size: AppMeasurements.getResponsiveIconSizeMedium(context),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              scan['diagnosis'] ?? 'Unknown Disease',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // FIXED: Use the timestamp formatting method
                            Text(
                              _formatTimestamp(scan['timestamp']),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            if (scan['confidence'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: _getConfidenceColor(scan['confidence']).withOpacity(0.2),
                                  ),
                                  child: Text(
                                    '${scan['confidence']}% confidence',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getConfidenceColor(scan['confidence']),
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}