import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final double opacity;

  DrawingPoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
  });
}