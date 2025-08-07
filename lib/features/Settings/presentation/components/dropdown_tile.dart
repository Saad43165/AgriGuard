import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';

class DropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const DropdownTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);

    return Semantics(
      label: 'Dropdown setting for $title',
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(smallPadding),
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
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
          ),
          SizedBox(width: smallPadding),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: AppMeasurements.getResponsiveSize(context, baseSize: 150),
            child: DropdownButton<String>(
              value: value,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
                size: AppMeasurements.getResponsiveIconSizeSmall(context),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}