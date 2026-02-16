import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../advance_result_screen/advanced_result_screen.dart';

class AdvanceScanSection extends StatelessWidget {
  final List<Map<String, dynamic>> advancedScans;
  final void Function(Map<String, dynamic> scan) onShowOptions;
  final VoidCallback onShowAllAdvancedScans;
  final Animation<double> scaleAnimation;

  const AdvanceScanSection({
    super.key,
    required this.advancedScans,
    required this.onShowOptions,
    required this.onShowAllAdvancedScans,
    required this.scaleAnimation,
  });

  bool _isAdvancedScan(Map<String, dynamic> scan) {
    return scan['isAdvanced'] as bool? ??
        scan['scanType']?.toString() == 'advanced' ||
            scan['analysisSource']?.toString() == 'gemini' ||
            scan['analysisSource']?.toString() == 'plantid' ||
            scan['analysisSource']?.toString() == 'plantId' ||
            scan['advancedData'] != null;
  }

  // Get color scheme based on analysis source AND theme mode
  Map<String, dynamic> _getSourceColorScheme(String source, bool isDark) {
    final lowerSource = source.toLowerCase();

    if (lowerSource.contains('gemini')) {
      return {
        'primary': isDark ? const Color(0xFF5E97F6) : const Color(0xFF4285F4),
        'secondary': isDark ? const Color(0xFF5BB974) : const Color(0xFF34A853),
        'gradient': isDark
            ? [const Color(0xFF5E97F6), const Color(0xFF5BB974)]
            : [const Color(0xFF4285F4), const Color(0xFF34A853)],
        'light': isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE),
        'cardBg': isDark ? const Color(0xFF1A1A1A) : Colors.white,
        'borderColor': isDark ? const Color(0xFF5E97F6).withOpacity(0.4) : const Color(0xFF4285F4).withOpacity(0.25),
        'icon': Icons.stars_rounded,
        'name': 'Gemini AI',
      };
    } else if (lowerSource.contains('plantid') || lowerSource.contains('plant.id')) {
      return {
        'primary': isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
        'secondary': isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
        'gradient': isDark
            ? [const Color(0xFF34D399), const Color(0xFF10B981)]
            : [const Color(0xFF10B981), const Color(0xFF059669)],
        'light': isDark ? const Color(0xFF1A3D2F) : const Color(0xFFD1FAE5),
        'cardBg': isDark ? const Color(0xFF1A1A1A) : Colors.white,
        'borderColor': isDark ? const Color(0xFF34D399).withOpacity(0.4) : const Color(0xFF10B981).withOpacity(0.25),
        'icon': Icons.eco_rounded,
        'name': 'Plant.id',
      };
    } else {
      return {
        'primary': isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
        'secondary': isDark ? const Color(0xFF9333EA) : const Color(0xFF7C3AED),
        'gradient': isDark
            ? [const Color(0xFFA78BFA), const Color(0xFF9333EA)]
            : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        'light': isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF3E8FF),
        'cardBg': isDark ? const Color(0xFF1A1A1A) : Colors.white,
        'borderColor': isDark ? const Color(0xFFA78BFA).withOpacity(0.4) : const Color(0xFF8B5CF6).withOpacity(0.25),
        'icon': Icons.auto_awesome,
        'name': source,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.05;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFFA78BFA), const Color(0xFF9333EA)]
                        : [Colors.deepPurple.shade600, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFFA78BFA) : Colors.purple).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),

              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  'Advanced AI Scans',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              // View All Button
              _buildViewAllButton(context, isDark),
            ],
          ),
        ),

        SizedBox(height: screenHeight * 0.012),

        // Cards List
        SizedBox(
          height: 165,
          child: advancedScans.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: advancedScans.length,
            itemBuilder: (context, index) {
              final scan = advancedScans[index];
              return _buildAdvancedScanCard(context, scan, index, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context, bool isDark) {
    final buttonColor = isDark ? const Color(0xFFA78BFA) : Colors.purple.shade700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onShowAllAdvancedScans();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                const Color(0xFFA78BFA).withOpacity(0.2),
                const Color(0xFF9333EA).withOpacity(0.15),
              ]
                  : [
                Colors.purple.withOpacity(0.12),
                Colors.purple.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFA78BFA).withOpacity(0.4)
                  : Colors.purple.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: buttonColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, size: 13, color: buttonColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedScanCard(BuildContext context, Map<String, dynamic> scan, int index, bool isDark) {
    final plantName = scan['plantName']?.toString() ?? 'Unknown Plant';
    final diseaseName = scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? 'Healthy';
    final confidence = double.tryParse(scan['confidence']?.toString() ?? '0') ?? 0;
    final analysisSource = scan['analysisSource']?.toString() ?? 'Gemini';
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.37).clamp(130.0, 155.0);

    // Get dynamic color scheme with dark mode support
    final colorScheme = _getSourceColorScheme(analysisSource, isDark);
    final primaryColor = colorScheme['primary'] as Color;
    final gradientColors = colorScheme['gradient'] as List<Color>;
    final lightColor = colorScheme['light'] as Color;
    final cardBg = colorScheme['cardBg'] as Color;
    final borderColor = colorScheme['borderColor'] as Color;
    final sourceIcon = colorScheme['icon'] as IconData;
    final sourceName = colorScheme['name'] as String;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(
        right: index < advancedScans.length - 1 ? 10 : 0,
        left: index == 0 ? 4 : 0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            cardBg,
            lightColor.withOpacity(0.15),
          ]
              : [
            cardBg,
            lightColor.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : primaryColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _openAdvancedScan(context, scan);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onShowOptions(scan);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section with Source Badge Overlay
              SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    // Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14.5),
                          topRight: Radius.circular(14.5),
                        ),
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      ),
                      child: scan['imageBase64'] != null && scan['imageBase64'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14.5),
                          topRight: Radius.circular(14.5),
                        ),
                        child: Image.memory(
                          base64Decode(scan['imageBase64']),
                          fit: BoxFit.cover,
                          height: 80,
                          width: double.infinity,
                        ),
                      )
                          : Center(
                        child: Icon(
                          Icons.local_florist_rounded,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          size: 30,
                        ),
                      ),
                    ),

                    // Source Badge at Bottom (overlaying image)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: gradientColors),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(sourceIcon, size: 10, color: Colors.white),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                sourceName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Confidence Badge (top right)
                    if (confidence > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${confidence.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Section - THEME ADAPTIVE
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Plant Name
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            child: Text(
                              plantName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                height: 1.2,
                                color: isDark
                                    ? primaryColor.withOpacity(0.95)
                                    : primaryColor.withOpacity(0.9),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Disease Status Box - DARK MODE ADAPTIVE
                          Flexible(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getDiseaseBoxColor(diseaseName, isDark, isBackground: true),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: _getDiseaseBoxColor(diseaseName, isDark, isBackground: false),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Health Status',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: Text(
                                      diseaseName,
                                      style: TextStyle(
                                        fontSize: 10.5,
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
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Get disease box colors based on theme
  Color _getDiseaseBoxColor(String diseaseName, bool isDark, {required bool isBackground}) {
    final isHealthy = diseaseName.toLowerCase() == 'healthy';

    if (isBackground) {
      if (isHealthy) {
        return isDark ? const Color(0xFF1A3D2F) : Colors.green.shade50;
      } else {
        return isDark ? const Color(0xFF3D2A1A) : Colors.orange.shade50;
      }
    } else {
      // Border color
      if (isHealthy) {
        return isDark ? const Color(0xFF34D399) : Colors.green.shade300;
      } else {
        return isDark ? const Color(0xFFFB923C) : Colors.orange.shade300;
      }
    }
  }

  // Helper: Get disease text color based on theme
  Color _getDiseaseTextColor(String diseaseName, bool isDark) {
    final isHealthy = diseaseName.toLowerCase() == 'healthy';

    if (isHealthy) {
      return isDark ? const Color(0xFF34D399) : Colors.green.shade700;
    } else {
      return isDark ? const Color(0xFFFB923C) : Colors.orange.shade800;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return const Color(0xFF10B981);
    if (confidence >= 60) return const Color(0xFFFB923C);
    return const Color(0xFFEF4444);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                    const Color(0xFFA78BFA).withOpacity(0.2),
                    const Color(0xFF9333EA).withOpacity(0.1),
                  ]
                      : [
                    Colors.purple.withOpacity(0.15),
                    Colors.purple.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 32,
                color: isDark ? const Color(0xFFA78BFA) : Colors.purple.shade400,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No Advanced Scans',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Try advanced scanning',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAdvancedScan(BuildContext context, Map<String, dynamic> scan) {
    try {
      final plantName = scan['plantName']?.toString() ?? scan['plant_name']?.toString() ?? 'Unknown Plant';
      final diseaseName = scan['diagnosis']?.toString() ?? scan['diseaseName']?.toString() ?? scan['disease_name']?.toString() ?? 'Healthy';
      final confidence = scan['confidence']?.toString() ?? scan['accuracy']?.toString() ?? '0';
      final severity = scan['severity']?.toString() ?? scan['disease_severity']?.toString() ?? 'Medium';

      List<String> symptoms = [];
      if (scan['symptoms'] is List) {
        symptoms = List<String>.from(scan['symptoms']);
      } else if (scan['symptoms'] is String && (scan['symptoms'] as String).isNotEmpty) {
        symptoms = (scan['symptoms'] as String).split(', ').where((s) => s.isNotEmpty).toList();
      }

      List<String> remediation = _convertTreatmentToList(scan['treatment']);
      if (remediation.isEmpty) remediation = _convertTreatmentToList(scan['remediation']);

      List<String> precautions = [];
      if (scan['precautions'] is List) {
        precautions = List<String>.from(scan['precautions']);
      } else if (scan['precautions'] is String && (scan['precautions'] as String).isNotEmpty) {
        precautions = (scan['precautions'] as String).split(', ').where((s) => s.isNotEmpty).toList();
      }

      Map<String, dynamic>? advancedInnerData;
      if (scan['advancedData'] != null) {
        try {
          if (scan['advancedData'] is String) {
            final decoded = jsonDecode(scan['advancedData'] as String);
            if (decoded is Map<String, dynamic>) advancedInnerData = decoded;
          } else if (scan['advancedData'] is Map<String, dynamic>) {
            advancedInnerData = scan['advancedData'] as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('❌ Error parsing advancedData: $e');
        }
      }

      final analysisResult = {
        'source': scan['analysisSource']?.toString() ?? 'Gemini',
        'data': {
          'plant': plantName,
          'disease': diseaseName,
          'confidence': confidence,
          'severity': severity,
          'symptoms': symptoms,
          'remediation': remediation,
          'precautions': precautions,
          'additionalInfo': scan['description']?.toString() ?? scan['additional_info']?.toString() ?? '',
          'scientificName': scan['scientificName']?.toString() ?? scan['scientific_name']?.toString() ?? '',
          'cause': scan['cause']?.toString() ?? '',
          'prevention': scan['prevention']?.toString() ?? '',
          if (advancedInnerData != null) ...advancedInnerData,
        },
        'success': true,
        'hasDiseaseInfo': diseaseName.toLowerCase() != 'healthy',
        'scanId': scan['id'],
      };

      final originalScanData = {
        'imagePath': scan['imagePath'],
        'imageUrl': scan['imageUrl'],
        'imageBase64': scan['imageBase64'],
        'isFromHistory': true,
        'skipSave': true,
        'alreadySaved': true,
        'id': scan['id'],
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
    } catch (e, stackTrace) {
      debugPrint('❌ Error opening advanced scan: $e');
      debugPrint('Stack trace: $stackTrace');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Could not load scan details. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  List<String> _convertTreatmentToList(dynamic treatment) {
    if (treatment == null) return [];
    if (treatment is List) {
      return treatment.map((item) => item.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (treatment is String) {
      return treatment
          .replaceAll(RegExp(r'\s*[•\-]\s*'), '. ')
          .split(RegExp(r'[.;]\s+'))
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.trim() + (s.trim().endsWith('.') ? '' : '.'))
          .toList();
    }
    return [treatment.toString()];
  }
}