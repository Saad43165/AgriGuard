// lib/features/scan_history/presentation/components/scan_card.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_measurements.dart';

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

class _ScanCardState extends State<ScanCard> with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> _navigableScan;
  late final String _formattedDate;
  late final Color _confidenceColor;
  late final String _confidenceText;
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _navigableScan = _convertScanForNavigation(widget.scan);
    _formattedDate = _formatTimestamp(widget.scan['timestamp']);
    final conf = double.tryParse(widget.scan['confidence'].toString()) ?? 0;
    _confidenceColor = _getConfidenceColor(conf);
    _confidenceText = '${conf.toInt()}%';

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return const Color(0xFF10B981);
    if (confidence >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        _onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      onLongPress: _onLongPress,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 140, // Fixed height to match parent
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context) + 2,
            ),
            border: Border.all(
              color: _isPressed
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.08),
                blurRadius: _isPressed ? 12 : 8,
                offset: Offset(0, _isPressed ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image with Confidence Badge ───────────────
              Expanded(
                flex: 7, // 70% of the card
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          AppMeasurements.getResponsiveBorderRadius(context) + 1,
                        ),
                        topRight: Radius.circular(
                          AppMeasurements.getResponsiveBorderRadius(context) + 1,
                        ),
                      ),
                      child: SizedBox.expand(
                        child: _buildImage(),
                      ),
                    ),
                    // Confidence Badge (top-right)
                    if (widget.scan['confidence'] != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _confidenceColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _confidenceText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Content Section ───────────────────────────
              Expanded(
                flex: 5, // 50% of the card
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Diagnosis (with flexible space)
                      Flexible(
                        child: Text(
                          widget.scan['diagnosis']?.toString() ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
SizedBox(height: 4),
                      // Date (always at bottom)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formattedDate,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                                fontSize: 12,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        loadingBuilder: (c, child, progress) => progress == null
            ? child
            : Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
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
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: 28,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
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