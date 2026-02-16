import 'package:flutter/material.dart';

class PdfFloatingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isGenerating;

  const PdfFloatingButton({
    super.key,
    required this.onPressed,
    this.isGenerating = false,
  });

  @override
  State<PdfFloatingButton> createState() => _PdfFloatingButtonState();
}

class _PdfFloatingButtonState extends State<PdfFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary
                    .withOpacity(_glowAnimation.value * 0.4),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
          child: Transform.scale(
            scale: widget.isGenerating ? 1.0 : _scaleAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: widget.isGenerating ? null : widget.onPressed,
              backgroundColor: widget.isGenerating
                  ? theme.colorScheme.primary.withOpacity(0.7)
                  : theme.colorScheme.primary,
              elevation: 8,
              icon: widget.isGenerating
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
                  : const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                widget.isGenerating ? 'Generating...' : 'Save PDF',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}