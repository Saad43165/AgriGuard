import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnalysisOptionCard extends StatefulWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final bool isAvailable;
  final Animation<double>? pulseAnimation;
  final VoidCallback onTap;

  const AnalysisOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isAvailable,
    this.pulseAnimation,
    required this.onTap,
  });

  @override
  State<AnalysisOptionCard> createState() => _AnalysisOptionCardState();
}

class _AnalysisOptionCardState extends State<AnalysisOptionCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.option['color'] as Color;

    Widget card = GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: widget.isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          )
              : LinearGradient(
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
          border: Border.all(
            color: widget.isSelected
                ? Colors.white.withOpacity(0.3)
                : isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.06),
            width: widget.isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (widget.isSelected) ...[
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Shimmer effect for selected card
              if (widget.isSelected)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Positioned(
                      top: -100,
                      left: -100 + (_shimmerController.value * 400),
                      child: Container(
                        width: 100,
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon and Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: widget.isSelected
                                ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            )
                                : LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.4)
                                  : color.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: widget.isSelected
                                ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : null,
                          ),
                          child: Icon(
                            widget.option['icon'] as IconData,
                            color: widget.isSelected ? Colors.white : color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and Duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.option['title'] as String,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: widget.isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black87),
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: widget.isSelected
                                        ? Colors.white.withOpacity(0.3)
                                        : color.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: widget.isSelected
                                          ? Colors.white
                                          : color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.option['duration'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isSelected
                                            ? Colors.white
                                            : color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      widget.option['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.9)
                            : (isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.6)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Feature Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.option['features'] as List<String>)
                          .take(3)
                          .map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: widget.isSelected
                                ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.2),
                              ],
                            )
                                : LinearGradient(
                              colors: [
                                color.withOpacity(0.15),
                                color.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : color.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: widget.isSelected ? Colors.white : color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isSelected ? Colors.white : color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Selection Indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: widget.isSelected
                            ? LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        )
                            : LinearGradient(
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isSelected
                              ? Colors.white
                              : color.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              widget.isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              key: ValueKey(widget.isSelected),
                              color: widget.isSelected ? color : color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isSelected ? 'SELECTED' : 'SELECT THIS METHOD',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: widget.isSelected
                                  ? color
                                  : (isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.6)),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark Badge for Selected
              if (widget.isSelected)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF0F0F0)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.pulseAnimation != null && widget.isSelected) {
      return ScaleTransition(scale: widget.pulseAnimation!, child: card);
    }

    return card;
  }
}