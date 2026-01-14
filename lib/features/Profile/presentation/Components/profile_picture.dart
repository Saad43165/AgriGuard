import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final File? profileImageFile;
  final String? profileImageBase64;
  final bool isEditing;
  final Animation<double> scaleAnimation;

  const ProfilePicture({
    super.key,
    this.profileImageFile,
    this.profileImageBase64,
    required this.isEditing,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Background image
              _buildImageContent(context),

              // Gradient overlay when editing
              if (isEditing)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),

              // Camera icon when editing
              if (isEditing)
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    String? imageUrl;

    if (profileImageFile != null) {
      imageUrl = profileImageFile!.path;
    } else if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      imageUrl = 'base64:$profileImageBase64';
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('base64:')) {
        final base64String = imageUrl.substring(7);
        try {
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(context);
            },
          );
        } catch (e) {
          return _buildDefaultAvatar(context);
        }
      } else {
        try {
          final file = File(imageUrl);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar(context);
              },
            );
          } else {
            return _buildDefaultAvatar(context);
          }
        } catch (e) {
          return _buildDefaultAvatar(context);
        }
      }
    } else {
      return _buildDefaultAvatar(context);
    }
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 60,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }
}