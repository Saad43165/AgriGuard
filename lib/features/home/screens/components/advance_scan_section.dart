import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../advance_result_screen/advanced_result_screen.dart';
import '../../../../core/widgets/app_themes.dart';

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

  // Get color scheme based on analysis source AND theme mode
  Map<String, dynamic> _getSourceColorScheme(String source, bool isDark) {
    final lowerSource = source.toLowerCase();

    if (lowerSource.contains('groq')) {
      return {
        'primary': isDark ? const Color(0xFF5E97F6) : const Color(0xFF4285F4),
        'secondary': isDark ? const Color(0xFF5BB974) : const Color(0xFF34A853),
        'gradient': isDark
            ? [const Color(0xFF5E97F6), const Color(0xFF5BB974)]
            : [const Color(0xFF4285F4), const Color(0xFF34A853)],
        'light': isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE),
        'cardBg': isDark ? const Color(0xFF1A1A1A) : Colors.white,
        'borderColor': isDark ? const Color(0xFF5E97F6).withValues(alpha: 0.4) : const Color(0xFF4285F4).withValues(alpha: 0.25),
        'icon': Icons.stars_rounded,
        'name': 'Groq AI',
      };
    } else if (lowerSource.contains('hugging') || lowerSource.contains('hf')) {
      return {
        'primary': isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
        'secondary': isDark ? const Color(0xFF9333EA) : const Color(0xFF7C3AED),
        'gradient': isDark
            ? [const Color(0xFFA78BFA), const Color(0xFF9333EA)]
            : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        'light': isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF3E8FF),
        'cardBg': isDark ? const Color(0xFF1A1A1A) : Colors.white,
        'borderColor': isDark
            ? const Color(0xFFA78BFA).withValues(alpha: 0.4)
            : const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        'icon': Icons.psychology_rounded,
        'name': 'Hugging Face',
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
        'borderColor': isDark ? const Color(0xFF34D399).withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.25),
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
        'borderColor': isDark ? const Color(0xFFA78BFA).withValues(alpha: 0.4) : const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        'icon': Icons.auto_awesome,
        'name': source,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = (screenWidth * 0.025).clamp(8.0, 12.0);
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
                      color: (isDark ? const Color(0xFFA78BFA) : Colors.purple).withValues(alpha: 0.3),
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

        // Cards List — fixed height, no Expanded inside cards
        SizedBox(
          height: 170,
          child: advancedScans.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: advancedScans.length,
            itemBuilder: (context, index) {
              final scan = advancedScans[index];
              final cardWidth = (MediaQuery.of(context).size.width * 0.38).clamp(140.0, 160.0);
              return SizedBox(
                width: cardWidth,
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < advancedScans.length - 1 ? 10 : 0,
                    left: index == 0 ? 4 : 0,
                  ),
                  child: _buildAdvancedScanCard(context, scan, index, isDark),
                ),
              );
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
                const Color(0xFFA78BFA).withValues(alpha: 0.2),
                const Color(0xFF9333EA).withValues(alpha: 0.15),
              ]
                  : [
                Colors.purple.withValues(alpha: 0.12),
                Colors.purple.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFA78BFA).withValues(alpha: 0.4)
                  : Colors.purple.withValues(alpha: 0.25),
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
    final analysisSource = scan['analysisSource']?.toString() ?? 'Groq';

    final colorScheme = _getSourceColorScheme(analysisSource, isDark);
    final primaryColor = colorScheme['primary'] as Color;
    final gradientColors = colorScheme['gradient'] as List<Color>;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = colorScheme['borderColor'] as Color;
    final sourceIcon = colorScheme['icon'] as IconData;
    final sourceName = colorScheme['name'] as String;
    final isHealthy = diseaseName.toLowerCase() == 'healthy';
    final statusColor = isHealthy ? AppColors.success : AppColors.warning;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); _openAdvancedScan(context, scan); },
      onLongPress: () { HapticFeedback.mediumImpact(); onShowOptions(scan); },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image — fixed height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.5)),
              child: SizedBox(
                height: 85,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    scan['imageBase64'] != null && (scan['imageBase64'] as String).isNotEmpty
                        ? Image.memory(
                            base64Decode(scan['imageBase64'] as String),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
                          )
                        : _imagePlaceholder(isDark),
                    // Source badge
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
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
                              child: Icon(sourceIcon, size: 9, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(sourceName,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Confidence badge
                    if (confidence > 0)
                      Positioned(
                        top: 5, right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${confidence.toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info — intrinsic height, no Expanded
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plantName,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800,
                      color: primaryColor, height: 1.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                          size: 10, color: statusColor,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(diseaseName,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                              color: statusColor, height: 1.2),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) => Container(
    color: isDark ? const Color(0xFF1C2333) : const Color(0xFFE8F4FD),
    child: Center(child: Icon(Icons.local_florist_rounded, size: 28,
      color: AppColors.primary.withValues(alpha: 0.4))),
  );

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
                    const Color(0xFFA78BFA).withValues(alpha: 0.2),
                    const Color(0xFF9333EA).withValues(alpha: 0.1),
                  ]
                      : [
                    Colors.purple.withValues(alpha: 0.15),
                    Colors.purple.withValues(alpha: 0.05),
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
        'source': scan['analysisSource']?.toString() ?? 'Groq',
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