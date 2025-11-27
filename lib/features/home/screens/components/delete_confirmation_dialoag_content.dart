// lib/features/scan_history/presentation/components/delete_confirmation_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_measurements.dart';

class DeleteConfirmationDialogContent extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const DeleteConfirmationDialogContent({
    super.key,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Consistent background colors with app theme
    final backgroundColor = isDark
        ? const Color(0xFF1A1A2E)
        : theme.colorScheme.surface;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.08, // Better horizontal spacing
        vertical: 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          minWidth: screenWidth * 0.8, // Ensure it takes good width
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppMeasurements.getResponsivePadding(context) * 1.5,
            vertical: AppMeasurements.getResponsivePadding(context) * 1.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon with gradient background
              Container(
                padding: EdgeInsets.all(
                  AppMeasurements.getResponsivePadding(context) * 0.8,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error.withOpacity(0.2),
                      theme.colorScheme.error.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: theme.colorScheme.error,
                  size: AppMeasurements.getResponsiveIconSizeLarge(context) * 1.2,
                ),
              ),

              SizedBox(
                height: AppMeasurements.getResponsivePadding(context) * 0.8,
              ),

              // Title with gradient
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    theme.colorScheme.error,
                    theme.colorScheme.error.withOpacity(0.8),
                  ],
                ).createShader(bounds),
                child: Text(
                  'Delete Scan?',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 22,
                    ),
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(
                height: AppMeasurements.getResponsiveSmallPadding(context) * 0.8,
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'This scan will be permanently deleted. This action cannot be undone.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: AppMeasurements.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(
                height: AppMeasurements.getResponsivePadding(context) * 1.2,
              ),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: _ActionButton(
                      label: 'Cancel',
                      onPressed: onCancel ?? () => Navigator.pop(context, false),
                      isPrimary: false,
                      backgroundColor: isDark
                          ? const Color(0xFF0F0F23)
                          : theme.colorScheme.surface,
                      borderColor: theme.colorScheme.outline.withOpacity(0.3),
                      textColor: theme.colorScheme.onSurface,
                    ),
                  ),

                  SizedBox(
                    width: AppMeasurements.getResponsiveSmallPadding(context),
                  ),

                  // Delete Button
                  Expanded(
                    child: _ActionButton(
                      label: 'Delete',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, true);
                        onConfirm();
                      },
                      isPrimary: true,
                      backgroundColor: theme.colorScheme.error,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.backgroundColor,
    this.borderColor,
    required this.textColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(
            AppMeasurements.getResponsiveBorderRadius(context),
          ),
          border: widget.borderColor != null
              ? Border.all(
            color: widget.borderColor!,
            width: 1.5,
          )
              : null,
          boxShadow: widget.isPrimary
              ? [
            BoxShadow(
              color: widget.backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              AppMeasurements.getResponsiveBorderRadius(context),
            ),
            onTap: () {
              _scaleController.forward().then((_) {
                _scaleController.reverse();
                widget.onPressed();
              });
            },
            splashColor: widget.isPrimary
                ? Colors.white.withOpacity(0.2)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            highlightColor: widget.isPrimary
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Center(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: AppMeasurements.getResponsiveFontSize(
                    context,
                    baseSize: 15,
                  ),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}