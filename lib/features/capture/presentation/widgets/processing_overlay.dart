import 'package:flutter/material.dart';
import 'dart:io';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';

/// Botanical-style scanning animation overlay
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
  late AnimationController _pulseRingCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _textFadeCtrl;
  late Animation<double> _pulseRing;
  late Animation<double> _rotate;
  late Animation<double> _textFade;

  int _currentStep = 0;
  int _currentTextIndex = 0;

  final List<String> _steps = [
    'Analyzing image',
    'Detecting leaves',
    'Identifying plant',
    'Checking for diseases',
  ];

  final List<String> _cyclingTexts = [
    'Detecting leaf...',
    'Identifying plant...',
    'Analyzing disease...',
    'Getting treatment...',
  ];

  @override
  void initState() {
    super.initState();

    _stepController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);

    _pulseRingCtrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);
    _pulseRing = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _pulseRingCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(
        duration: const Duration(seconds: 3), vsync: this)
      ..repeat();
    _rotate = Tween<double>(begin: 0, end: 1).animate(_rotateCtrl);

    _textFadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this)
      ..value = 1.0;
    _textFade = CurvedAnimation(parent: _textFadeCtrl, curve: Curves.easeOut);

    _animateSteps();
    _cycleText();
  }

  void _animateSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _currentStep = i + 1);
    }
  }

  void _cycleText() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) break;
      await _textFadeCtrl.reverse();
      if (mounted) {
        setState(() => _currentTextIndex = (_currentTextIndex + 1) % _cyclingTexts.length);
      }
      if (mounted) await _textFadeCtrl.forward();
    }
  }

  @override
  void dispose() {
    _stepController.dispose();
    _pulseRingCtrl.dispose();
    _rotateCtrl.dispose();
    _textFadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Image with scan animation — top 55%
          Expanded(
            flex: 55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.imagePath != null)
                  Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                else
                  Container(color: Colors.black),
                Container(color: Colors.black.withValues(alpha: 0.55)),
                const _GridOverlay(),
                const _CornerBrackets(),
                _ScanLine(animation: widget.pulseAnimation),
                
                // Pulsing ring in center
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseRing,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseRing.value,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _rotate,
                          builder: (_, __) => Transform.rotate(
                            angle: _rotate.value * 2 * 3.14159,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer dashed ring logic can go here, but for simplicity we rely on the rotate
                                const Icon(
                                  Icons.eco_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                                // Inner geometric shape
                                Positioned(
                                  top: 15,
                                  child: Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom white panel — 45%
          Expanded(
            flex: 45,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cycling text with fade
                  FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      _cyclingTexts[_currentTextIndex],
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2B1E), letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('We are checking your plant, just wait a second 🌿',
                      style: TextStyle(fontSize: 13, color: Color(0xFF718096), height: 1.4)),
                  const SizedBox(height: 18),
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
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A subtle geometric grid overlay for a high-tech scanning feel
class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double spacing = 30.0;
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
