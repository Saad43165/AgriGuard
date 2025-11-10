// lib/features/Profile/presentation/components/profile_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/constants/app_measurements.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onToggleEdit;
  final bool isEditing;

  const ProfileHeader({
    super.key,
    required this.onToggleEdit,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    // Safely get theme and measurements
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: AppMeasurements.defaultPadding,
          bottom: 16,
          right: 140,
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'My Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: AppMeasurements.getResponsiveFontSize(
                context,
                baseSize: 24,
              ),
              letterSpacing: 0.5,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface.withOpacity(0.0),
                theme.colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(
            right: AppMeasurements.defaultPadding,
            top: 8,
          ),
          child: _DebouncedEditButton(
            isEditing: isEditing,
            onPressed: onToggleEdit,
          ),
        ),
      ],
    );
  }
}

class _DebouncedEditButton extends StatefulWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const _DebouncedEditButton({
    required this.isEditing,
    required this.onPressed,
  });

  @override
  State<_DebouncedEditButton> createState() => _DebouncedEditButtonState();
}

class _DebouncedEditButtonState extends State<_DebouncedEditButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safely get responsive values
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context) ?? 16.0;
    final iconSize = AppMeasurements.getResponsiveIconSizeSmall(context) ?? 20.0;
    final fontSize = AppMeasurements.getResponsiveFontSize(context, baseSize: 14) ?? 14.0;
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context) ?? 8.0;

    return Tooltip(
      message: widget.isEditing ? 'Save changes' : 'Edit profile',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: widget.isEditing
              ? LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          )
              : LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
          border: Border.all(
            color: widget.isEditing
                ? Colors.transparent
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: widget.isEditing
              ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: _isPressed ? null : _handleTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppMeasurements.smallPadding,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    color: widget.isEditing ? Colors.white : theme.colorScheme.primary,
                    size: iconSize,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isEditing ? 'Save' : 'Edit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.isEditing ? Colors.white : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    if (_isPressed) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
    widget.onPressed();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _isPressed = false);
  }
}