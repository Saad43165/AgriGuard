import 'dart:io';
import 'package:flutter/material.dart';

class AdvancedTopImageSection extends StatelessWidget {
  final String? imagePath;
  const AdvancedTopImageSection({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && File(imagePath!).existsSync()) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: Colors.black12,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
