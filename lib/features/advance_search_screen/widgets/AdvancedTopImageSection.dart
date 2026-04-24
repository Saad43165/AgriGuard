import 'dart:io';
import 'package:flutter/material.dart';

class AdvancedTopImageSection extends StatelessWidget {
  final String? imagePath;
  const AdvancedTopImageSection({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 42,
      child: (imagePath != null && File(imagePath!).existsSync())
          ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity)
          : Container(color: Colors.black12),
    );
  }
}