import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/severity_indicator.dart';
import 'diagnosis_result.dart';

class DiagnosisCard extends StatefulWidget {
  final DiagnosisResult diagnosisResult;

  const DiagnosisCard({super.key, required this.diagnosisResult});

  @override
  State<DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<DiagnosisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color getDiseaseColor(DiagnosisResult result) {
    if (result.isHealthy) return const Color(0xFF10B981);
    if (result.requiresUrgentAction) return const Color(0xFFEF4444);
    if (result.severity.toLowerCase() == 'medium') return const Color(0xFFF59E0B);
    if (result.severity.toLowerCase() == 'low') return const Color(0xFF3B82F6);
    return const Color(0xFFEF4444);
  }

  IconData getDiseaseIcon(DiagnosisResult result) {
    if (result.isHealthy) return Icons.verified_rounded;
    if (result.requiresUrgentAction) return Icons.error_rounded;
    if (result.severity.toLowerCase() == 'medium')
      return Icons.warning_amber_rounded;
    return Icons.info_rounded;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('$label copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color diseaseColor = getDiseaseColor(widget.diagnosisResult);
    final IconData diseaseIcon = getDiseaseIcon(widget.diagnosisResult);
    final String confidenceText = '${widget.diagnosisResult.confidence}%';
    final double confidence =
        double.tryParse(widget.diagnosisResult.confidence) ?? 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
                    : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: diseaseColor.withOpacity(isDark ? 0.2 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated Header
                _AnimatedHeader(
                  diseaseColor: diseaseColor,
                  diseaseIcon: diseaseIcon,
                  disease: widget.diagnosisResult.disease,
                  confidence: confidence,
                  confidenceText: confidenceText,
                  isHealthy: widget.diagnosisResult.isHealthy,
                  isDark: isDark,
                  onCopy: () => _copyToClipboard(
                    widget.diagnosisResult.disease,
                    'Disease name',
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plant Name with Copy
                      _PlantInfoCard(
                        plantName: widget.diagnosisResult.plantName,
                        scientificName: widget.diagnosisResult.scientificName,
                        isDark: isDark,
                        onCopy: () => _copyToClipboard(
                          widget.diagnosisResult.plantName,
                          'Plant name',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confidence Meter
                      _ConfidenceMeter(
                        confidence: confidence,
                        color: diseaseColor,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 20),

                      // Description (expandable)
                      if (widget.diagnosisResult.description != null &&
                          widget.diagnosisResult.description!.isNotEmpty)
                        _ExpandableDescription(
                          description: widget.diagnosisResult.description!,
                          diseaseColor: diseaseColor,
                          isDark: isDark,
                          isExpanded: _isExpanded,
                          onToggle: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isExpanded = !_isExpanded);
                          },
                        ),

                      if (widget.diagnosisResult.description != null &&
                          widget.diagnosisResult.description!.isNotEmpty)
                        const SizedBox(height: 20),

                      // Severity with Animation
                      _AnimatedSeverityIndicator(
                        severity: widget.diagnosisResult.severity,
                        color: diseaseColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Header Component
class _AnimatedHeader extends StatefulWidget {
  final Color diseaseColor;
  final IconData diseaseIcon;
  final String disease;
  final double confidence;
  final String confidenceText;
  final bool isHealthy;
  final bool isDark;
  final VoidCallback onCopy;

  const _AnimatedHeader({
    required this.diseaseColor,
    required this.diseaseIcon,
    required this.disease,
    required this.confidence,
    required this.confidenceText,
    required this.isHealthy,
    required this.isDark,
    required this.onCopy,
  });

  @override
  State<_AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<_AnimatedHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.diseaseColor.withOpacity(widget.isDark ? 0.15 : 0.1),
            widget.diseaseColor.withOpacity(widget.isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        border: Border(
          bottom: BorderSide(
            color: widget.diseaseColor.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Pulsing Disease Icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.diseaseColor,
                      widget.diseaseColor.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.diseaseColor
                          .withOpacity(0.4 + _pulseController.value * 0.3),
                      blurRadius: 12 + _pulseController.value * 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.diseaseIcon,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isHealthy ? 'Healthy Plant' : 'Disease Detected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onLongPress: widget.onCopy,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.disease,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: widget.diseaseColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Animated Confidence Badge
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: widget.confidence),
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.diseaseColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: widget.diseaseColor,
                      ),
                    ),
                    Text(
                      'Confidence',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Plant Info Card with Copy
class _PlantInfoCard extends StatelessWidget {
  final String plantName;
  final String? scientificName;
  final bool isDark;
  final VoidCallback onCopy;

  const _PlantInfoCard({
    required this.plantName,
    this.scientificName,
    required this.isDark,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onCopy,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
              const Color(0xFF10B981).withOpacity(0.15),
              const Color(0xFF10B981).withOpacity(0.05),
            ]
                : [
              const Color(0xFF10B981).withOpacity(0.08),
              const Color(0xFF10B981).withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant Species',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plantName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (scientificName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        scientificName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                        ),
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
}

// Confidence Meter
class _ConfidenceMeter extends StatelessWidget {
  final double confidence;
  final Color color;
  final bool isDark;

  const _ConfidenceMeter({
    required this.confidence,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence Level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
              ),
            ),
            Text(
              '${confidence.toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: confidence / 100),
            builder: (context, value, child) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
      ],
    );
  }
}

// Expandable Description
class _ExpandableDescription extends StatelessWidget {
  final String description;
  final Color diseaseColor;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableDescription({
    required this.description,
    required this.diseaseColor,
    required this.isDark,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: diseaseColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: diseaseColor,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Severity Indicator
class _AnimatedSeverityIndicator extends StatefulWidget {
  final String severity;
  final Color color;

  const _AnimatedSeverityIndicator({
    required this.severity,
    required this.color,
  });

  @override
  State<_AnimatedSeverityIndicator> createState() =>
      _AnimatedSeverityIndicatorState();
}

class _AnimatedSeverityIndicatorState
    extends State<_AnimatedSeverityIndicator> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: SeverityIndicator(
            severity: widget.severity,
            showLabel: true,
            showDescription: true,
          ),
        );
      },
    );
  }
}