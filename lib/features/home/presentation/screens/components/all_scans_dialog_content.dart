// lib/features/scan_history/presentation/components/all_scans_dialog_content.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // -----------------------------------------------------------------------
  // Convert Firestore Timestamps to JSON-safe strings
  // -----------------------------------------------------------------------
  Map<String, dynamic> _convertForNavigation(Map<String, dynamic> data

      ) {
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
      if (timestamp is Timestamp) dt = timestamp.toDate();
      else if (timestamp is DateTime) dt = timestamp;
      else if (timestamp is String) dt = DateTime.tryParse(timestamp);
      return dt != null ? DateFormat('MMM dd, yyyy - HH:mm').format(dt) : 'Invalid Date';
    } catch (_) {
      return 'Error';
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double pad = AppMeasurements.getResponsivePadding(context);
    final double smallPad = AppMeasurements.getResponsiveSmallPadding(context);
    final double radius = AppMeasurements.getResponsiveBorderRadius(context);
    final double iconSize = AppMeasurements.getResponsiveIconSizeMedium(context);

    return GlassCard(
      borderRadius: radius * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(pad),
            child: Text(
              'All Recent Scans',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 22),
              ),
            ),
          ),

          // Empty state
          if (recentScans.isEmpty)
            _buildEmptyState(context, pad, radius, iconSize)
          else
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: smallPad),
                itemCount: recentScans.length,
                separatorBuilder: (_, __) => SizedBox(height: smallPad * 0.8),
                itemBuilder: (context, index) {
                  final scan = recentScans[index];
                  final String scanId = scan['id']?.toString() ?? 'scan_$index';
                  final navigableScan = _convertForNavigation(scan);

                  // DEBUG: See what image keys exist
                  debugPrint('SCAN $index → imageUrl: ${scan['imageUrl']}');
                  debugPrint('           localImagePath: ${scan['localImagePath']}');
                  debugPrint('           imagePath: ${scan['imagePath']}');

                  return Dismissible(
                    key: Key(scanId),
                    direction: DismissDirection.endToStart,
                    background: _buildDismissBackground(context, pad),
                    confirmDismiss: (_) => _showDeleteConfirmation(context),
                    onDismissed: (_) => onDeleteScan(scanId),
                    child: _buildScanTile(context, scan, navigableScan, radius, iconSize),
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
  Widget _buildDismissBackground(BuildContext context, double pad) {
    final cs = Theme.of(context).colorScheme;
    final r = AppMeasurements.getResponsiveBorderRadius(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.error.withOpacity(0.25),
        borderRadius: BorderRadius.circular(r * 1.5),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: pad),
      child: Icon(
        Icons.delete_rounded,
        color: cs.error,
        size: AppMeasurements.getResponsiveIconSizeLarge(context) * 0.6,
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
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: DeleteConfirmationDialogContent(
          onConfirm: () => Navigator.pop(dialogContext, true),
          onCancel: () => Navigator.pop(dialogContext, false),
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
      double radius,
      double iconSize,
      ) {
    final cs = Theme.of(context).colorScheme;
    final title = scan['diagnosis']?.toString() ?? 'Unknown Disease';
    final timestamp = _formatTimestamp(scan['timestamp']);
    final confidence = double.tryParse(scan['confidence']?.toString() ?? '');

    // SUPPORT MULTIPLE KEYS
    final imageUrl = scan['imageUrl'] as String?;
    final localPath = scan['localImagePath'] as String?;
    final imagePath = scan['imagePath'] as String?; // fallback

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius * 1.8),
        gradient: LinearGradient(
          colors: [cs.surface.withOpacity(0.4), cs.surface.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outline.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(color: cs.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(AppMeasurements.smallPadding),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary.withOpacity(0.3), cs.secondary.withOpacity(0.3)],
              ),
            ),
            child: _buildScanImage(imageUrl, localPath, imagePath, context), // PASS ALL
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 15),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timestamp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.65),
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 11.5),
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(height: 3),
              Text(
                '$confidence% confidence',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _getConfidenceColor(confidence),
                  fontWeight: FontWeight.w600,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 10.5),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert_rounded, size: iconSize * 0.9),
          color: cs.onSurface.withOpacity(0.6),
          onPressed: () => onShowOptions(scan),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, '/results', arguments: {'scanData': navigableScan});
        },
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Image loader – SUPPORTS imagePath, localImagePath, imageUrl
  // -----------------------------------------------------------------------
  Widget _buildScanImage(String? imageUrl, String? localPath, String? imagePath, BuildContext context) {
    // 1. Try localImagePath
    if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(context),
      );
    }

    // 2. Try imagePath (common in older data)
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackImage(context),
      );
    }

    // 3. Cloud URL
    if (imageUrl != null && imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.hasScheme == true) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, __, ___) => _fallbackImage(context),
      );
    }

    // 4. Fallback
    return _fallbackImage(context);
  }

  Widget _fallbackImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      child: Icon(
        Icons.local_florist_rounded,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        size: 28,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Confidence color
  // -----------------------------------------------------------------------
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green.shade600;
    if (confidence >= 60) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  // -----------------------------------------------------------------------
  // Empty state
  // -----------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, double pad, double radius, double iconSize) {
    return Container(
      padding: EdgeInsets.all(pad * 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.scanner_rounded, size: iconSize * 1.8, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
          SizedBox(height: pad),
          Text(
            'No scans yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 17),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: AppMeasurements.smallPadding * 0.5),
          Text(
            'Your scanned results will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 13),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}