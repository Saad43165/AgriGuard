import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';
import 'slider_widget.dart';

class HighlightPanel extends StatefulWidget {
  final Function(Color, double) onHighlightChanged;

  const HighlightPanel({super.key, required this.onHighlightChanged});

  @override
  State<HighlightPanel> createState() => _HighlightPanelState();
}

class _HighlightPanelState extends State<HighlightPanel> {
  Color _highlightColor = Colors.yellow;
  double _highlightSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return Column(
      children: [
        SliderWidget(
          label: AppStrings.highlightSize,
          value: _highlightSize,
          min: 5.0,
          max: 50.0,
          onChanged: (value) {
            setState(() => _highlightSize = value);
            widget.onHighlightChanged(_highlightColor, _highlightSize);
          },
        ),
        TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppStrings.selectColor),
              content: ColorPicker(
                pickerColor: _highlightColor,
                onColorChanged: (color) {
                  setState(() => _highlightColor = color);
                  widget.onHighlightChanged(_highlightColor, _highlightSize);
                },
                enableAlpha: false,
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