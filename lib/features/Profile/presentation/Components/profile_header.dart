import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/constants/app_measurements.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onToggleEdit;
  final bool isEditing;

  const ProfileHeader({super.key, required this.onToggleEdit, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile header with edit toggle',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 28),
              ),
            ),
          ),
          // DEBOUNCED BUTTON
          _DebouncedEditButton(
            isEditing: isEditing,
            onPressed: onToggleEdit,
          ),
        ],
      ),
    );
  }
}

// NEW: Debounced Edit Button
class _DebouncedEditButton extends StatefulWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const _DebouncedEditButton({required this.isEditing, required this.onPressed});

  @override
  State<_DebouncedEditButton> createState() => _DebouncedEditButtonState();
}

class _DebouncedEditButtonState extends State<_DebouncedEditButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.isEditing ? 'Save profile changes' : 'Edit profile',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
            onTap: _isPressed ? null : _handleTap,
            child: Padding(
              padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
              child: Icon(
                widget.isEditing ? Icons.check_rounded : Icons.edit_rounded,
                color: widget.isEditing
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: AppMeasurements.getResponsiveIconSizeMedium(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    if (_isPressed) return;
    _isPressed = true;
    HapticFeedback.lightImpact();
    widget.onPressed();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isPressed = false);
  }
}