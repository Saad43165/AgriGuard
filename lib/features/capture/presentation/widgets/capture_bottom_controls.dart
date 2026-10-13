import 'dart:ui';
import 'package:flutter/material.dart';

import 'animated_shutter_button.dart';

class CaptureBottomControls extends StatelessWidget {
  final int scanModeIndex;
  final ValueChanged<int> onChangeMode;
  final VoidCallback onPickGallery;
  final VoidCallback onTakePicture;
  final bool showZoomReset;
  final VoidCallback? onZoomReset;

  const CaptureBottomControls({
    super.key,
    required this.scanModeIndex,
    required this.onChangeMode,
    required this.onPickGallery,
    required this.onTakePicture,
    required this.showZoomReset,
    required this.onZoomReset,
  });

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
            color: Colors.black.withValues(alpha: 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeSelector(selectedIndex: scanModeIndex, onChanged: onChangeMode),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _smallBtn(Icons.photo_library_outlined, onPickGallery),
                    AnimatedShutterButton(onTap: onTakePicture),
                    AnimatedOpacity(
                      opacity: showZoomReset ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _smallBtn(Icons.zoom_out_rounded, onZoomReset),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ModeSelector({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('Fast Scan', Icons.bolt_rounded),
      ('Deep AI', Icons.auto_awesome_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(modes.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF16A34A) : Colors.transparent,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Icon(modes[i].$2, color: selected ? Colors.white : Colors.white60, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    modes[i].$1,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}