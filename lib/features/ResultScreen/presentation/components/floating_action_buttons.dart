import 'package:flutter/material.dart';
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
        if (isAutoSaved) _buildAutoSavedBadge(context),
        _CustomFab(
          onPressed: onViewHistory,
          icon: Icons.history_rounded,
          tooltip: 'View Scan History',
          semanticLabel: 'View History',
          fabSize: fabSize,
          isLoading: isProcessing,
          backgroundColor: Colors.blue,
        ),
        const SizedBox(height: AppMeasurements.defaultPadding),
        _CustomFab(
          onPressed: onShare,
          icon: Icons.share_rounded,
          tooltip: 'Share Results',
          semanticLabel: 'Share Results',
          fabSize: fabSize,
          isLoading: isProcessing,
          backgroundColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAutoSavedBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            'Auto-saved',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
  final Color backgroundColor;

  const _CustomFab({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    this.fabSize,
    this.isLoading = false,
    required this.backgroundColor,
  });

  @override
  State<_CustomFab> createState() => _CustomFabState();
}

class _CustomFabState extends State<_CustomFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
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
    final isMini = size < 40;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: !widget.isLoading,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => !widget.isLoading ? _controller.forward() : null,
          onTapUp: (_) {
            _controller.reverse();
            if (!widget.isLoading) {
              widget.onPressed();
            }
          },
          onTapCancel: _controller.reverse,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(size),
                onTap: widget.isLoading ? null : widget.onPressed,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.backgroundColor,
                        widget.backgroundColor.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.backgroundColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                      width: isMini ? 16 : 20,
                      height: isMini ? 16 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(
                      widget.icon,
                      color: Colors.white,
                      size: isMini
                          ? AppMeasurements.getResponsiveIconSizeSmall(context)
                          : AppMeasurements.getResponsiveIconSizeMedium(context),
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