import 'package:flutter/material.dart';

class TextAnnotation {
  final Offset position;
  final String text;
  final TextStyle style;
  final double rotation;

  TextAnnotation({
    required this.position,
    required this.text,
    required this.style,
    required this.rotation,
  });
}