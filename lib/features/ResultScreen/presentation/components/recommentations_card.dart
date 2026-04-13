import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
import 'section_header.dart';

class RecommendationsCard extends StatefulWidget {
  final dynamic recommendations; // Can be List<String> or Map with en/ur
  final String? severity; // Optional severity level
  final List<String>? precautions; // Optional precautions

  const RecommendationsCard({
    super.key,
    required this.recommendations,
    this.severity,
    this.precautions,
  });

  @override
  State<RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends State<RecommendationsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Set<int> _completedSteps = {};
  List<String> _processedRecommendations = []; // Explicitly List<String>

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _processRecommendations();
  }

  @override
  void didUpdateWidget(RecommendationsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendations != widget.recommendations) {
      _processRecommendations();
    }
  }

  void _processRecommendations() {
    final translation = Provider.of<TranslationService>(context, listen: false);

    if (widget.recommendations == null) {
      _processedRecommendations = [];
      return;
    }

    // Create a temporary list to build results
    List<String> tempList = [];

    // Handle different data formats
    if (widget.recommendations is List) {
      final list = widget.recommendations as List;

      if (list.isEmpty) {
        _processedRecommendations = [];
        return;
      }

      // Check if list contains maps (bilingual format)
      if (list.isNotEmpty && list.first is Map) {
        // Process each map item and convert to String
        tempList = list.map((item) {
          if (item is Map) {
            // Extract the appropriate language text
            return translation.isUrdu
                ? (item['ur'] ?? item['en'] ?? '').toString()
                : (item['en'] ?? item['ur'] ?? '').toString();
          }
          // If not a map, convert to string
          return item.toString();
        }).where((s) => s.isNotEmpty).toList();
      } else {
        // Simple string list - ensure all items are strings
        tempList = list.map((e) => e.toString()).toList();
      }
    } else if (widget.recommendations is Map) {
      // Single recommendation map with en/ur
      final map = widget.recommendations as Map;
      final text = translation.isUrdu
          ? (map['ur'] ?? map['en'] ?? '').toString()
          : (map['en'] ?? map['ur'] ?? '').toString();
      if (text.isNotEmpty) {
        tempList = [text];
      }
    } else if (widget.recommendations is String) {
      // Single string - split by common delimiters if needed
      String text = widget.recommendations.toString();
      if (text.contains('\n') || text.contains(';') || text.contains(',')) {
        tempList = text
            .split(RegExp(r'[\n;,.]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length > 3)
            .toList();
      } else {
        tempList = [text];
      }
    }

    // Assign the processed list (ensuring it's List<String>)
    _processedRecommendations = tempList;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleStep(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_completedSteps.contains(index)) {
        _completedSteps.remove(index);
      } else {
        _completedSteps.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translation = Provider.of<TranslationService>(context);

    // Re-process recommendations when language changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processRecommendations();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: translation.get('treatment_plan'),
                icon: Icons.medical_services_rounded,
                subtitle: translation.get('follow_steps'),
                iconColor: const Color(0xFFEF4444),
              ),
            ),
            if (_processedRecommendations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF4444).withValues(alpha: 0.2),
                      const Color(0xFFEF4444).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_completedSteps.length}/${_processedRecommendations.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Severity badge if provided
        if (widget.severity != null && widget.severity != 'None' && widget.severity != 'N/A')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getSeverityColor(widget.severity!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSeverityColor(widget.severity!).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 18,
                    color: _getSeverityColor(widget.severity!),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    translation.isUrdu
                        ? _getSeverityUrdu(widget.severity!)
                        : 'Severity: ${widget.severity}',
                    style: TextStyle(
                      color: _getSeverityColor(widget.severity!),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        Container(
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
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
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
          child: _processedRecommendations.isEmpty
              ? _buildEmptyState(context, isDark, translation)
              : Column(
            children: List.generate(
              _processedRecommendations.length,
                  (index) => _TimelineRecommendationItem(
                text: _processedRecommendations[index],
                index: index,
                isLast: index == _processedRecommendations.length - 1,
                isDark: isDark,
                isCompleted: _completedSteps.contains(index),
                onToggle: () => _toggleStep(index),
                animationController: _animationController,
              ),
            ),
          ),
        ),

        // Precautions section if provided
        if (widget.precautions != null && widget.precautions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildPrecautionsSection(context, isDark, translation),
          ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'none': return const Color(0xFF4CAF50);
      case 'low': return const Color(0xFF8BC34A);
      case 'medium': return const Color(0xFFFFC107);
      case 'high': return const Color(0xFFFF9800);
      case 'critical': return const Color(0xFFF44336);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String _getSeverityUrdu(String severity) {
    switch (severity.toLowerCase()) {
      case 'none': return 'شدت: کوئی نہیں';
      case 'low': return 'شدت: کم';
      case 'medium': return 'شدت: درمیانی';
      case 'high': return 'شدت: زیادہ';
      case 'critical': return 'شدت: انتہائی';
      default: return 'شدت: نامعلوم';
    }
  }

  Widget _buildPrecautionsSection(BuildContext context, bool isDark, TranslationService translation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                translation.get('precautions'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.precautions!.map((precaution) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    precaution,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, TranslationService translation) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444).withValues(alpha: 0.1),
                  const Color(0xFFEF4444).withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            translation.get('no_recommendations'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translation.get('consult_expert_guidance'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimelineRecommendationItem extends StatelessWidget {
  final String text;
  final int index;
  final bool isLast;
  final bool isDark;
  final bool isCompleted;
  final VoidCallback onToggle;
  final AnimationController animationController;

  const _TimelineRecommendationItem({
    required this.text,
    required this.index,
    required this.isLast,
    required this.isDark,
    required this.isCompleted,
    required this.onToggle,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final translation = Provider.of<TranslationService>(context);
    final stepColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
    ];

    final stepColor = stepColors[index % stepColors.length];
    String cleanText = text.trim();

    if (cleanText.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final delay = index * 0.1;
        final adjustedValue = (animationController.value - delay).clamp(0.0, 1.0);

        return Opacity(
          opacity: adjustedValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - adjustedValue)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.only(
          topLeft: index == 0 ? const Radius.circular(18) : Radius.zero,
          topRight: index == 0 ? const Radius.circular(18) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(18) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(18) : Radius.zero,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                              : LinearGradient(colors: [stepColor, stepColor.withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: (isCompleted ? const Color(0xFF10B981) : stepColor).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(scale: animation, child: child);
                            },
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, key: ValueKey('check'), color: Colors.white, size: 28)
                                : Text('${index + 1}',
                                key: const ValueKey('number'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [stepColor.withValues(alpha: 0.5), stepColor.withValues(alpha: 0.2)],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCompleted ? const Color(0xFF10B981) : stepColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (isCompleted ? const Color(0xFF10B981) : stepColor).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isCompleted
                              ? translation.get('completed')
                              : '${translation.get('step')} ${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? const Color(0xFF10B981) : stepColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4))
                              : (isDark ? Colors.white : Colors.black87),
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                        child: Text(
                          cleanText,
                          textAlign: translation.isUrdu ? TextAlign.right : TextAlign.left,
                        ),
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