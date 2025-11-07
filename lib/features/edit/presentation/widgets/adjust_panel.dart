import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';
import 'slider_widget.dart';

class AdjustPanel extends StatelessWidget {
  final Function(String, double) onAdjustmentChanged;
  final Map<String, double> currentValues;
  final bool showResetButtons;

  const AdjustPanel({
    super.key,
    required this.onAdjustmentChanged,
    this.currentValues = const {},
    this.showResetButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: _buildSliders(context, padding),
        ),
      ),
    );
  }

  List<Widget> _buildSliders(BuildContext context, double padding) {
    final sliders = [
      _buildSlider(
        label: AppStrings.brightness,
        defaultValue: 0.0,
        min: -1.0,
        max: 1.0,
        key: 'Brightness',
        padding: padding,
      ),
      _buildSlider(
        label: AppStrings.contrast,
        defaultValue: 1.0,
        min: 0.0,
        max: 2.0,
        key: 'Contrast',
        padding: padding,
      ),
      _buildSlider(
        label: AppStrings.saturation,
        defaultValue: 1.0,
        min: 0.0,
        max: 2.0,
        key: 'Saturation',
        padding: padding,
      ),
      _buildSlider(
        label: AppStrings.hue,
        defaultValue: 0.0,
        min: -180.0,
        max: 180.0,
        key: 'Hue',
        padding: padding,
      ),
      _buildSlider(
        label: AppStrings.temperature,
        defaultValue: 0.0,
        min: -1.0,
        max: 1.0,
        key: 'Temperature',
        padding: padding,
      ),
      _buildSlider(
        label: AppStrings.tint,
        defaultValue: 0.0,
        min: -1.0,
        max: 1.0,
        key: 'Tint',
        padding: padding,
      ),
    ];

    return sliders;
  }

  Widget _buildSlider({
    required String label,
    required double defaultValue,
    required double min,
    required double max,
    required String key,
    required double padding,
  }) {
    final currentValue = currentValues[key] ?? defaultValue;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding / 2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (showResetButtons && currentValue != defaultValue) ...[
                Text(
                  _formatValue(currentValue),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onAdjustmentChanged(key, defaultValue),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ] else if (showResetButtons) ...[
                Text(
                  _formatValue(currentValue),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SliderWidget(
            label: label,
            value: currentValue,
            min: min,
            max: max,
            onChanged: (value) => onAdjustmentChanged(key, value),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    return value.toStringAsFixed(value.abs() >= 10 ? 0 : 1);
  }
}

// Optional: Create a more advanced version with sections
class AdvancedAdjustPanel extends StatelessWidget {
  final Function(String, double) onAdjustmentChanged;
  final Map<String, double> currentValues;
  final bool showResetButtons;
  final bool showSections;

  const AdvancedAdjustPanel({
    super.key,
    required this.onAdjustmentChanged,
    this.currentValues = const {},
    this.showResetButtons = true,
    this.showSections = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSections) ..._buildSections(context),
            if (!showSections) ..._buildAllSliders(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    return [
      _buildSection(
        title: 'Basic Adjustments',
        sliders: [
          _buildSliderData('Brightness', AppStrings.brightness, 0.0, -1.0, 1.0),
          _buildSliderData('Contrast', AppStrings.contrast, 1.0, 0.0, 2.0),
          _buildSliderData('Saturation', AppStrings.saturation, 1.0, 0.0, 2.0),
        ],
        context: context,
      ),
      _buildSection(
        title: 'Color Adjustments',
        sliders: [
          _buildSliderData('Hue', AppStrings.hue, 0.0, -180.0, 180.0),
          _buildSliderData('Temperature', AppStrings.temperature, 0.0, -1.0, 1.0),
          _buildSliderData('Tint', AppStrings.tint, 0.0, -1.0, 1.0),
        ],
        context: context,
      ),
    ];
  }

  List<Widget> _buildAllSliders(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return _buildSliderDataList().map((data) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: padding / 2),
        child: _buildSliderWidget(data, context),
      );
    }).toList();
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> sliders,
    required BuildContext context,
  }) {
    final padding = AppMeasurements.getResponsivePadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: padding, horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        ...sliders.map((data) => Padding(
          padding: EdgeInsets.symmetric(vertical: padding / 2),
          child: _buildSliderWidget(data, context),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSliderWidget(Map<String, dynamic> data, BuildContext context) {
    final key = data['key'] as String;
    final currentValue = currentValues[key] ?? data['defaultValue'] as double;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data['label'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (showResetButtons && currentValue != data['defaultValue']) ...[
              Text(
                _formatValue(currentValue),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _buildResetButton(key, data['defaultValue'] as double),
            ] else if (showResetButtons) ...[
              Text(
                _formatValue(currentValue),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SliderWidget(
          label: data['label'] as String,
          value: currentValue,
          min: data['min'] as double,
          max: data['max'] as double,
          onChanged: (value) => onAdjustmentChanged(key, value),
        ),
      ],
    );
  }

  Widget _buildResetButton(String key, double defaultValue) {
    return GestureDetector(
      onTap: () => onAdjustmentChanged(key, defaultValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Reset',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildSliderData(String key, String label, double defaultValue, double min, double max) {
    return {
      'key': key,
      'label': label,
      'defaultValue': defaultValue,
      'min': min,
      'max': max,
    };
  }

  List<Map<String, dynamic>> _buildSliderDataList() {
    return [
      _buildSliderData('Brightness', AppStrings.brightness, 0.0, -1.0, 1.0),
      _buildSliderData('Contrast', AppStrings.contrast, 1.0, 0.0, 2.0),
      _buildSliderData('Saturation', AppStrings.saturation, 1.0, 0.0, 2.0),
      _buildSliderData('Hue', AppStrings.hue, 0.0, -180.0, 180.0),
      _buildSliderData('Temperature', AppStrings.temperature, 0.0, -1.0, 1.0),
      _buildSliderData('Tint', AppStrings.tint, 0.0, -1.0, 1.0),
    ];
  }

  String _formatValue(double value) {
    return value.toStringAsFixed(value.abs() >= 10 ? 0 : 1);
  }
}