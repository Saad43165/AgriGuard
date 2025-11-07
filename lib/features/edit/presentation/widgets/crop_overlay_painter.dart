import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Color borderColor;

  CropOverlayPainter(this.cropRect, this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(cropRect),
      ),
      paint,
    );

    canvas.drawRect(cropRect, borderPaint);

    final handleSize = 8.0;
    final handlePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final corners = [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, handleSize, handlePaint);
    }
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.borderColor != borderColor;
  }
}