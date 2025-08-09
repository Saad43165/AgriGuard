import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';
import 'slider_widget.dart';

class EffectsPanel extends StatelessWidget {
  final Function(String, dynamic) onEffectChanged;

  const EffectsPanel({super.key, required this.onEffectChanged});

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return Column(
      children: [
        SliderWidget(
          label: AppStrings.blur,
          value: 0.0,
          min: 0.0,
          max: 10.0,
          onChanged: (value) => onEffectChanged('Blur', value),
        ),
        SliderWidget(
          label: AppStrings.posterize,
          value: 0.0,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => onEffectChanged('Posterize', value),
        ),
        SwitchListTile(
          title: Text(AppStrings.grayscale),
          value: false,
          onChanged: (value) => onEffectChanged('Grayscale', value),
        ),
        SwitchListTile(
          title: Text(AppStrings.sepia),
          value: false,
          onChanged: (value) => onEffectChanged('Sepia', value),
        ),
      ].map((e) => Padding(padding: EdgeInsets.symmetric(vertical: padding / 2), child: e)).toList(),
    );
  }
}