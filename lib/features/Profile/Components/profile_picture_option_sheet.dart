import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void showProfilePictureOptionsSheet({
  required BuildContext context,
  required File? profileImageFile,
  required String? profileImageBase64,
  required VoidCallback onChangeImage,
}) {
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fullscreen_rounded,
                color: Color(0xFF2196F3),
              ),
            ),
            title: const Text('View Profile Picture'),
            onTap: () {
              Navigator.pop(context);
              _showFullscreenImage(
                context,
                profileImageFile,
                profileImageBase64,
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF4CAF50),
              ),
            ),
            title: const Text('Change Profile Picture'),
            onTap: () {
              Navigator.pop(context);
              onChangeImage();
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showFullscreenImage(
    BuildContext context,
    File? profileImageFile,
    String? profileImageBase64,
    ) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => _FullscreenImageView(
        profileImageFile: profileImageFile,
        profileImageBase64: profileImageBase64,
      ),
    ),
  );
}

class _FullscreenImageView extends StatelessWidget {
  final File? profileImageFile;
  final String? profileImageBase64;

  const _FullscreenImageView({
    this.profileImageFile,
    this.profileImageBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImage(),
            ),
          ),
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
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Text(
                    'Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
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

  Widget _buildImage() {
    if (profileImageFile != null) {
      return Image.file(profileImageFile!, fit: BoxFit.contain);
    }

    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageBase64!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
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