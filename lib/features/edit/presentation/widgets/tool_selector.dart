import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../utils/constants.dart';

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}

class ToolSelector extends StatelessWidget {
  final EditingTool currentTool;
  final Function(EditingTool) onToolSelected;
  final Animation<double> animation;

  const ToolSelector({
    super.key,
    required this.currentTool,
    required this.onToolSelected,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    return SizedBox(
      height: padding * 3,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: EditingTool.values.map((tool) => Padding(
          padding: EdgeInsets.symmetric(horizontal: padding / 2),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Transform.scale(
              scale: currentTool == tool ? 1.0 + 0.2 * animation.value : 1.0,
              child: GestureDetector(
                onTap: () => onToolSelected(tool),
                child: Chip(
                  label: Text(tool.toString().split('.').last.capitalize()),
                  backgroundColor: currentTool == tool
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}