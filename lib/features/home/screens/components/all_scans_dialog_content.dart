// lib/features/scan_history/presentation/components/all_scans_dialog_content.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // -----------------------------------------------------------------------
  // Convert Firestore Timestamps to JSON-safe strings
  // -----------------------------------------------------------------------
  Map<String, dynamic> _convertForNavigation(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        final date = value.toDate();
        converted[key] = date.toIso8601String();
        converted['${key}Millis'] = value.millisecondsSinceEpoch;
      } else if (value is DateTime) {
        converted[key] = value.toIso8601String();
        converted['${key}Millis'] = value.millisecondsSinceEpoch;
      } else if (value is Map) {
        converted[key] = _convertForNavigation(Map<String, dynamic>.from(value));
      } else if (value is List) {
        converted[key] = value.map((e) {
          if (e is Map) return _convertForNavigation(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else {
        converted[key] = value;
      }
    });
    return converted;
  }

  // -----------------------------------------------------------------------
  // Timestamp → human readable
  // -----------------------------------------------------------------------
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    try {
      DateTime? dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dt = timestamp;
      } else if (timestamp is String) {
        dt = DateTime.tryParse(timestamp);
      } else if (timestamp is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return dt != null ? DateFormat('MMM dd, yyyy • HH:mm').format(dt) : 'Invalid Date';
    } catch (e) {
      debugPrint('Error formatting timestamp: $e');
      return 'Invalid Date';
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: MediaQuery.of(context).size.width * 0.95,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '${recentScans.length} ${recentScans.length == 1 ? 'scan' : 'scans'} total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  iconSize: 24,
                ),
              ],
            ),
          ),

          // Content
          if (recentScans.isEmpty)
            _buildEmptyState(context)
          else
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: recentScans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final scan = recentScans[index];
                  final String scanId = scan['id']?.toString() ?? 'scan_${DateTime.now().millisecondsSinceEpoch}_$index';
                  final navigableScan = _convertForNavigation(scan);

                  return Dismissible(
                    key: Key(scanId),
                    direction: DismissDirection.endToStart,
                    background: _buildDismissBackground(context),
                    confirmDismiss: (_) => _showDeleteConfirmation(context),
                    onDismissed: (_) {
                      HapticFeedback.mediumImpact();
                      onDeleteScan(scanId);
                    },
                    child: _buildScanTile(context, scan, navigableScan),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Dismiss background
  // -----------------------------------------------------------------------
  Widget _buildDismissBackground(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error.withOpacity(0.1),
            theme.colorScheme.error.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_rounded,
            color: theme.colorScheme.error,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Delete confirmation
  // -----------------------------------------------------------------------
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: DeleteConfirmationDialogContent(
          onConfirm: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(dialogContext, true);
          },
          onCancel: () {
            HapticFeedback.lightImpact();
            Navigator.pop(dialogContext, false);
          },
        ),
      ),
    );
    return confirmed == true;
  }

  // -----------------------------------------------------------------------
  // Scan tile
  // -----------------------------------------------------------------------
  Widget _buildScanTile(
      BuildContext context,
      Map<String, dynamic> scan,
      Map<String, dynamic> navigableScan,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = scan['diagnosis']?.toString() ?? 'Unknown Disease';
    final timestamp = _formatTimestamp(scan['timestamp']);
    final confidence = double.tryParse(scan['confidence']?.toString() ?? '0') ?? 0;

    final imageUrl = scan['imageUrl'] as String?;
    final localPath = scan['localImagePath'] as String?;
    final imagePath = scan['imagePath'] as String?;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(
          context,
          '/results',
          arguments: {'scanData': navigableScan},
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface.withOpacity(0.5)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _buildScanImage(imageUrl, localPath, imagePath, context),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 10,
                            color: _getConfidenceColor(confidence),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${confidence.toInt()}% confident',
                            style: TextStyle(
                              color: _getConfidenceColor(confidence),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Options button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onShowOptions(scan);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Image loader
  // -----------------------------------------------------------------------
  Widget _buildScanImage(
      String? imageUrl,
      String? localPath,
      String? imagePath,
      BuildContext context,
      ) {
    // 1. Try localImagePath
    if (localPath != null && localPath.isNotEmpty) {
      try {
        final file = File(localPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackImage(context),
          );
        }
      } catch (e) {
        debugPrint('Error loading local image: $e');
      }
    }

    // 2. Try imagePath
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackImage(context),
          );
        }
      } catch (e) {
        debugPrint('Error loading image path: $e');
      }
    }

    // 3. Cloud URL
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final uri = Uri.tryParse(imageUrl);
      if (uri != null && uri.hasScheme) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _fallbackImage(context),
        );
      }
    }

    // 4. Fallback
    return _fallbackImage(context);
  }

  Widget _fallbackImage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          color: theme.colorScheme.primary.withOpacity(0.4),
          size: 32,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Confidence color
  // -----------------------------------------------------------------------
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return const Color(0xFF10B981);
    if (confidence >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // -----------------------------------------------------------------------
  // Empty state
  // -----------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.scanner_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Scans Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plant scan history will appear here.\nStart by capturing your first plant!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}