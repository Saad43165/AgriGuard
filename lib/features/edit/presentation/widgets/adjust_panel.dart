import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';
import 'slider_widget.dart';

class AdjustPanel extends StatelessWidget {
  final Function(String, double) onAdjustmentChanged;

  const AdjustPanel({super.key, required this.onAdjustmentChanged});

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          SliderWidget(
            label: AppStrings.brightness,
            value: 0.0,
            min: -1.0,
            max: 1.0,
            onChanged: (value) => onAdjustmentChanged('Brightness', value),
          ),
          SliderWidget(
            label: AppStrings.contrast,
            value: 1.0,
            min: 0.0,
            max: 2.0,
            onChanged: (value) => onAdjustmentChanged('Contrast', value),
          ),
          SliderWidget(
            label: AppStrings.saturation,
            value: 1.0,
            min: 0.0,
            max: 2.0,
            onChanged: (value) => onAdjustmentChanged('Saturation', value),
          ),
          SliderWidget(
            label: AppStrings.hue,
            value: 0.0,
            min: -180.0,
            max: 180.0,
            onChanged: (value) => onAdjustmentChanged('Hue', value),
          ),
          SliderWidget(
            label: AppStrings.temperature,
            value: 0.0,
            min: -1.0,
            max: 1.0,
            onChanged: (value) => onAdjustmentChanged('Temperature', value),
          ),
          SliderWidget(
            label: AppStrings.tint,
            value: 0.0,
            min: -1.0,
            max: 1.0,
            onChanged: (value) => onAdjustmentChanged('Tint', value),
          ),
        ].map((e) => Padding(padding: EdgeInsets.symmetric(vertical: padding / 2), child: e)).toList(),
      ),
    );
  }
}