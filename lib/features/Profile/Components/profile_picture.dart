import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final File? profileImageFile;
  final String? profileImageBase64;
  final bool isEditing;
  final Animation<double> scaleAnimation;
  final VoidCallback? onImageChanged;

  const ProfilePicture({
    super.key,
    this.profileImageFile,
    this.profileImageBase64,
    required this.isEditing,
    required this.scaleAnimation,
    this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: GestureDetector(
        onTap: () => _showProfilePictureOptions(context),
        child: Hero(
          tag: 'profile_picture',
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipOval(
                child: _buildImageContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfilePictureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // View Profile Picture
            _buildOption(
              context,
              icon: Icons.fullscreen_rounded,
              iconColor: const Color(0xFF2196F3),
              iconBgColor: const Color(0xFFE3F2FD),
              title: 'View Profile Picture',
              subtitle: 'See in full screen',
              onTap: () {
                Navigator.pop(context);
                _showFullscreenImage(context);
              },
            ),
            const SizedBox(height: 12),

            // Change Profile Picture
            _buildOption(
              context,
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF4CAF50),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Change Profile Picture',
              subtitle: 'Upload a new photo',
              onTap: () {
                Navigator.pop(context);
                if (onImageChanged != null) {
                  onImageChanged!();
                }
              },
            ),
            const SizedBox(height: 12),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required Color iconBgColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenProfilePicture(
          profileImageFile: profileImageFile,
          profileImageBase64: profileImageBase64,
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (profileImageFile != null) {
      return Image.file(
        profileImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildDefaultAvatar(context),
      );
    }

    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(context),
        );
      } catch (e) {
        return _buildDefaultAvatar(context);
      }
    }

    return _buildDefaultAvatar(context);
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
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withOpacity(0.6),
        ),
      ),
    );
  }
}

// Fullscreen Profile Picture Viewer
class FullscreenProfilePicture extends StatelessWidget {
  final File? profileImageFile;
  final String? profileImageBase64;

  const FullscreenProfilePicture({
    super.key,
    this.profileImageFile,
    this.profileImageBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image
          Center(
            child: Hero(
              tag: 'profile_picture',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildImage(context),
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Text(
                    'Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (profileImageFile != null) {
      return Image.file(
        profileImageFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );
    }

    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageBase64!);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        );
      } catch (e) {
        return _buildPlaceholder(context);
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade800,
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 100,
        color: Colors.white54,
      ),
    );
  }
}