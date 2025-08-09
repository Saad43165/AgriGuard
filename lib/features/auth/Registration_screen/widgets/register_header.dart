import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterHeader extends StatelessWidget {
  final XFile? imageFile;
  final VoidCallback onImagePressed;
  final bool isLoading;

  const RegisterHeader({
    super.key,
    required this.imageFile,
    required this.onImagePressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const imageSize = 100.0;

    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : onImagePressed,
          child: CircleAvatar(
            radius: imageSize / 2,
            backgroundColor: theme.colorScheme.surface.withOpacity(0.2),
            backgroundImage: imageFile != null
                ? FileImage(File(imageFile!.path)) as ImageProvider
                : null,
            child: imageFile == null
                ? Icon(
              Icons.person_rounded,
              size: imageSize * 0.5,
              color: theme.colorScheme.primary,
            )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'AgriGuard',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create an account to protect your crops',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}