import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'section_header.dart';

class RecommendationsCard extends StatefulWidget {
  final List<String> recommendations;

  const RecommendationsCard({
    super.key,
    required this.recommendations,
  });

  @override
  State<RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends State<RecommendationsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Treatment Plan',
                icon: Icons.medical_services_rounded,
                subtitle: 'Follow these steps in order',
                iconColor: const Color(0xFFEF4444),
              ),
            ),
            if (widget.recommendations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF4444).withOpacity(0.2),
                      const Color(0xFFEF4444).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_completedSteps.length}/${widget.recommendations.length}',
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
        Container(
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.recommendations.isEmpty
              ? _buildEmptyState(context, isDark)
              : Column(
            children: List.generate(
              widget.recommendations.length,
                  (index) => _TimelineRecommendationItem(
                text: widget.recommendations[index],
                index: index,
                isLast: index == widget.recommendations.length - 1,
                isDark: isDark,
                isCompleted: _completedSteps.contains(index),
                onToggle: () => _toggleStep(index),
                animationController: _animationController,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEF4444).withOpacity(0.1),
                  const Color(0xFFEF4444).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.3),
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
            'No Recommendations Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consult an expert for personalized guidance',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.black.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Timeline Recommendation Item
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
        final adjustedValue =
        (animationController.value - delay).clamp(0.0, 1.0);

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
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline with animated checkmark
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
                              ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                              : LinearGradient(
                            colors: [stepColor, stepColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isCompleted
                                  ? const Color(0xFF10B981)
                                  : stepColor)
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: isCompleted
                                ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('check'),
                              color: Colors.white,
                              size: 28,
                            )
                                : Text(
                              '${index + 1}',
                              key: ValueKey('number'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Timeline connector
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                stepColor.withOpacity(0.5),
                                stepColor.withOpacity(0.2),
                              ],
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
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCompleted
                              ? const Color(0xFF10B981)
                              : stepColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (isCompleted
                                ? const Color(0xFF10B981)
                                : stepColor)
                                .withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCompleted ? 'COMPLETED' : 'STEP ${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isCompleted
                                    ? const Color(0xFF10B981)
                                    : stepColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
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
                              ? (isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.4))
                              : (isDark ? Colors.white : Colors.black87),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        child: Text(cleanText),
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