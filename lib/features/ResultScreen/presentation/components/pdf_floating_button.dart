// lib/features/ResultScreen/presentation/components/pdf_floating_button.dart
//
// A clean, pulse-animated extended FAB for triggering PDF generation.
// Drop-in replacement for the old PdfFloatingButton.
//
// Usage:
//   PdfFloatingButton(
//     onPressed: _handleGeneratePdf,
//     isGenerating: _isGeneratingPdf,
//   )

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  bool _isPressed = false;

  static const _orange = Color(0xFFFF6F00);
  static const _orangeLight = Color(0xFFFF8F00);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
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
    final disabled = widget.isGenerating;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return GestureDetector(
          onTapDown: disabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: disabled
              ? null
              : (_) {
            setState(() => _isPressed = false);
            HapticFeedback.mediumImpact();
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : (disabled ? 1.0 : _scaleAnim.value),
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: disabled
                    ? []
                    : [
                  BoxShadow(
                    color: _orange.withValues(alpha: _glowAnim.value * 0.5),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: disabled
                        ? const LinearGradient(
                      colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                    )
                        : const LinearGradient(
                      colors: [_orange, _orangeLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon / Spinner
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: disabled
                            ? const SizedBox(
                          key: ValueKey('spinner'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                            : const Icon(
                          key: ValueKey('icon'),
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Label
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          disabled ? 'Generating…' : 'Save as PDF',
                          key: ValueKey(disabled),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}