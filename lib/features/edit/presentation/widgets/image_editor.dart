import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../utils/constants.dart';
import 'crop_overlay_painter.dart';

class ImageEditor extends StatelessWidget {
  final Uint8List? encodedImage;
  final EditingTool currentTool;
  final bool isCropping;
  final Rect? cropRect;
  final Matrix4 matrix;
  final double currentScale;
  final GlobalKey imageKey;
  final bool isProcessing;
  final Function(Matrix4, dynamic, dynamic, dynamic) onMatrixUpdate;
  final Function(TapDownDetails) onTapDown;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const ImageEditor({
    super.key,
    required this.encodedImage,
    required this.currentTool,
    required this.isCropping,
    required this.cropRect,
    required this.matrix,
    required this.currentScale,
    required this.imageKey,
    required this.isProcessing,
    required this.onMatrixUpdate,
    required this.onTapDown,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (encodedImage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            MatrixGestureDetector(
              onMatrixUpdate: onMatrixUpdate,
              child: GestureDetector(
                onTapDown: onTapDown,
                onPanUpdate: onPanUpdate,
                onPanEnd: onPanEnd,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: Transform(
                      transform: matrix,
                      child: Image.memory(
                        encodedImage!,
                        key: imageKey,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (currentTool == EditingTool.crop && cropRect != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(cropRect!, Theme.of(context).colorScheme.primary),
                ),
              ),
            if (isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}