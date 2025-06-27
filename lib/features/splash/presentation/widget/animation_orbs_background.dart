import 'package:flutter/material.dart';

class AnimatedOrbsBackground extends StatefulWidget {
  final Animation<double> scaleAnimation;

  const AnimatedOrbsBackground({
    super.key,
    required this.scaleAnimation,
  });

  @override
  State<AnimatedOrbsBackground> createState() => _AnimatedOrbsBackgroundState();
}

class _AnimatedOrbsBackgroundState extends State<AnimatedOrbsBackground> with TickerProviderStateMixin {
  late List<AnimationController> _rotationControllers;
  late List<AnimationController> _opacityControllers;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _rotationControllers = List.generate(
      8,
          (index) => AnimationController(
        duration: Duration(milliseconds: 4000 + index * 500),
        vsync: this,
      )..repeat(reverse: true),
    );
    _opacityControllers = List.generate(
      8,
          (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + index * 300),
        vsync: this,
      )..repeat(reverse: true),
    );
    _rotationAnimations = _rotationControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    ))
        .toList();
    _opacityAnimations = _opacityControllers
        .map((controller) => Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    ))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _rotationControllers) {
      controller.dispose();
    }
    for (var controller in _opacityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(8, (index) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            widget.scaleAnimation,
            _rotationAnimations[index],
            _opacityAnimations[index],
          ]),
          builder: (context, child) {
            return Positioned(
              top: (index * 120.0) % MediaQuery.of(context).size.height,
              left: (index * 80.0) % MediaQuery.of(context).size.width,
              child: RotationTransition(
                turns: _rotationAnimations[index],
                child: FadeTransition(
                  opacity: _opacityAnimations[index],
                  child: Transform.scale(
                    scale: widget.scaleAnimation.value * (0.8 + (index * 0.1)),
                    child: Container(
                      width: 60 + (index * 15.0),
                      height: 60 + (index * 15.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (index.isEven
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary)
                                .withOpacity(0.15),
                            (index.isEven
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary)
                                .withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
      }),
    );
  }
}