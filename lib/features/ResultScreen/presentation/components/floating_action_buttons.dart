import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class FloatingActionButtons extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final double? fabSize;

  const FloatingActionButtons({
    super.key,
    required this.onSave,
    required this.onShare,
    this.fabSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _CustomFab(
          onPressed: onSave,
          icon: Icons.save_rounded,
          tooltip: 'Save Report',
          semanticLabel: 'Save Report',
          fabSize: fabSize,
        ),
        const SizedBox(height: AppMeasurements.defaultPadding),
        _CustomFab(
          onPressed: onShare,
          icon: Icons.share_rounded,
          tooltip: 'Share Results',
          semanticLabel: 'Share Results',
          fabSize: fabSize,
        ),
      ],
    );
  }
}

class _CustomFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final double? fabSize;

  const _CustomFab({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    this.fabSize,
  });

  @override
  _CustomFabState createState() => _CustomFabState();
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
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
        onTapUp: widget.onPressed != null
            ? (_) {
          _controller.reverse();
          widget.onPressed!();
        }
            : null,
        onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            disabledElevation: 0,
            tooltip: widget.tooltip,
            mini: widget.fabSize != null && widget.fabSize! < 40,
            child: Container(
              width: widget.fabSize ??
                  AppMeasurements.getResponsiveFabSize(context, baseSize: 56),
              height: widget.fabSize ??
                  AppMeasurements.getResponsiveFabSize(context, baseSize: 56),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.onPressed != null
                      ? [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ]
                      : [
                    Colors.grey.shade600,
                    Colors.grey.shade800,
                  ],
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.onPressed != null
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.grey.shade400,
                  size: AppMeasurements.getResponsiveIconSizeMedium(context),
                  semanticLabel: '${widget.semanticLabel} Icon',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}