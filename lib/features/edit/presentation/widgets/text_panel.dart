import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/constants/app_constants.dart';

class TextPanel extends StatefulWidget {
  final Function(String, Color) onTextAdded;

  const TextPanel({super.key, required this.onTextAdded});

  @override
  State<TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<TextPanel> {
  final _controller = TextEditingController();
  Color _selectedColor = Colors.red;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: AppStrings.enterText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius)),
              contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onTextAdded(value, _selectedColor);
                _controller.clear();
              }
            },
          ),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppStrings.selectColor),
                content: ColorPicker(
                  pickerColor: _selectedColor,
                  onColorChanged: (color) => setState(() => _selectedColor = color),
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
      ),
    );
  }
}