import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_measurements.dart';

class StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatItem({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    final iconSize = AppMeasurements.getResponsiveIconSizeSmall(context);
    final fontSizeMedium = AppMeasurements.getResponsiveFontSize(context, baseSize: 16);
    final fontSizeSmall = AppMeasurements.getResponsiveFontSize(context, baseSize: 12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(smallPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
        SizedBox(height: smallPadding * 0.5),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: fontSizeMedium,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.7),
            fontSize: fontSizeSmall,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}