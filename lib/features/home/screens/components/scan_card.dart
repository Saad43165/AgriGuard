import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

class _ScanCardState extends State<ScanCard> with SingleTickerProviderStateMixin {
  late final String _formattedDate;
  late final Color _confidenceColor;
  late final String _confidenceText;
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _formattedDate = _formatTimestamp(widget.scan['timestamp'] ?? widget.scan['scanDate']);
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
    if (confidence >= 60) return const Color(0xFFFB923C);
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

  bool _isAdvancedScan() {
    return widget.scan['isAdvanced'] as bool? ??
        widget.scan['scanType']?.toString() == 'advanced' ||
            widget.scan['analysisSource']?.toString() == 'gemini' ||
            widget.scan['analysisSource']?.toString() == 'plantid' ||
            widget.scan['analysisSource']?.toString() == 'plantId';
  }

  String _getPlantName() {
    return widget.scan['plantName']?.toString() ?? 'Unknown Plant';
  }

  String _getDiseaseName() {
    return widget.scan['diagnosis']?.toString() ??
        widget.scan['diseaseName']?.toString() ??
        'Healthy';
  }

  // Get color scheme based on analysis source
  Map<String, dynamic> _getSourceColorScheme(String? source, bool isDark) {
    final lowerSource = (source ?? '').toLowerCase();

    if (lowerSource.contains('gemini')) {
      return {
        'primary': isDark ? const Color(0xFF5E97F6) : const Color(0xFF4285F4),
        'gradient': isDark
            ? [const Color(0xFF5E97F6), const Color(0xFF5BB974)]
            : [const Color(0xFF4285F4), const Color(0xFF34A853)],
        'light': isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE),
        'cardBg': isDark ? const Color(0xFF1F1F1F) : Colors.white,
        'borderColor': isDark
            ? const Color(0xFF5E97F6).withOpacity(0.4)
            : const Color(0xFF4285F4).withOpacity(0.25),
        'icon': Icons.stars_rounded,
        'name': 'Gemini AI',
      };
    } else if (lowerSource.contains('plantid') || lowerSource.contains('plant.id')) {
      return {
        'primary': isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
        'gradient': isDark
            ? [const Color(0xFF34D399), const Color(0xFF10B981)]
            : [const Color(0xFF10B981), const Color(0xFF059669)],
        'light': isDark ? const Color(0xFF1A3D2F) : const Color(0xFFD1FAE5),
        'cardBg': isDark ? const Color(0xFF1F1F1F) : Colors.white,
        'borderColor': isDark
            ? const Color(0xFF34D399).withOpacity(0.4)
            : const Color(0xFF10B981).withOpacity(0.25),
        'icon': Icons.eco_rounded,
        'name': 'Plant.id',
      };
    } else {
      return {
        'primary': Theme.of(context).colorScheme.primary,
        'gradient': [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ],
        'light': Theme.of(context).colorScheme.primaryContainer,
        'cardBg': Theme.of(context).colorScheme.surface,
        'borderColor': Theme.of(context).colorScheme.outline.withOpacity(isDark ? 0.3 : 0.15),
        'icon': Icons.local_florist_rounded,
        'name': 'Standard',
      };
    }
  }

  Color _getDiseaseBoxColor(String diseaseName, bool isDark, {required bool isBackground}) {
    final isHealthy = diseaseName.toLowerCase() == 'healthy';
    if (isBackground) {
      return isHealthy
          ? (isDark ? const Color(0xFF1A3D2F) : Colors.green.shade50)
          : (isDark ? const Color(0xFF3D2A1A) : Colors.orange.shade50);
    } else {
      return isHealthy
          ? (isDark ? const Color(0xFF34D399) : Colors.green.shade300)
          : (isDark ? const Color(0xFFFB923C) : Colors.orange.shade300);
    }
  }

  Color _getDiseaseTextColor(String diseaseName, bool isDark) {
    final isHealthy = diseaseName.toLowerCase() == 'healthy';
    return isHealthy
        ? (isDark ? const Color(0xFF34D399) : Colors.green.shade700)
        : (isDark ? const Color(0xFFFB923C) : Colors.orange.shade800);
  }

  // -----------------------------------------------------------------------
  // Navigation
  // -----------------------------------------------------------------------
  void _navigateToResults(BuildContext context) {
    HapticFeedback.lightImpact();

    if (_isAdvancedScan()) {
      final analysisResult = {
        'source': widget.scan['analysisSource']?.toString() ?? 'Gemini',
        'data': {
          'plant': _getPlantName(),
          'disease': _getDiseaseName(),
          'confidence': widget.scan['confidence']?.toString() ?? '0',
          'severity': widget.scan['severity']?.toString() ?? 'Medium',
          'symptoms': widget.scan['symptoms'] is List
              ? List<String>.from(widget.scan['symptoms'])
              : [],
          'remediation': widget.scan['treatment'] is List
              ? List<String>.from(widget.scan['treatment'])
              : [],
          'precautions': widget.scan['precautions'] is List
              ? List<String>.from(widget.scan['precautions'])
              : [],
          'additionalInfo': widget.scan['description']?.toString() ?? '',
        },
        'success': true,
        'hasDiseaseInfo': true,
        'scanId': widget.scan['id'],
      };

      final originalScanData = {
        'imagePath': widget.scan['imagePath'],
        'imageUrl': widget.scan['imageUrl'],
        'imageBase64': widget.scan['imageBase64'],
        'isFromHistory': true,
        'skipSave': true,
        'alreadySaved': true,
        'id': widget.scan['id'],
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
    } else {
      final scanData = {
        ...widget.scan,
        'isFromHistory': true,
        'skipSave': true,
        'alreadySaved': true,
        'originalId': widget.scan['id'],
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(scanData: scanData),
        ),
      );
    }
  }

  // -----------------------------------------------------------------------
  // UI - REDUCED SIZE
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final plantName = _getPlantName();
    final diseaseName = _getDiseaseName();
    final isAdvanced = _isAdvancedScan();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analysisSource = widget.scan['analysisSource']?.toString();

    final colorScheme = _getSourceColorScheme(analysisSource, isDark);
    final primaryColor = colorScheme['primary'] as Color;
    final gradientColors = colorScheme['gradient'] as List<Color>;
    final lightColor = colorScheme['light'] as Color;
    final cardBg = colorScheme['cardBg'] as Color;
    final borderColor = colorScheme['borderColor'] as Color;
    final sourceIcon = colorScheme['icon'] as IconData;
    final sourceName = colorScheme['name'] as String;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        _navigateToResults(context);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onShowOptions(widget.scan);
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [cardBg, lightColor.withOpacity(0.12)]
                  : [cardBg, lightColor.withOpacity(0.25)],
            ),
            borderRadius: BorderRadius.circular(14), // Slightly reduced
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : primaryColor.withOpacity(0.15),
                blurRadius: _isPressed ? 10 : 8,
                offset: Offset(0, _isPressed ? 3 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section - REDUCED
              SizedBox(
                height: 70, // Reduced from 80
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.5),
                        topRight: Radius.circular(12.5),
                      ),
                      child: SizedBox.expand(
                        child: _buildImage(isDark),
                      ),
                    ),

                    // Source Badge (for advanced scans) - SMALLER
                    if (isAdvanced)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.85),
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: gradientColors),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(sourceIcon, size: 8, color: Colors.white),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  sourceName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8.5,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Confidence Badge - SMALLER
                    if (widget.scan['confidence'] != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _confidenceColor,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            _confidenceText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Section - SMALLER
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(7), // Reduced from 8
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Plant Name - SMALLER
                      Text(
                        plantName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11, // Reduced from 11.5
                          height: 1.2,
                          color: isDark
                              ? primaryColor.withOpacity(0.95)
                              : primaryColor.withOpacity(0.9),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Disease Status Box - SMALLER
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3), // Reduced
                          decoration: BoxDecoration(
                            color: _getDiseaseBoxColor(diseaseName, isDark, isBackground: true),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _getDiseaseBoxColor(diseaseName, isDark, isBackground: false),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 6.5, // Reduced from 7
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 6.5, // Reduced from 7
                                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formattedDate,
                                        style: TextStyle(
                                          fontSize: 6.5, // Reduced from 7
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  diseaseName,
                                  style: TextStyle(
                                    fontSize: 9.5, // Reduced from 10
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: _getDiseaseTextColor(diseaseName, isDark),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  // Image handling
  // -----------------------------------------------------------------------
  Widget _buildImage(bool isDark) {
    final imageBase64 = widget.scan['imageBase64']?.toString();
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageBase64),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(isDark),
        );
      } catch (e) {
        debugPrint('Error decoding base64: $e');
      }
    }

    final imageUrl = widget.scan['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, progress) => progress == null
            ? child
            : Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        errorBuilder: (_, __, ___) => _placeholder(isDark),
      );
    }

    final imagePath = widget.scan['imagePath']?.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(isDark),
        );
      }
    }

    return _placeholder(isDark);
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: 22, // Reduced from 24
          color: isDark
              ? Colors.grey.shade600
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}