import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_measurements.dart';

/// A row displaying contact information with an icon, label, and value, with tap support.
class ContactRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double itemSpacing;
  final Future<void> Function()? onTap;

  const ContactRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.itemSpacing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      button: onTap != null,
      child: InkWell(
        onTap: onTap != null
            ? () async {
          HapticFeedback.lightImpact();
          await onTap!();
        }
            : null,
        borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: itemSpacing / 2),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(itemSpacing),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppMeasurements.getResponsiveFontSize(context, baseSize: 18),
                ),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    SizedBox(height: itemSpacing * 0.5),
                    Text(
                      value.isEmpty ? 'Not available' : value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}