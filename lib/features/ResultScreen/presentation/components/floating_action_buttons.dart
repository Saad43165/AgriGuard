import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class FloatingActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;
  final double? fabSize;
  final String heroTagPrefix; // Optional: for debugging or future Hero use

  const FloatingActionButtons({
    super.key,
    required this.onSave,
    required this.onShare,
    this.fabSize,
    required this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
  final VoidCallback onPressed;
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
      enabled: true,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onPressed();
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
                onTap: widget.onPressed,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
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
                      color: Theme.of(context).colorScheme.onPrimary,
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