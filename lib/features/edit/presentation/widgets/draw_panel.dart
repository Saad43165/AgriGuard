import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';
import 'slider_widget.dart';

class DrawPanel extends StatefulWidget {
  final Function(Color, double, double) onDrawChanged;

  const DrawPanel({super.key, required this.onDrawChanged});

  @override
  State<DrawPanel> createState() => _DrawPanelState();
}

class _DrawPanelState extends State<DrawPanel> {
  Color _selectedColor = Colors.red;
  double _brushSize = 5.0;
  double _brushOpacity = 1.0;

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return Column(
      children: [
        SliderWidget(
          label: AppStrings.brushSize,
          value: _brushSize,
          min: 1.0,
          max: 20.0,
          onChanged: (value) {
            setState(() => _brushSize = value);
            widget.onDrawChanged(_selectedColor, _brushSize, _brushOpacity);
          },
        ),
        SliderWidget(
          label: AppStrings.brushOpacity,
          value: _brushOpacity,
          min: 0.1,
          max: 1.0,
          onChanged: (value) {
            setState(() => _brushOpacity = value);
            widget.onDrawChanged(_selectedColor, _brushSize, _brushOpacity);
          },
        ),
        TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppStrings.selectColor),
              content: ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) {
                  setState(() => _selectedColor = color);
                  widget.onDrawChanged(_selectedColor, _brushSize, _brushOpacity);
                },
                enableAlpha: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.done),
                ),
              ],
            ),
          ),
          child: Text(AppStrings.chooseColor),
        ),
      ].map((e) => Padding(padding: EdgeInsets.symmetric(vertical: padding / 2), child: e)).toList(),
    );
  }
}