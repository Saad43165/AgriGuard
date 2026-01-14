import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';

class FloatingActionButtons extends StatelessWidget {
  final VoidCallback onViewHistory;
  final VoidCallback onShare;
  final double? fabSize;
  final String heroTagPrefix;
  final bool isProcessing;
  final bool isAutoSaved;

  const FloatingActionButtons({
    super.key,
    required this.onViewHistory,
    required this.onShare,
    this.fabSize,
    required this.heroTagPrefix,
    this.isProcessing = false,
    this.isAutoSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Auto-saved Badge (if applicable)
        if (isAutoSaved) _buildAutoSavedBadge(context),

        // View History FAB
        _CustomFab(
          onPressed: onViewHistory,
          icon: Icons.history_rounded,
          tooltip: 'View Scan History',
          semanticLabel: 'View scan history',
          fabSize: fabSize,
          isLoading: isProcessing,
          heroTag: '${heroTagPrefix}_history',
          backgroundColor: const Color(0xFF2196F3), // Blue
          label: 'History',
        ),

        const SizedBox(height: 12),

        // Share FAB
        _CustomFab(
          onPressed: onShare,
          icon: Icons.share_rounded,
          tooltip: 'Share Results',
          semanticLabel: 'Share scan results',
          fabSize: fabSize,
          isLoading: isProcessing,
          heroTag: '${heroTagPrefix}_share',
          backgroundColor: const Color(0xFF9C27B0), // Purple
          label: 'Share',
        ),
      ],
    );
  }

  Widget _buildAutoSavedBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Auto-saved',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final double? fabSize;
  final bool isLoading;
  final String heroTag;
  final Color backgroundColor;
  final String label;

  const _CustomFab({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    this.fabSize,
    this.isLoading = false,
    required this.heroTag,
    required this.backgroundColor,
    required this.label,
  });

  @override
  State<_CustomFab> createState() => _CustomFabState();
}

class _CustomFabState extends State<_CustomFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.fabSize ?? AppMeasurements.getResponsiveFabSize(context, baseSize: 56);
    final iconSize = size < 40
        ? AppMeasurements.getResponsiveIconSizeSmall(context)
        : AppMeasurements.getResponsiveIconSizeMedium(context);

    return Hero(
      tag: widget.heroTag,
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: !widget.isLoading,
        child: Tooltip(
          message: widget.tooltip,
          preferBelow: false,
          verticalOffset: -10,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) {
                if (!widget.isLoading) {
                  _controller.forward();
                  HapticFeedback.lightImpact();
                }
              },
              onTapUp: (_) {
                _controller.reverse();
                if (!widget.isLoading) {
                  widget.onPressed();
                }
              },
              onTapCancel: () => _controller.reverse(),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.backgroundColor,
                        widget.backgroundColor.withOpacity(0.85),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(_isHovered ? 0.5 : 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.backgroundColor.withOpacity(0.4),
                        blurRadius: _isHovered ? 16 : 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(size),
                      onTap: widget.isLoading ? null : widget.onPressed,
                      child: Center(
                        child: widget.isLoading
                            ? SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Icon(
                          widget.icon,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}