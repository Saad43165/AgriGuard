import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'delete_confirmation_dialoag_content.dart';

class AllScansDialogContent extends StatelessWidget {
  final List<Map<String, dynamic>> recentScans;
  final Function(String) onDeleteScan;
  final Function(Map<String, dynamic>) onShowOptions;

  const AllScansDialogContent({
    super.key,
    required this.recentScans,
    required this.onDeleteScan,
    required this.onShowOptions,
  });

  // Add timestamp formatting method
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

  // Safe method to handle any timestamp type
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
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'All Recent Scans',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 20),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: recentScans.length,
              itemBuilder: (context, index) {
                final scan = recentScans[index];
                return Dismissible(
                  key: Key(scan['id']?.toString() ?? index.toString()),
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    HapticFeedback.mediumImpact();
                    return await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: DeleteConfirmationDialogContent(
                          onConfirm: () => onDeleteScan(scan['id']?.toString() ?? ''),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
                        ],
                      ),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: _buildScanImage(scan, context),
                        ),
                      ),
                      title: Text(
                        scan['diagnosis']?.toString() ?? 'Unknown Disease',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTimestamp(scan['timestamp']), // FIXED: Use formatted timestamp
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                            ),
                          ),
                          if (scan['confidence'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${scan['confidence']}% confidence',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getConfidenceColor(scan['confidence']),
                                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () => onShowOptions(scan),
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/results', arguments: scan);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanImage(Map<String, dynamic> scan, BuildContext context) {
    final imageUrl = scan['imageUrl'];
    final localImagePath = scan['localImagePath'];
    final localImageExists = scan['localImageExists'] == true;

    // Try local image first, then fallback to imageUrl
    if (localImageExists && localImagePath != null) {
      return Image.file(
        File(localImagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(context),
      );
    } else if (imageUrl != null) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(context),
      );
    } else {
      return _buildFallbackIcon(context);
    }
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Icon(
      Icons.local_florist_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 24,
    );
  }

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
}