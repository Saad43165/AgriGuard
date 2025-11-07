import 'package:agriguard_fyp/features/edit/presentation/widgets/sticker_panel.dart';
import 'package:agriguard_fyp/features/edit/presentation/widgets/text_panel.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'adjust_panel.dart';
import 'draw_panel.dart';
import 'crop_panel.dart';
import 'effects_panel.dart';
import 'highlitghts_panel.dart';

class ToolPanelContainer extends StatelessWidget {
  final EditingTool currentTool;
  final bool isPanelExpanded;
  final Animation<double> panelAnimation;
  final VoidCallback onToggleExpansion;
  final Function(String, double) onAdjustmentChanged;
  final Function(Color, double) onHighlightChanged;
  final VoidCallback onStartCrop;
  final VoidCallback? onApplyCrop;
  final VoidCallback onResetCrop;
  final Function(Color, double, double) onDrawChanged;
  final Function(String, Color) onTextAdded;
  final Function(String, dynamic) onEffectChanged;
  final Function(String, Color) onStickerAdded;

  const ToolPanelContainer({
    super.key,
    required this.currentTool,
    required this.isPanelExpanded,
    required this.panelAnimation,
    required this.onToggleExpansion,
    required this.onAdjustmentChanged,
    required this.onHighlightChanged,
    required this.onStartCrop,
    required this.onApplyCrop,
    required this.onResetCrop,
    required this.onDrawChanged,
    required this.onTextAdded,
    required this.onEffectChanged,
    required this.onStickerAdded,
  });

  String _getToolDisplayName(EditingTool tool) {
    switch (tool) {
      case EditingTool.adjust:
        return 'Adjustments';
      case EditingTool.highlight:
        return 'Highlights';
      case EditingTool.crop:
        return 'Crop & Resize';
      case EditingTool.draw:
        return 'Draw';
      case EditingTool.text:
        return 'Text';
      case EditingTool.effects:
        return 'Effects';
      case EditingTool.stickers:
        return 'Stickers';
      case EditingTool.curves:
        return 'Curves';
    }
  }

  Widget _buildToolPanel(BuildContext context) {
    try {
      switch (currentTool) {
        case EditingTool.adjust:
          return AdjustPanel(onAdjustmentChanged: onAdjustmentChanged);
        case EditingTool.highlight:
          return HighlightPanel(onHighlightChanged: onHighlightChanged);
        case EditingTool.crop:
          return CropPanel(
            isCropping: false, // Controlled by parent
            onStartCrop: onStartCrop,
            onApplyCrop: onApplyCrop,
            onResetCrop: onResetCrop,
          );
        case EditingTool.draw:
          return DrawPanel(onDrawChanged: onDrawChanged);
        case EditingTool.text:
          return TextPanel(onTextAdded: onTextAdded);
        case EditingTool.effects:
          return EffectsPanel(onEffectChanged: onEffectChanged);
        case EditingTool.stickers:
          return StickersPanel(onStickerAdded: onStickerAdded);
        case EditingTool.curves:
          return Center(
            child: Text(
              'Curves panel coming soon',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          );
        default:
          return Center(
            child: Text(
              'Tool not implemented',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
      }
    } catch (e) {
      return Center(
        child: Text(
          'Error loading panel: $e',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with tool name and expand/collapse button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _getToolDisplayName(currentTool),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isPanelExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: onToggleExpansion,
                ),
              ],
            ),
          ),

          // Tool panel content with animation
          Expanded(
            child: AnimatedBuilder(
              animation: panelAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: panelAnimation,
                  child: _buildToolPanel(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}