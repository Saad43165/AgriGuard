import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import 'section_header.dart';
import 'detail_row.dart';

class AnalysisDetailsCard extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const AnalysisDetailsCard({super.key, required this.scanData});

  @override
  State<AnalysisDetailsCard> createState() => _AnalysisDetailsCardState();
}

class _AnalysisDetailsCardState extends State<AnalysisDetailsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyAllDetails() {
    final translation = Provider.of<TranslationService>(context, listen: false);
    final displayInfo = _getDiseaseDisplayInfo();
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('=== ${translation.get('plant_analysis_details')} ===\n');
    buffer.writeln('${displayInfo['label']}: ${displayInfo['value']}');

    if (widget.scanData['plantName'] != null) {
      buffer.writeln('${translation.get('plant_species')}: ${widget.scanData['plantName']}');
    }
    if (widget.scanData['severity'] != null) {
      buffer.writeln('${translation.get('severity')}: ${widget.scanData['severity']}');
    }
    if (widget.scanData['confidence'] != null) {
      buffer.writeln('${translation.get('confidence_level')}: ${widget.scanData['confidence']}%');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(translation.get('details_copied')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Map<String, dynamic> _getDiseaseDisplayInfo() {
    final translation = Provider.of<TranslationService>(context, listen: false);

    String label = translation.get('health_status');
    String value = translation.get('healthy');
    IconData icon = Icons.verified_rounded;
    Color color = const Color(0xFF10B981);

    String? processedDisease = widget.scanData['diseaseName']?.toString() ??
        widget.scanData['diagnosis']?.toString() ??
        widget.scanData['disease']?.toString();

    String? rawLabel = widget.scanData['rawLabel']?.toString();

    if (rawLabel != null && rawLabel.contains('___')) {
      final parts = rawLabel.split('___');
      if (parts.length >= 2) {
        final diseasePart = parts[1].replaceAll('_', ' ').trim();
        if (diseasePart.toLowerCase() != 'healthy') {
          label = translation.get('detected_disease');
          value = translation.translateDisease(
              diseasePart
                  .split(' ')
                  .map((word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word)
                  .join(' ')
          );
          icon = Icons.medical_services_rounded;

          final severity = widget.scanData['severity']?.toString() ?? 'Medium';
          color = _getDiseaseColor(severity);

          return {
            'label': label,
            'value': value,
            'icon': icon,
            'color': color,
            'hasDisease': true
          };
        }
      }
    }

    if (processedDisease != null &&
        processedDisease.isNotEmpty &&
        processedDisease.toLowerCase() != 'healthy' &&
        processedDisease.toLowerCase() != 'no disease detected' &&
        processedDisease.toLowerCase() != 'health analysis') {
      label = translation.get('detected_disease');
      value = translation.translateDisease(processedDisease);
      icon = Icons.medical_services_rounded;

      final severity = widget.scanData['severity']?.toString() ?? 'Medium';
      color = _getDiseaseColor(severity);

      return {
        'label': label,
        'value': value,
        'icon': icon,
        'color': color,
        'hasDisease': true
      };
    }

    return {
      'label': label,
      'value': value,
      'icon': icon,
      'color': color,
      'hasDisease': false
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    final displayInfo = _getDiseaseDisplayInfo();
    final String? plantName = widget.scanData['plantName']?.toString();
    final String? confidence = widget.scanData['confidence']?.toString();
    final String? severity = widget.scanData['severity']?.toString();
    final String? cause = widget.scanData['cause']?.toString();
    final bool hasDisease = displayInfo['hasDisease'] as bool;

    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: translation.get('analysis_details'),
                    icon: Icons.analytics_rounded,
                    subtitle: translation.get('comprehensive_diagnosis'),
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                ),
                // Copy Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.content_copy_rounded),
                    color: const Color(0xFF8B5CF6),
                    iconSize: 20,
                    onPressed: _copyAllDetails,
                    tooltip: translation.get('copy_all_details'),
                  ),
                ),
                const SizedBox(width: 8),
                // Expand/Collapse Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isExpanded ? 0.5 : 0,
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                    color: const Color(0xFF8B5CF6),
                    iconSize: 20,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    tooltip: _isExpanded ? translation.get('collapse') : translation.get('expand'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [Colors.white, const Color(0xFFF8FAFC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Main Disease/Health Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (displayInfo['color'] as Color).withValues(alpha: isDark ? 0.15 : 0.08),
                            (displayInfo['color'] as Color).withValues(alpha: isDark ? 0.08 : 0.03),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: (displayInfo['color'] as Color).withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      child: DetailRow(
                        label: displayInfo['label'] as String,
                        value: displayInfo['value'] as String,
                        icon: displayInfo['icon'] as IconData,
                        iconColor: displayInfo['color'] as Color,
                        valueColor: displayInfo['color'] as Color,
                        isHighlight: true,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Plant Information
                          if (plantName != null &&
                              plantName.isNotEmpty &&
                              plantName != 'Unknown Plant') ...[
                            _AnimatedDetailRow(
                              label: translation.get('plant_species'),
                              value: translation.translatePlant(plantName),
                              icon: Icons.eco_rounded,
                              iconColor: const Color(0xFF10B981),
                              delay: 0.1,
                              animation: _animationController,
                            ),
                            const SizedBox(height: 16),
                            _buildDivider(isDark),
                            const SizedBox(height: 16),
                          ],

                          // Severity Level
                          if (hasDisease &&
                              severity != null &&
                              severity.isNotEmpty &&
                              severity.toLowerCase() != 'none') ...[
                            _AnimatedDetailRow(
                              label: translation.get('severity_level'),
                              value: translation.translateSeverity(severity),
                              icon: Icons.warning_rounded,
                              iconColor: _getSeverityColor(severity),
                              valueColor: _getSeverityColor(severity),
                              delay: 0.2,
                              animation: _animationController,
                            ),
                            const SizedBox(height: 16),
                            _buildDivider(isDark),
                            const SizedBox(height: 16),
                          ],

                          // Confidence Level
                          if (confidence != null && confidence.isNotEmpty) ...[
                            _AnimatedDetailRow(
                              label: translation.get('ai_confidence'),
                              value: '${_formatConfidence(confidence)}%',
                              icon: Icons.analytics_rounded,
                              iconColor: _getConfidenceColor(confidence),
                              valueColor: _getConfidenceColor(confidence),
                              delay: 0.3,
                              animation: _animationController,
                            ),
                            const SizedBox(height: 16),
                            _buildDivider(isDark),
                            const SizedBox(height: 16),
                          ],

                          // Cause Information
                          if (hasDisease && cause != null && cause.isNotEmpty) ...[
                            _AnimatedDetailRow(
                              label: translation.get('likely_cause'),
                              value: cause,
                              icon: Icons.search_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              delay: 0.4,
                              animation: _animationController,
                            ),
                          ],

                          // Healthy Plant Note
                          if (!hasDisease)
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF10B981).withValues(alpha: 0.1),
                                      const Color(0xFF10B981).withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        translation.get('no_diseases_detected'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                          height: 1.4,
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
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Color _getDiseaseColor(String? severity) {
    if (severity == null) return const Color(0xFFF59E0B);
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF3B82F6);
      case 'none':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getConfidenceColor(String confidence) {
    try {
      final value = double.tryParse(confidence) ?? 0;
      if (value >= 80) return const Color(0xFF10B981);
      if (value >= 60) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }

  String _formatConfidence(String confidence) {
    try {
      final value = double.tryParse(confidence) ?? 0;
      return value.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }
}

// Animated Detail Row
class _AnimatedDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final double delay;
  final AnimationController animation;

  const _AnimatedDetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
    required this.delay,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final adjustedValue = (animation.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: adjustedValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - adjustedValue)),
            child: child,
          ),
        );
      },
      child: DetailRow(
        label: label,
        value: value,
        icon: icon,
        iconColor: iconColor,
        valueColor: valueColor,
      ),
    );
  }
}