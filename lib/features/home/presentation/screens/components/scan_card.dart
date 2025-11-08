// lib/features/scan_history/presentation/components/scan_card.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';

class ScanCard extends StatefulWidget {
  final Map<String, dynamic> scan;
  final int index;
  final Animation<double> scaleAnimation;
  final void Function(Map<String, dynamic>) onShowOptions;

  const ScanCard({
    super.key,
    required this.scan,
    required this.index,
    required this.scaleAnimation,
    required this.onShowOptions,
  });

  @override
  State<ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<ScanCard> {
  late final Map<String, dynamic> _navigableScan;
  late final String _formattedDate;
  late final Color _confidenceColor;
  late final String _confidenceText;

  @override
  void initState() {
    super.initState();
    _navigableScan = _convertScanForNavigation(widget.scan);
    _formattedDate = _formatTimestamp(widget.scan['timestamp']);
    final conf = double.tryParse(widget.scan['confidence'].toString()) ?? 0;
    _confidenceColor = _getConfidenceColor(conf);
    _confidenceText = '${conf.toInt()}%';
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime? dt;
      if (timestamp is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dt = timestamp;
      } else if (timestamp is String) {
        dt = DateTime.tryParse(timestamp);
      }
      return dt != null ? DateFormat('MMM dd').format(dt) : 'Invalid';
    } catch (_) {
      return 'Error';
    }
  }

  Map<String, dynamic> _convertScanForNavigation(Map<String, dynamic> data) {
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
        converted[key] = _convertScanForNavigation(Map<String, dynamic>.from(value));
      } else if (value is List) {
        converted[key] = value.map((e) {
          if (e is Map) return _convertScanForNavigation(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else {
        converted[key] = value;
      }
    });
    return converted;
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.scaleAnimation.value,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        child: GlassCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
            onTap: _onTap,
            onLongPress: _onLongPress,
            child: IntrinsicHeight(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200), // matches parent
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Image ─────────────────────────────────────
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImage(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Diagnosis ─────────────────────────────────
                      Flexible(
                        child: Text(
                          widget.scan['diagnosis']?.toString() ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 13,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ── Date + Confidence ────────────────────────
                      Row(
                        children: [
                          // Date
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _formattedDate,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                      fontSize: AppMeasurements.getResponsiveFontSize(
                                        context,
                                        baseSize: 11,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Confidence badge (optional)
                          if (widget.scan['confidence'] != null) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: _confidenceColor.withOpacity(0.15),
                                ),
                                child: Text(
                                  _confidenceText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: _confidenceColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppMeasurements.getResponsiveFontSize(
                                      context,
                                      baseSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Image handling
  // -------------------------------------------------------------------------
  Widget _buildImage() {
    final imageUrl = widget.scan['imageUrl']?.toString();
    final imagePath = widget.scan['imagePath']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, progress) =>
        progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (imagePath != null &&
        imagePath.isNotEmpty &&
        (Platform.isAndroid || Platform.isIOS)) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.local_florist_rounded,
        size: 32,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Interactions
  // -------------------------------------------------------------------------
  void _onTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/results',
      arguments: {'scanData': _navigableScan},
    );
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onShowOptions(widget.scan);
  }
}