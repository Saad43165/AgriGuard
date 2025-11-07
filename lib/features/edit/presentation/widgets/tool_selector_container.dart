import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'tool_selector.dart';

class ToolSelectorContainer extends StatelessWidget {
  final EditingTool currentTool;
  final Function(EditingTool) onToolSelected;
  final Animation<double> animation;
  final bool isHorizontal;

  const ToolSelectorContainer({
    super.key,
    required this.currentTool,
    required this.onToolSelected,
    required this.animation,
    required this.isHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isHorizontal ? 16 : 8,
        vertical: isHorizontal ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: isHorizontal
              ? BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          )
              : BorderSide.none,
        ),
      ),
      child: ToolSelector(
        currentTool: currentTool,
        onToolSelected: onToolSelected,
        animation: animation,
        isHorizontal: isHorizontal,
      ),
    );
  }
}