import 'package:flutter/material.dart';
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
          Tooltip(
            message: isEditing ? 'Save profile changes' : 'Edit profile',
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
                  onTap: onToggleEdit,
                  child: Padding(
                    padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
                    child: Semantics(
                      label: isEditing ? 'Save profile changes' : 'Edit profile',
                      child: Icon(
                        isEditing ? Icons.check_rounded : Icons.edit_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppMeasurements.getResponsiveIconSizeMedium(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}