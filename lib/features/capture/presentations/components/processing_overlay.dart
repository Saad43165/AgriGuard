import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/widgets/app_themes.dart';

/// Botanical-style scanning animation overlay
/// Shows leaf image with corner brackets + animated step list
class ProcessingOverlay extends StatefulWidget {
  final String selectedMethod;
  final bool isProcessing;
  final bool isGuestMode;
  final int remainingScans;
  final Animation<double> pulseAnimation;
  final String processingMessage;
  final Map<String, bool> modelStatuses;
  final VoidCallback onCancel;
  final String? imagePath;

  const ProcessingOverlay({
    super.key,
    required this.selectedMethod,
    required this.isProcessing,
    required this.isGuestMode,
    required this.remainingScans,
    required this.pulseAnimation,
    required this.processingMessage,
    required this.modelStatuses,
    required this.onCancel,
    this.imagePath,
  });

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _stepController;
  int _currentStep = 0;

  final List<String> _steps = [
    'Analyzing image',
    'Detecting leaves',
    'Identifying plant',
    'Checking for diseases',
  ];

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 800), vsync: this);
    _animateSteps();
  }

  void _animateSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _currentStep = i + 1);
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Image with corner brackets — top 55%
          Expanded(
            flex: 55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Leaf image
                if (widget.imagePath != null)
                  Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                else
                  Container(color: Colors.black),
                // Dark overlay
                Container(color: Colors.black.withValues(alpha: 0.4)),
                // Corner brackets
                const _CornerBrackets(),
                // Scanning line animation
                _ScanLine(animation: widget.pulseAnimation),
              ],
            ),
          ),

          // Bottom white panel — 45%
          Expanded(
            flex: 45,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scanning...',
                      style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2B1E), letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 4),
                  const Text('We are checking your plant, just wait a second 🌿',
                      style: TextStyle(fontSize: 13, color: Color(0xFF718096), height: 1.4)),
                  const SizedBox(height: 20),
                  // Animated steps
                  ..._steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final step = entry.value;
                    final isDone = _currentStep > i;
                    final isActive = _currentStep == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? AppColors.primary : Colors.transparent,
                              border: Border.all(
                                color: isDone ? AppColors.primary
                                    : isActive ? AppColors.primary
                                    : const Color(0xFFCBD5E0),
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                                : isActive
                                    ? const SizedBox(
                                        width: 10, height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppColors.primary))
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Text(step, style: TextStyle(
                            fontSize: 14,
                            fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isDone || isActive
                                ? const Color(0xFF1B2B1E)
                                : const Color(0xFF9E9E9E),
                          )),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White corner brackets overlay
class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Stack(
        children: [
          // Top-left
          Positioned(top: 0, left: 0, child: _bracket(true, true)),
          // Top-right
          Positioned(top: 0, right: 0, child: _bracket(true, false)),
          // Bottom-left
          Positioned(bottom: 0, left: 0, child: _bracket(false, true)),
          // Bottom-right
          Positioned(bottom: 0, right: 0, child: _bracket(false, false)),
        ],
      ),
    );
  }

  Widget _bracket(bool top, bool left) {
    return SizedBox(
      width: 36, height: 36,
      child: CustomPaint(painter: _BracketPainter(top: top, left: left)),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool top, left;
  const _BracketPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width * 0.7 : -size.width * 0.7;
    final dy = top ? size.height * 0.7 : -size.height * 0.7;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Animated horizontal scan line
class _ScanLine extends StatelessWidget {
  final Animation<double> animation;
  const _ScanLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.55 * animation.value,
          left: 32, right: 32,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
