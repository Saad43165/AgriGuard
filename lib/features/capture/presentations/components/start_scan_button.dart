import 'package:flutter/material.dart';

class StartScanButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Animation<double>? animation;
  final bool isPulsing;

  const StartScanButton({
    super.key,
    required this.onPressed,
    this.animation,
    this.isPulsing = true, required bool isGuestMode, required int remainingScans,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive width
    final buttonWidth = screenWidth * 0.7;
    final buttonHeight = 56.0;

    Widget button = Container(
      width: buttonWidth.clamp(200, 300), // Min 200, Max 300
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          splashColor: Colors.white.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Flexible(
                child: Text(
                  'Start Plant Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth > 400 ? 16 : 14,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (animation != null && isPulsing) {
      button = ScaleTransition(
        scale: animation!,
        child: button,
      );
    }

    return button; // Just return the button, no padding
  }
}