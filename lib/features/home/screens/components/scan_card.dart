import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_measurements.dart';
import '../../../ResultScreen/presentation/results_screen.dart';
import '../../../advance_result_screen/advanced_result_screen.dart';

class ScanCard extends StatefulWidget {
  final Map<String, dynamic> scan;
  final int index;
  final Animation<double> scaleAnimation;
  final void Function(Map<String, dynamic>) onShowOptions;
  final bool showFullPlantName;

  const ScanCard({
    super.key,
    required this.scan,
    required this.index,
    required this.scaleAnimation,
    required this.onShowOptions,
    this.showFullPlantName = true,
  });

  @override
  State<ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<ScanCard>
    with SingleTickerProviderStateMixin {
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
    _formattedDate = _formatTimestamp(
        widget.scan['timestamp'] ?? widget.scan['scanDate']);
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

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------
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

  Map<String, dynamic> _convertScanForNavigation(
      Map<String, dynamic> data) {
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
        converted[key] = _convertScanForNavigation(Map.from(value));
      } else if (value is List) {
        converted[key] = value.map((e) {
          if (e is Map) return _convertScanForNavigation(Map.from(e));
          return e;
        }).toList();
      } else {
        converted[key] = value;
      }
    });
    return converted;
  }

  // Check if scan is advanced
  bool _isAdvancedScan() {
    return widget.scan['isAdvanced'] as bool? ??
        widget.scan['scanType']?.toString() == 'advanced' ||
            widget.scan['analysisSource']?.toString() == 'gemini' ||
            widget.scan['analysisSource']?.toString() == 'plantid' ||
            widget.scan['analysisSource']?.toString() == 'plantId';
  }

  // Get plant name with disease for display
  String _getPlantName() {
    return widget.scan['plantName']?.toString() ?? 'Unknown Plant';
  }

  // Get disease name for display
  String _getDiseaseName() {
    final disease = widget.scan['diagnosis']?.toString() ??
        widget.scan['diseaseName']?.toString() ??
        'Healthy';
    return disease;
  }

  // Convert treatment to list
  List<String> _convertTreatmentToList(dynamic treatment) {
    if (treatment == null) return [];
    if (treatment is List) return List<String>.from(treatment);
    if (treatment is String) {
      return treatment.split('. ').where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  // Get raw data for advanced results
  Map<String, dynamic>? _getAdvancedData() {
    if (_isAdvancedScan()) {
      return widget.scan['advancedData'] is Map
          ? Map<String, dynamic>.from(widget.scan['advancedData'])
          : widget.scan['rawData'] is Map
          ? Map<String, dynamic>.from(widget.scan['rawData'])
          : null;
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Navigation Handlers - FIXED: Added ID and history flags
  // -----------------------------------------------------------------------
  void _navigateToRegularResults(BuildContext context) {
    // Create scan data WITH HISTORY FLAGS
    final scanData = {
      ...widget.scan, // Pass all original data
      'isFromHistory': true, // CRITICAL: Mark as from history
      'skipSave': true,
      'alreadySaved': true,
      'originalId': widget.scan['id'], // Pass original ID
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          scanData: scanData, // Pass with flags
        ),
      ),
    );
  }

  void _navigateToAdvancedResults(BuildContext context) {
    final advancedData = _getAdvancedData();

    // Build analysis result format WITH ID
    final analysisResult = {
      'source': widget.scan['analysisSource']?.toString() ?? 'Gemini',
      'data': {
        'plant': _getPlantName(),
        'disease': _getDiseaseName(),
        'confidence': widget.scan['confidence']?.toString() ?? '0',
        'severity': widget.scan['severity']?.toString() ?? 'Medium',
        'symptoms': widget.scan['symptoms'] is List ?
        List<String>.from(widget.scan['symptoms']) : [],
        'remediation': _convertTreatmentToList(widget.scan['treatment']),
        'precautions': widget.scan['precautions'] is List ?
        List<String>.from(widget.scan['precautions']) : [],
        'additionalInfo': widget.scan['description']?.toString() ?? '',
      },
      'success': true,
      'hasDiseaseInfo': true,
      'scanId': widget.scan['id'], // Pass original ID
    };

    // Safely merge only if both are Maps
    final data = analysisResult['data'];
    if (data is Map<String, dynamic> &&
        advancedData != null &&
        advancedData['data'] is Map<String, dynamic>) {
      data.addAll(advancedData['data'] as Map<String, dynamic>);
    }

    // Create original scan data WITH HISTORY FLAGS
    final originalScanData = {
      'imagePath': widget.scan['imagePath'],
      'imageUrl': widget.scan['imageUrl'],
      'imageBase64': widget.scan['imageBase64'],
      'isFromHistory': true, // CRITICAL: Mark as from history
      'skipSave': true,
      'alreadySaved': true,
      'id': widget.scan['id'], // Pass original ID
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedResultsScreen(
          analysisResult: analysisResult,
          originalScanData: originalScanData,
        ),
      ),
    );
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    if (_isAdvancedScan()) {
      _navigateToAdvancedResults(context);
    } else {
      _navigateToRegularResults(context);
    }
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    widget.onShowOptions(widget.scan);
  }

  // -----------------------------------------------------------------------
  // UI (unchanged)
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final plantName = _getPlantName();
    final diseaseName = _getDiseaseName();
    final isAdvanced = _isAdvancedScan();

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
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context) + 2,
            ),
            border: Border.all(
              color: _isPressed
                  ? (isAdvanced ? Colors.blue : Theme.of(context).colorScheme.primary).withOpacity(0.3)
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
              // Image with Confidence Badge
              Expanded(
                flex: 7,
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

                    // Confidence Badge
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

                    // Advanced Scan Badge
                    if (isAdvanced)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Plant Name
                      Text(
                        plantName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: isAdvanced ? Colors.blue : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),

                      // Disease Name
                      Text(
                        diseaseName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.2,
                          color: diseaseName.toLowerCase() == 'healthy'
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),

                      // Date
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                                fontSize: 10,
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

  // -----------------------------------------------------------------------
  // Image handling (unchanged)
  // -----------------------------------------------------------------------
  Widget _buildImage() {
    // Try base64 first
    final imageBase64 = widget.scan['imageBase64']?.toString();
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (e) {
        debugPrint('Error decoding base64: $e');
      }
    }

    // Try network URL
    final imageUrl = widget.scan['imageUrl']?.toString();
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

    // Try local file
    final imagePath = widget.scan['imagePath']?.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
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
}