import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class SliderWidget extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const SliderWidget({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          SizedBox(width: padding * 2, child: Text(label)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          SizedBox(width: padding, child: Text(value.toStringAsFixed(2))),
        ],
      ),
    );
  }
}