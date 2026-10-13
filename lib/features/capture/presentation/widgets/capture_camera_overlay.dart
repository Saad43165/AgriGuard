import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'brackets_painter.dart';

class CaptureCameraOverlay extends StatelessWidget {
  final bool cameraReady;
  final CameraController? controller;
  final double currentZoom;
  final bool showFocusCircle;
  final Offset? focusPoint;
  final Animation<double> focusAnimation;
  final String? plantHint;
  final FlashMode flashMode;
  final bool hasMultipleCameras;
  final Future<void> Function(TapDownDetails, BoxConstraints) onTapToFocus;
  final VoidCallback onScaleStart;
  final void Function(ScaleUpdateDetails) onScaleUpdate;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final VoidCallback onFlipCamera;
  final String hintText;

  const CaptureCameraOverlay({
    super.key,
    required this.cameraReady,
    required this.controller,
    required this.currentZoom,
    required this.showFocusCircle,
    required this.focusPoint,
    required this.focusAnimation,
    required this.plantHint,
    required this.flashMode,
    required this.hasMultipleCameras,
    required this.onTapToFocus,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onClose,
    required this.onToggleFlash,
    required this.onFlipCamera,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraReady && controller != null)
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = 1 /
                  (controller!.value.aspectRatio *
                      MediaQuery.of(context).size.aspectRatio);
              return Transform.scale(
                scale: scale < 1 ? 1 / scale : scale,
                child: Center(
                  child: GestureDetector(
                    onTapDown: (d) => onTapToFocus(d, constraints),
                    onScaleStart: (_) => onScaleStart(),
                    onScaleUpdate: onScaleUpdate,
                    child: CameraPreview(controller!),
                  ),
                ),
              );
            },
          )
        else
          const Center(child: CircularProgressIndicator()),

        Center(
          child: SizedBox(width: 240, height: 240, child: CustomPaint(painter: BracketsPainter())),
        ),

        if (showFocusCircle && focusPoint != null)
          PositionedDirectional(
            start: focusPoint!.dx - 30,
            top: focusPoint!.dy - 30,
            child: AnimatedBuilder(
              animation: focusAnimation,
              builder: (_, __) => Transform.scale(
                scale: focusAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.yellow, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

        PositionedDirectional(
          bottom: 230,
          start: 0,
          end: 0,
          child: Text(
            hintText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),

        if (currentZoom > 1.05)
          PositionedDirectional(
            bottom: 210,
            start: 0,
            end: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${currentZoom.toStringAsFixed(1)}×',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),

        PositionedDirectional(
          top: MediaQuery.of(context).padding.top + 8,
          start: 16,
          end: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _btn(Icons.close_rounded, onClose),
              _btn(
                flashMode == FlashMode.torch
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                onToggleFlash,
              ),
              hasMultipleCameras
                  ? _btn(Icons.flip_camera_ios_rounded, onFlipCamera)
                  : const SizedBox(width: 40),
            ],
          ),
        ),

        if (plantHint != null)
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 60,
            start: 0,
            end: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Scanning as $plantHint',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}