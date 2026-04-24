import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_themes.dart';

class AnimatedShutterButton extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedShutterButton({super.key, required this.onTap});
  @override
  State<AnimatedShutterButton> createState() => _AnimatedShutterButtonState();
}

class _AnimatedShutterButtonState extends State<AnimatedShutterButton>
    with TickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scale;
  late Animation<double> _pulseScale;
  bool _flashing = false;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
        CurvedAnimation(parent: _tapCtrl, curve: Curves.easeIn));
        
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { 
    _tapCtrl.dispose(); 
    _pulseCtrl.dispose();
    super.dispose(); 
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
    await _tapCtrl.forward();
    await _tapCtrl.reverse();
    // White flash
    if (mounted) setState(() => _flashing = true);
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) setState(() => _flashing = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing background glow
        AnimatedBuilder(
          animation: _pulseScale,
          builder: (_, __) => Transform.scale(
            scale: _pulseScale.value,
            child: Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        
        // Main button
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _scale,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // White flash overlay
        if (_flashing)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
